import 'package:mysql1/mysql1.dart';

void main() async {
  final passwords = ['', 'root', '123456', 'password', 'admin', '1234', 'mysql'];
  final port = 3305;
  
  print('=== KIỂM TRA MẬT KHẨU MYSQL ===\n');
  print('Đang thử kết nối với user: root, port: $port\n');
  
  for (var pwd in passwords) {
    try {
      print('Thử mật khẩu: "${pwd.isEmpty ? '(trống)' : pwd}"...');
      final conn = await MySqlConnection.connect(
        ConnectionSettings(
          host: 'localhost',
          port: port,
          user: 'root',
          password: pwd,
          db: 'mysql', // Kết nối vào database mysql để test
        ),
      );
      
      // Nếu kết nối thành công, kiểm tra xem có database db_exam_171020459 chưa
      final result = await conn.query('SHOW DATABASES LIKE "db_exam_171020459"');
      
      print('✅ THÀNH CÔNG! Mật khẩu đúng là: "${pwd.isEmpty ? '(trống)' : pwd}"');
      print('   Database db_exam_171020459: ${result.isEmpty ? "CHƯA TẠO" : "ĐÃ TẠO"}');
      
      await conn.close();
      break;
    } catch (e) {
      if (e.toString().contains('Access denied')) {
        print('   ❌ Không đúng\n');
      } else {
        print('   ⚠️  Lỗi khác: $e\n');
      }
    }
  }
  
  print('\n=== KẾT THÚC KIỂM TRA ===');
  print('Nếu không tìm thấy mật khẩu, bạn cần reset password MySQL.');
}

