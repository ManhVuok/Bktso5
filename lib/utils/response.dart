import 'dart:convert';

import 'package:shelf/shelf.dart';

Response jsonResponse(int statusCode, Map<String, dynamic> body) {
  return Response(statusCode,
      body: jsonEncode(body), headers: {'Content-Type': 'application/json'});
}

Response ok(Map<String, dynamic> body) => jsonResponse(200, body);

Response created(Map<String, dynamic> body) => jsonResponse(201, body);

Response badRequest(String message) =>
    jsonResponse(400, {'error': message, 'status': 400});

Response unauthorized([String message = 'Unauthorized']) =>
    jsonResponse(401, {'error': message, 'status': 401});

Response forbidden([String message = 'Forbidden']) =>
    jsonResponse(403, {'error': message, 'status': 403});

Response notFound([String message = 'Not found']) =>
    jsonResponse(404, {'error': message, 'status': 404});

Response serverError([String message = 'Server error']) =>
    jsonResponse(500, {'error': message, 'status': 500});

