import 'package:dotenv/dotenv.dart';

import 'jwt_helper.dart';

DotEnv _env = DotEnv(includePlatformEnvironment: true)..load(['.env']);
JwtHelper _jwtHelper = JwtHelper(secret: _env['JWT_SECRET'] ?? 'secret');

Map<String, dynamic>? getUserFromAuthHeader(String? header) {
  if (header == null || !header.startsWith('Bearer ')) return null;
  final token = header.substring(7);
  final payload = _jwtHelper.verify(token);
  if (payload == null) return null;
  return {
    'id': payload['id'],
    'email': payload['email'],
    'full_name': payload['full_name'],
    'is_admin': payload['is_admin'] ?? false,
  };
}

