import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class JwtHelper {
  final String secret;
  final Duration expiresIn;

  JwtHelper({required this.secret, this.expiresIn = const Duration(hours: 12)});

  String sign(Map<String, dynamic> payload) {
    final jwt = JWT(payload);
    return jwt.sign(SecretKey(secret), expiresIn: expiresIn);
  }

  Map<String, dynamic>? verify(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(secret));
      return jwt.payload;
    } catch (_) {
      return null;
    }
  }
}

