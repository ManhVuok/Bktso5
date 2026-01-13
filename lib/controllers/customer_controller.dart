import 'dart:convert';

import 'package:mysql1/mysql1.dart';
import 'package:shelf/shelf.dart';

import '../config/database.dart';
import '../utils/request_user.dart';
import '../utils/response.dart';

class CustomerController {
  final _db = Database();

  bool _isAdmin(Request request) {
    final user = getUserFromAuthHeader(request.headers['Authorization']);
    return user?['is_admin'] == true;
  }

  Future<Response> listCustomers(Request request) async {
    if (!_isAdmin(request)) return forbidden();
    final conn = await _db.getConnection();
    final rows = await conn.query(
        'SELECT id, email, full_name, phone_number, address, loyalty_points, created_at, updated_at, is_active FROM customers');
    final items = rows
        .map((r) => {
              'id': r['id'],
              'email': r['email'],
              'full_name': r['full_name'],
              'phone_number': r['phone_number'],
              'address': r['address'],
              'loyalty_points': r['loyalty_points'],
              'created_at': r['created_at'].toString(),
              'updated_at': r['updated_at'].toString(),
              'is_active': (r['is_active'] as int) == 1,
            })
        .toList();
    return ok({'items': items});
  }

  Future<Response> getCustomer(Request request, String id) async {
    final user = getUserFromAuthHeader(request.headers['Authorization']);
    final isAdmin = user?['is_admin'] == true;
    final userId = user?['id'];
    if (user == null) return unauthorized();
    if (!isAdmin && userId != int.parse(id)) return forbidden();

    final conn = await _db.getConnection();
    final rows = await conn.query(
        'SELECT id, email, full_name, phone_number, address, loyalty_points, created_at, updated_at, is_active FROM customers WHERE id=?',
        [int.parse(id)]);
    if (rows.isEmpty) return notFound('Customer not found');
    final r = rows.first;
    return ok({
      'id': r['id'],
      'email': r['email'],
      'full_name': r['full_name'],
      'phone_number': r['phone_number'],
      'address': r['address'],
      'loyalty_points': r['loyalty_points'],
      'created_at': r['created_at'].toString(),
      'updated_at': r['updated_at'].toString(),
      'is_active': (r['is_active'] as int) == 1,
    });
  }

  Future<Response> updateCustomer(Request request, String id) async {
    final user = getUserFromAuthHeader(request.headers['Authorization']);
    if (user == null) return unauthorized();
    final isAdmin = user['is_admin'] == true;
    if (!isAdmin && user['id'] != int.parse(id)) return forbidden();

    final body = jsonDecode(await request.readAsString()) as Map;
    final conn = await _db.getConnection();
    await conn.query(
        '''UPDATE customers SET full_name=?, phone_number=?, address=?, updated_at=NOW() WHERE id=?''',
        [
          body['full_name'],
          body['phone_number'],
          body['address'],
          int.parse(id)
        ]);
    return ok({'message': 'Customer updated', 'id': int.parse(id)});
  }
}

