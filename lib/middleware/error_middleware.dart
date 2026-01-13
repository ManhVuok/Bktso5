import 'dart:convert';

import 'package:shelf/shelf.dart';

/// Global error handler to return consistent JSON responses.
Middleware errorMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      try {
        return await innerHandler(request);
      } catch (e, _) {
        return Response.internalServerError(
          body: jsonEncode({'error': e.toString(), 'status': 500}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    };
  };
}

