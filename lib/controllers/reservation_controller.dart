import 'dart:convert';

import 'package:mysql1/mysql1.dart';
import 'package:shelf/shelf.dart';

import '../config/database.dart';
import '../utils/request_user.dart';
import '../utils/response.dart';
import '../utils/validation.dart';

class ReservationController {
  final _db = Database();

  Map<String, dynamic>? _user(Request request) =>
      getUserFromAuthHeader(request.headers['Authorization']);

  String _generateCode() {
    final now = DateTime.now();
    final datePart =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final millis = now.millisecondsSinceEpoch % 1000;
    return 'RES-$datePart-${millis.toString().padLeft(3, '0')}';
  }

  Future<Response> createReservation(Request request) async {
    final user = _user(request);
    if (user == null) return unauthorized();
    final data = jsonDecode(await request.readAsString()) as Map;
    final err = requireFields(
        data, ['reservation_date', 'number_of_guests'],
        messages: {
          'reservation_date': 'reservation_date is required',
          'number_of_guests': 'number_of_guests is required'
        });
    if (err != null) return err;
    final reservationDate = data['reservation_date'];
    final guests = data['number_of_guests'];

    final conn = await _db.getConnection();
    final code = _generateCode();
    final result = await conn.query(
        '''INSERT INTO reservations (customer_id, reservation_number, reservation_date, number_of_guests, status, special_requests, subtotal, service_charge, discount, total, payment_status, created_at, updated_at)
        VALUES (?, ?, ?, ?, 'pending', ?, 0, 0, 0, 0, 'pending', NOW(), NOW())''',
        [
          user['id'],
          code,
          reservationDate,
          guests,
          data['special_requests']
        ]);
    return created({
      'message': 'Reservation created',
      'id': result.insertId,
      'reservation_number': code
    });
  }

  Future<Response> addItem(Request request, String id) async {
    final user = _user(request);
    if (user == null) return unauthorized();
    final data = jsonDecode(await request.readAsString()) as Map;
    final err = requireFields(data, ['menu_item_id']);
    if (err != null) return err;
    final menuItemId = data['menu_item_id'];
    final quantity = data['quantity'] ?? 1;

    final conn = await _db.getConnection();
    // verify reservation owner
    final resRows = await conn.query(
        'SELECT customer_id, status FROM reservations WHERE id=?', [int.parse(id)]);
    if (resRows.isEmpty) return notFound('Reservation not found');
    final resRow = resRows.first;
    if (resRow['customer_id'] != user['id']) return forbidden();
    if (resRow['status'] == 'completed') {
      return badRequest('Cannot add items to completed reservation');
    }

    // check menu item availability
    final itemRows = await conn.query(
        'SELECT price, is_available FROM menu_items WHERE id=?', [menuItemId]);
    if (itemRows.isEmpty) return badRequest('Menu item not found');
    final item = itemRows.first;
    if ((item['is_available'] as int) != 1) {
      return badRequest('Menu item not available');
    }

    final price = (item['price'] as num).toDouble();
    await conn.query(
        '''INSERT INTO reservation_items (reservation_id, menu_item_id, quantity, price, created_at)
        VALUES (?, ?, ?, ?, NOW())''',
        [int.parse(id), menuItemId, quantity, price]);

    // recalc totals
    final totals = await conn.query(
        'SELECT SUM(quantity*price) as subtotal FROM reservation_items WHERE reservation_id=?',
        [int.parse(id)]);
    final subtotal = (totals.first['subtotal'] as num?)?.toDouble() ?? 0;
    final serviceCharge = subtotal * 0.1;
    final total = subtotal + serviceCharge;
    await conn.query(
        'UPDATE reservations SET subtotal=?, service_charge=?, total=?, updated_at=NOW() WHERE id=?',
        [subtotal, serviceCharge, total, int.parse(id)]);

    return ok({
      'message': 'Item added',
      'reservation_id': int.parse(id),
      'subtotal': subtotal,
      'service_charge': serviceCharge,
      'total': total
    });
  }

