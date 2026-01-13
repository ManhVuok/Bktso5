import 'dart:io';

import 'package:mysql1/mysql1.dart';
import 'package:dotenv/dotenv.dart';

Future<void> main() async {
  final env = DotEnv(includePlatformEnvironment: true)..load(['.env']);

  final settings = ConnectionSettings(
    host: env['DB_HOST'] ?? 'localhost',
    port: int.parse(env['DB_PORT'] ?? '3306'),
    user: env['DB_USER'] ?? 'root',
    password: env['DB_PASSWORD'] ?? '',
    db: env['DB_NAME'] ?? 'db_exam_171020459',
  );

  final conn = await MySqlConnection.connect(settings);
  final migrationsDir = Directory('migrations');
  if (!migrationsDir.existsSync()) {
    // ignore: avoid_print
    print('No migrations directory found.');
    await conn.close();
    return;
  }

  final files = migrationsDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.sql'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final sql = await file.readAsString();
    // ignore: avoid_print
    print('Running migration: ${file.path}');

    // MySQL driver không hỗ trợ multi-statement trong một query,
    // nên cần tách file .sql thành từng câu lệnh nhỏ.
    final statements = sql.split(';');
    for (var stmt in statements) {
      final s = stmt.trim();
      if (s.isEmpty) continue;
      await conn.query('$s;');
    }
  }

  await conn.close();
  // ignore: avoid_print
  print('Migrations completed.');
}

