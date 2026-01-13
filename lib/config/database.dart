import 'package:mysql1/mysql1.dart';
import 'package:dotenv/dotenv.dart';

/// Đơn giản: mỗi lần gọi getConnection() sẽ tạo 1 kết nối mới.
/// Tránh dùng 1 connection chia sẻ cho nhiều request (dẫn tới Error 1156 packets out of order).
class Database {
  static final Database _instance = Database._internal();

  factory Database() => _instance;
  Database._internal();

  Future<MySqlConnection> getConnection() async {
    final env = DotEnv(includePlatformEnvironment: true)..load(['.env']);

    final settings = ConnectionSettings(
      host: env['DB_HOST'] ?? 'localhost',
      port: int.parse(env['DB_PORT'] ?? '3306'),
      user: env['DB_USER'] ?? 'root',
      password: env['DB_PASSWORD'] ?? '',
      db: env['DB_NAME'] ?? 'db_exam_171020459',
      // Thêm options để tránh lỗi packets out of order
      maxPacketSize: 16777216,
      timeout: Duration(seconds: 30),
    );

    return MySqlConnection.connect(settings);
  }

  /// Helper method để tự động đóng connection sau khi sử dụng
  Future<T> withConnection<T>(
    Future<T> Function(MySqlConnection conn) fn,
  ) async {
    MySqlConnection? conn;
    try {
      conn = await getConnection();
      return await fn(conn);
    } finally {
      await conn?.close();
    }
  }
}