  Future<Response> confirmReservation(Request request, String id) async {
    final user = _user(request);
    if (user == null || user['is_admin'] != true) return forbidden();
    final data = jsonDecode(await request.readAsString()) as Map;
    final err = requireFields(data, ['table_number']);
    if (err != null) return err;
    final tableNumber = data['table_number'];

    final conn = await _db.getConnection();
    final tableRows = await conn.query(
        'SELECT id, capacity, is_available FROM tables WHERE table_number=?',
        [tableNumber]);
    if (tableRows.isEmpty) return badRequest('Table not found');
    final table = tableRows.first;
    if ((table['is_available'] as int) != 1) {
      return badRequest('Table not available');
    }

    final resRows = await conn.query(
        'SELECT number_of_guests FROM reservations WHERE id=?', [int.parse(id)]);
    if (resRows.isEmpty) return notFound('Reservation not found');
    final guests = resRows.first['number_of_guests'] as int;
    if (guests > (table['capacity'] as int)) {
      return badRequest('Table capacity not sufficient');
    }

    await conn.query(
        '''UPDATE reservations SET table_number=?, status='confirmed', updated_at=NOW() WHERE id=?''',
        [tableNumber, int.parse(id)]);
    await conn.query(
        'UPDATE tables SET is_available=0, updated_at=NOW() WHERE id=?',
        [table['id']]);
    return ok({'message': 'Reservation confirmed', 'reservation_id': int.parse(id)});
  }

  Future<Response> seatReservation(Request request, String id) async {
    final user = _user(request);
    if (user == null || user['is_admin'] != true) return forbidden();
    final conn = await _db.getConnection();
    final resRows = await conn.query(
        'SELECT status FROM reservations WHERE id=?', [int.parse(id)]);
    if (resRows.isEmpty) return notFound('Reservation not found');
    if (resRows.first['status'] != 'confirmed') {
      return badRequest('Reservation must be confirmed before seated');
    }
    await conn.query(
        'UPDATE reservations SET status=\'seated\', updated_at=NOW() WHERE id=?',
        [int.parse(id)]);
    return ok({'message': 'Reservation seated', 'reservation_id': int.parse(id)});
  }

  Future<Response> payReservation(Request request, String id) async {
    final user = _user(request);
    if (user == null) return unauthorized();
    final data = jsonDecode(await request.readAsString()) as Map;
    final paymentMethod = data['payment_method'] ?? 'cash';
    final usePoints = data['use_loyalty_points'] == true;
    final pointsToUse = (data['loyalty_points_to_use'] as int?) ?? 0;

    final conn = await _db.getConnection();
    final Response? result = await conn.transaction<Response?>((txn) async {
      final resRows = await txn
          .query('SELECT * FROM reservations WHERE id=? FOR UPDATE', [int.parse(id)]);
      if (resRows.isEmpty) return notFound('Reservation not found');
      final res = resRows.first;
      if (res['customer_id'] != user['id'] && user['is_admin'] != true) {
        return forbidden();
      }
      if (res['status'] != 'seated') {
        return badRequest('Reservation must be seated before payment');
      }

      double subtotal = (res['subtotal'] as num).toDouble();
      double serviceCharge = (res['service_charge'] as num).toDouble();
      double total = subtotal + serviceCharge;
      double discount = 0;

      if (usePoints && pointsToUse > 0) {
        // 1 point = 1000, max 50% total
        final maxDiscount = total * 0.5;
        discount = (pointsToUse * 1000).toDouble();
        if (discount > maxDiscount) discount = maxDiscount;
        total = total - discount;
        await txn.query(
            'UPDATE customers SET loyalty_points = GREATEST(loyalty_points-?, 0) WHERE id=?',
            [pointsToUse, res['customer_id']]);
      }

      // add loyalty 1% total
      final addPoints = (total * 0.01).floor();
      await txn.query(
          'UPDATE customers SET loyalty_points = loyalty_points + ? WHERE id=?',
          [addPoints, res['customer_id']]);

      await txn.query(
          '''UPDATE reservations SET discount=?, total=?, payment_method=?, payment_status='paid', status='completed', updated_at=NOW() WHERE id=?''',
          [discount, total, paymentMethod, int.parse(id)]);

      if (res['table_number'] != null) {
        await txn.query(
            'UPDATE tables SET is_available=1, updated_at=NOW() WHERE table_number=?',
            [res['table_number']]);
      }

      return ok({
        'message': 'Payment successful',
        'reservation_id': int.parse(id),
        'total': total,
        'discount': discount,
        'loyalty_points_added': addPoints
      });
    });
    if (result == null) {
      return serverError('Payment failed');
    }
    return result;
  }

