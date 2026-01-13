import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../config/database.dart';
import '../utils/request_user.dart';
import '../utils/response.dart';

class TableController {
  final _db = Database();

  bool _isAdmin(Request request) {
    final user = getUserFromAuthHeader(request.headers['Authorization']);
    return user?['is_admin'] == true;
  }

  Future<Response> listTables(Request request) async {
    final availableOnly = request.url.queryParameters['available_only'] == 'true';
    final conn = await _db.getConnection();
    final where = availableOnly ? 'WHERE is_available=1' : '';
    final rows = await conn.query('SELECT * FROM tables $where ORDER BY id DESC');
    final items = rows
        .map((r) => {
              'id': r['id'],
              'table_number': r['table_number'],
              'capacity': r['capacity'],
              'is_available': (r['is_available'] as int) == 1,
              'created_at': r['created_at'].toString(),
              'updated_at': r['updated_at'].toString(),
            })
        .toList();
    return ok({'items': items});
  }

  Future<Response> createTable(Request request) async {
    if (!_isAdmin(request)) return forbidden();
    final data = jsonDecode(await request.readAsString()) as Map;
    final conn = await _db.getConnection();
    final result = await conn.query(
        '''INSERT INTO tables (table_number, capacity, is_available, created_at, updated_at)
        VALUES (?, ?, ?, NOW(), NOW())''',
        [
          data['table_number'],
          data['capacity'],
          (data['is_available'] ?? true) ? 1 : 0
        ]);
    return created({'message': 'Table created', 'id': result.insertId});
  }

  Future<Response> updateTable(Request request, String id) async {
    if (!_isAdmin(request)) return forbidden();
    final data = jsonDecode(await request.readAsString()) as Map;
    final conn = await _db.getConnection();
    await conn.query(
        '''UPDATE tables SET table_number=?, capacity=?, is_available=?, updated_at=NOW() WHERE id=?''',
        [
          data['table_number'],
          data['capacity'],
          (data['is_available'] ?? true) ? 1 : 0,
          int.parse(id)
        ]);
    return ok({'message': 'Table updated', 'id': int.parse(id)});
  }

  Future<Response> deleteTable(Request request, String id) async {
    if (!_isAdmin(request)) return forbidden();
    final conn = await _db.getConnection();
    await conn.query('DELETE FROM tables WHERE id=?', [int.parse(id)]);
    return ok({'message': 'Table deleted', 'id': int.parse(id)});
  }
}

