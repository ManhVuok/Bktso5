import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../config/database.dart';
import '../utils/request_user.dart';
import '../utils/response.dart';
import '../utils/validation.dart';

class MenuController {
  final _db = Database();

  bool _isAdmin(Request request) {
    final user = getUserFromAuthHeader(request.headers['Authorization']);
    return user?['is_admin'] == true;
  }

  Future<Response> listMenuItems(Request request) async {
    final q = request.url.queryParameters;
    final page = int.tryParse(q['page'] ?? '1') ?? 1;
    final limit = int.tryParse(q['limit'] ?? '20') ?? 20;
    final offset = (page - 1) * limit;
    final search = q['search'];
    final category = q['category'];
    final vegetarianOnly = q['vegetarian_only'] == 'true';
    final spicyOnly = q['spicy_only'] == 'true';
    final availableOnly = q['available_only'] == 'true';

    final filters = <String>[];
    final params = <dynamic>[];
    if (search != null && search.isNotEmpty) {
      filters.add('(name LIKE ? OR description LIKE ?)');
      params.add('%$search%');
      params.add('%$search%');
    }
    if (category != null && category.isNotEmpty) {
      filters.add('category = ?');
      params.add(category);
    }
    if (vegetarianOnly) filters.add('is_vegetarian = 1');
    if (spicyOnly) filters.add('is_spicy = 1');
    if (availableOnly) filters.add('is_available = 1');

    final where =
        filters.isEmpty ? '' : 'WHERE ${filters.join(' AND ')}';

    final conn = await _db.getConnection();
    final totalRows = await conn
        .query('SELECT COUNT(*) as cnt FROM menu_items $where', params);
    final total = totalRows.first['cnt'] as int;

    final itemsRows = await conn.query(
        'SELECT * FROM menu_items $where ORDER BY id DESC LIMIT ? OFFSET ?',
        [...params, limit, offset]);
    final items = itemsRows
        .map((r) => {
              'id': r['id'],
              'name': r['name'],
              'description': r['description'],
              'category': r['category'],
              'price': r['price'],
              'image_url': r['image_url'],
              'preparation_time': r['preparation_time'],
              'is_vegetarian': (r['is_vegetarian'] as int) == 1,
              'is_spicy': (r['is_spicy'] as int) == 1,
              'is_available': (r['is_available'] as int) == 1,
              'rating': r['rating'],
              'created_at': r['created_at'].toString(),
              'updated_at': r['updated_at'].toString(),
            })
        .toList();

    return ok({
      'items': items,
      'page': page,
      'limit': limit,
      'total': total,
    });
  }

  Future<Response> searchMenuItems(Request request) async {
    final query = request.url.queryParameters['search'] ?? '';
    final conn = await _db.getConnection();
    final rows = await conn.query(
        'SELECT * FROM menu_items WHERE name LIKE ? OR description LIKE ? LIMIT 20',
        ['%$query%', '%$query%']);
    final items = rows
        .map((r) => {
              'id': r['id'],
              'name': r['name'],
              'price': r['price'],
              'is_available': (r['is_available'] as int) == 1
            })
        .toList();
    return ok({'items': items, 'search': query});
  }

  Future<Response> getMenuItem(Request request, String id) async {
    final conn = await _db.getConnection();
    final rows =
        await conn.query('SELECT * FROM menu_items WHERE id=?', [int.parse(id)]);
    if (rows.isEmpty) return notFound('Menu item not found');
    final r = rows.first;
    return ok({
      'id': r['id'],
      'name': r['name'],
      'description': r['description'],
      'category': r['category'],
      'price': r['price'],
      'image_url': r['image_url'],
      'preparation_time': r['preparation_time'],
      'is_vegetarian': (r['is_vegetarian'] as int) == 1,
      'is_spicy': (r['is_spicy'] as int) == 1,
      'is_available': (r['is_available'] as int) == 1,
      'rating': r['rating'],
      'created_at': r['created_at'].toString(),
      'updated_at': r['updated_at'].toString(),
    });
  }

  Future<Response> createMenuItem(Request request) async {
    if (!_isAdmin(request)) return forbidden();
    final data = jsonDecode(await request.readAsString()) as Map;
    final err = requireFields(
        data,
        ['name', 'category', 'price', 'preparation_time'],
        messages: {
          'name': 'name is required',
          'category': 'category is required',
          'price': 'price is required',
          'preparation_time': 'preparation_time is required',
        });
    if (err != null) return err;
    final conn = await _db.getConnection();
    final result = await conn.query(
        '''INSERT INTO menu_items (name, description, category, price, image_url, preparation_time, is_vegetarian, is_spicy, is_available, rating, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())''',
        [
          data['name'],
          data['description'],
          data['category'],
          data['price'],
          data['image_url'],
          data['preparation_time'],
          (data['is_vegetarian'] ?? false) ? 1 : 0,
          (data['is_spicy'] ?? false) ? 1 : 0,
          (data['is_available'] ?? true) ? 1 : 0,
          data['rating'] ?? 0.0
        ]);
    return created({'message': 'Menu item created', 'id': result.insertId});
  }

  Future<Response> updateMenuItem(Request request, String id) async {
    if (!_isAdmin(request)) return forbidden();
    final data = jsonDecode(await request.readAsString()) as Map;
    final conn = await _db.getConnection();
    await conn.query(
        '''UPDATE menu_items SET name=?, description=?, category=?, price=?, image_url=?, preparation_time=?, is_vegetarian=?, is_spicy=?, is_available=?, rating=?, updated_at=NOW() WHERE id=?''',
        [
          data['name'],
          data['description'],
          data['category'],
          data['price'],
          data['image_url'],
          data['preparation_time'],
          (data['is_vegetarian'] ?? false) ? 1 : 0,
          (data['is_spicy'] ?? false) ? 1 : 0,
          (data['is_available'] ?? true) ? 1 : 0,
          data['rating'] ?? 0.0,
          int.parse(id)
        ]);
    return ok({'message': 'Menu item updated', 'id': int.parse(id)});
  }

  Future<Response> deleteMenuItem(Request request, String id) async {
    if (!_isAdmin(request)) return forbidden();
    final conn = await _db.getConnection();

    // check relation
    final pending = await conn.query(
        '''SELECT ri.id FROM reservation_items ri
        JOIN reservations r ON r.id = ri.reservation_id
        WHERE ri.menu_item_id=? AND r.status <> 'completed' LIMIT 1''',
        [int.parse(id)]);
    if (pending.isNotEmpty) {
      return badRequest(
          'Cannot delete: item exists in reservations not completed.');
    }

    await conn.query('DELETE FROM menu_items WHERE id=?', [int.parse(id)]);
    return ok({'message': 'Menu item deleted', 'id': int.parse(id)});
  }
}

