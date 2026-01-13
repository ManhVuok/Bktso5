import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:web_api_171020459/routes.dart';
import 'package:web_api_171020459/middleware/error_middleware.dart';

Future<void> main(List<String> args) async {
  // Load environment variables
  final env = DotEnv(includePlatformEnvironment: true)..load(['.env']);

  final host = env['HOST'] ?? InternetAddress.anyIPv4.host;
  final port = int.tryParse(env['PORT'] ?? '') ?? 8080;

  final router = buildRouter();

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addMiddleware(errorMiddleware())
      .addHandler(router);

  final server = await serve(handler, host, port);
  // ignore: avoid_print
  print('✅ Server running on http://${server.address.host}:${server.port}');
}

