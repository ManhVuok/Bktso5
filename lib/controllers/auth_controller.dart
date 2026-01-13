import 'dart:convert';

import 'package:dotenv/dotenv.dart';
import 'package:mysql1/mysql1.dart';
import 'package:shelf/shelf.dart';

import '../config/database.dart';
import '../utils/jwt_helper.dart';
import '../utils/response.dart';
import '../utils/security.dart';
import '../utils/validation.dart';

class AuthController {
  static const String studentId = '171020459';

  final _db = Database();
  final _env = DotEnv(includePlatformEnvironment: true)..load(['.env']);

  JwtHelper get _jwt => JwtHelper(secret: _env['JWT_SECRET'] ?? 'secret');
  String get _adminEmail => _env['ADMIN_EMAIL'] ?? 'admin@example.com';

  Future<Response> register(Request request) async {
    final body = await request.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;

    final err = requireFields(data, ['email', 'password', 'full_name']);
    if (err != null) return err;

    final email = (data['email'] as String).trim();
    final password = data['password'] as String;
    final fullName = (data['full_name'] as String).trim();

    return await _db.withConnection<Response>((conn) async {
      final existing =
          await conn.query('SELECT id FROM customers WHERE email=?', [email]);
      if (existing.isNotEmpty) {
        return badRequest('Email already exists');
      }

      final hashed = hashPassword(password);
      final result = await conn.query(
          '''INSERT INTO customers (email, password, full_name, phone_number, address, loyalty_points, created_at, updated_at, is_active)
          VALUES (?, ?, ?, ?, ?, 0, NOW(), NOW(), TRUE)''',
          [email, hashed, fullName, data['phone_number'], data['address']]);

      final id = result.insertId!;
      final isAdmin = email == _adminEmail;
      final token = _jwt.sign(
          {'id': id, 'email': email, 'full_name': fullName, 'is_admin': isAdmin});

      return created({
        'message': 'Registered successfully',
        'token': token,
        'student_id': studentId,
        'user': {
          'id': id,
          'email': email,
          'full_name': fullName,
          'phone_number': data['phone_number'],
          'address': data['address'],
          'is_admin': isAdmin,
        }
      });
    });
  }

  Future<Response> login(Request request) async {
    final body = await request.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;
    final email = (data['email'] as String?)?.trim();
    final password = data['password'] as String?;
    if (email == null || email.isEmpty) return badRequest('email is required');
    if (password == null || password.isEmpty) {
      return badRequest('password is required');
    }

    return await _db.withConnection<Response>((conn) async {
      final rows = await conn.query(
          'SELECT id, email, password, full_name, phone_number, address FROM customers WHERE email=? LIMIT 1',
          [email]);
      if (rows.isEmpty) return unauthorized('Invalid credentials');
      final row = rows.first;
      final hashed = row['password'] as String;
      if (!verifyPassword(password, hashed)) {
        return unauthorized('Invalid credentials');
      }

      final isAdmin = email == _adminEmail;
      final token = _jwt.sign({
        'id': row['id'],
        'email': row['email'],
        'full_name': row['full_name'],
        'is_admin': isAdmin
      });

      return ok({
        'token': token,
        'student_id': studentId,
        'user': {
          'id': row['id'],
          'email': row['email'],
          'full_name': row['full_name'],
          'phone_number': row['phone_number'],
          'address': row['address'],
          'is_admin': isAdmin,
        }
      });
    });
  }

  Future<Response> me(Request request) async {
    final user = await _authenticate(request);
    if (user == null) return unauthorized();
    return ok({
      'user': user,
      'student_id': studentId,
    });
  }

  Future<Map<String, dynamic>?> _authenticate(Request request) async {
    final header = request.headers['Authorization'];
    if (header == null || !header.startsWith('Bearer ')) return null;
    final token = header.substring(7);
    final payload = _jwt.verify(token);
    if (payload == null) return null;
    return {
      'id': payload['id'],
      'email': payload['email'],
      'full_name': payload['full_name'],
      'is_admin': payload['is_admin'] ?? false,
    };
  }
}