  Future<Response> cancelReservation(Request request, String id) async {
    final user = _user(request);
    if (user == null) return unauthorized();
    final conn = await _db.getConnection();
    final rows =
        await conn.query('SELECT * FROM reservations WHERE id=?', [int.parse(id)]);
    if (rows.isEmpty) return notFound('Reservation not found');
    final res = rows.first;
    final isOwner = res['customer_id'] == user['id'];
    final isAdmin = user['is_admin'] == true;
    if (!isOwner && !isAdmin) return forbidden();
    if (!isAdmin &&
        res['status'] != 'pending' &&
        res['status'] != 'confirmed') {
      return badRequest('Customer can cancel only pending/confirmed reservations');
    }
    await conn.query(
        'UPDATE reservations SET status=\'cancelled\', updated_at=NOW() WHERE id=?',
        [int.parse(id)]);
    if (res['table_number'] != null) {
      await conn.query(
          'UPDATE tables SET is_available=1, updated_at=NOW() WHERE table_number=?',
          [res['table_number']]);
    }
    return ok({'message': 'Reservation cancelled', 'reservation_id': int.parse(id)});
  }

  Future<Response> getReservation(Request request, String id) async {
    final user = _user(request);
    if (user == null) return unauthorized();
    final conn = await _db.getConnection();
    final resRows =
        await conn.query('SELECT * FROM reservations WHERE id=?', [int.parse(id)]);
    if (resRows.isEmpty) return notFound('Reservation not found');
    final res = resRows.first;
    if (res['customer_id'] != user['id'] && user['is_admin'] != true) {
      return forbidden();
    }
    final itemsRows = await conn.query(
        '''SELECT ri.*, m.name, m.category FROM reservation_items ri 
        JOIN menu_items m ON m.id = ri.menu_item_id WHERE ri.reservation_id=?''',
        [int.parse(id)]);
    final items = itemsRows
        .map((i) => {
              'id': i['id'],
              'menu_item_id': i['menu_item_id'],
              'name': i['name'],
              'category': i['category'],
              'quantity': i['quantity'],
              'price': i['price'],
              'created_at': i['created_at'].toString(),
            })
        .toList();
    return ok({
      'reservation': {
        'id': res['id'],
        'customer_id': res['customer_id'],
        'reservation_number': res['reservation_number'],
        'reservation_date': res['reservation_date'].toString(),
        'number_of_guests': res['number_of_guests'],
        'table_number': res['table_number'],
        'status': res['status'],
        'special_requests': res['special_requests'],
        'subtotal': res['subtotal'],
        'service_charge': res['service_charge'],
        'discount': res['discount'],
        'total': res['total'],
        'payment_method': res['payment_method'],
        'payment_status': res['payment_status'],
        'created_at': res['created_at'].toString(),
        'updated_at': res['updated_at'].toString(),
      },
      'items': items
    });
  }

  Future<Response> listCustomerReservations(
      Request request, String customerId) async {
    final user = _user(request);
    if (user == null) return unauthorized();
    final isAdmin = user['is_admin'] == true;
    if (!isAdmin && user['id'] != int.parse(customerId)) return forbidden();

    final q = request.url.queryParameters;
    final page = int.tryParse(q['page'] ?? '1') ?? 1;
    final limit = int.tryParse(q['limit'] ?? '20') ?? 20;
    final status = q['status'];
    final offset = (page - 1) * limit;

    final filters = <String>['customer_id=?'];
    final params = <dynamic>[int.parse(customerId)];
    if (status != null && status.isNotEmpty) {
      filters.add('status=?');
      params.add(status);
    }
    final where = 'WHERE ${filters.join(' AND ')}';

    final conn = await _db.getConnection();
    final totalRows =
        await conn.query('SELECT COUNT(*) as cnt FROM reservations $where', params);
    final total = totalRows.first['cnt'] as int;

    final rows = await conn.query(
        'SELECT * FROM reservations $where ORDER BY id DESC LIMIT ? OFFSET ?',
        [...params, limit, offset]);
    final items = rows
        .map((r) => {
              'id': r['id'],
              'reservation_number': r['reservation_number'],
              'reservation_date': r['reservation_date'].toString(),
              'status': r['status'],
              'subtotal': r['subtotal'],
              'service_charge': r['service_charge'],
              'discount': r['discount'],
              'total': r['total'],
              'payment_status': r['payment_status']
            })
        .toList();
    return ok({'items': items, 'page': page, 'limit': limit, 'total': total});
  }
}

