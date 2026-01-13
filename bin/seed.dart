import 'package:crypto/crypto.dart';
import 'package:dotenv/dotenv.dart';
import 'package:mysql1/mysql1.dart';
import 'dart:convert';

String hashPassword(String password) {
  final bytes = utf8.encode(password);
  return sha256.convert(bytes).toString();
}

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

  // Seed customers
  final customers = [
    {
      'email': env['ADMIN_EMAIL'] ?? 'admin@example.com',
      'password': hashPassword('admin123'),
      'full_name': 'Admin User',
      'phone_number': '0123456789',
      'address': '123 Admin St',
      'loyalty_points': 0
    },
    {
      'email': 'customer1@example.com',
      'password': hashPassword('password1'),
      'full_name': 'Customer One',
      'phone_number': '0900000001',
      'address': 'Address 1',
      'loyalty_points': 100
    },
    {
      'email': 'customer2@example.com',
      'password': hashPassword('password2'),
      'full_name': 'Customer Two',
      'phone_number': '0900000002',
      'address': 'Address 2',
      'loyalty_points': 200
    },
    {
      'email': 'customer3@example.com',
      'password': hashPassword('password3'),
      'full_name': 'Customer Three',
      'phone_number': '0900000003',
      'address': 'Address 3',
      'loyalty_points': 300
    },
    {
      'email': 'customer4@example.com',
      'password': hashPassword('password4'),
      'full_name': 'Customer Four',
      'phone_number': '0900000004',
      'address': 'Address 4',
      'loyalty_points': 400
    },
  ];

  for (final c in customers) {
    await conn.query(
      '''INSERT INTO customers (email, password, full_name, phone_number, address, loyalty_points, created_at, updated_at, is_active)
      VALUES (?, ?, ?, ?, ?, ?, NOW(), NOW(), TRUE)
      ON DUPLICATE KEY UPDATE email=email''',
      [
        c['email'],
        c['password'],
        c['full_name'],
        c['phone_number'],
        c['address'],
        c['loyalty_points'],
      ],
    );
  }

  // Seed tables
  final tables = List.generate(8, (i) {
    final num = i + 1;
    return {
      'table_number': 'T${num.toString().padLeft(2, '0')}',
      'capacity': 2 + (num % 4) * 2
    };
  });

  for (final t in tables) {
    await conn.query(
      '''INSERT INTO tables (table_number, capacity, is_available, created_at, updated_at)
      VALUES (?, ?, TRUE, NOW(), NOW())
      ON DUPLICATE KEY UPDATE table_number=table_number''',
      [t['table_number'], t['capacity']],
    );
  }

  // Seed menu items (20)
  final categories = ['Appetizer', 'Main Course', 'Dessert', 'Beverage', 'Soup'];
  final menuItems = List.generate(20, (i) {
    final idx = i + 1;
    return {
      'name': 'Dish $idx',
      'description': 'Delicious dish $idx',
      'category': categories[i % categories.length],
      'price': 50000 + (i * 5000),
      'image_url': null,
      'preparation_time': 10 + i,
      'is_vegetarian': i % 3 == 0,
      'is_spicy': i % 4 == 0,
      'is_available': true,
      'rating': 4.0
    };
  });

  for (final m in menuItems) {
    await conn.query(
      '''INSERT INTO menu_items (name, description, category, price, image_url, preparation_time, is_vegetarian, is_spicy, is_available, rating, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())''',
      [
        m['name'],
        m['description'],
        m['category'],
        m['price'],
        m['image_url'],
        m['preparation_time'],
        m['is_vegetarian'] as bool ? 1 : 0,
        m['is_spicy'] as bool ? 1 : 0,
        m['is_available'] as bool ? 1 : 0,
        m['rating'],
      ],
    );
  }

  // Create reservations (10) with items
  for (var i = 0; i < 10; i++) {
    final customerId = (i % customers.length) + 1;
    final res = await conn.query(
      '''INSERT INTO reservations (customer_id, reservation_number, reservation_date, number_of_guests, status, subtotal, service_charge, discount, total, payment_status, created_at, updated_at)
      VALUES (?, ?, DATE_ADD(NOW(), INTERVAL ? DAY), ?, 'pending', 0, 0, 0, 0, 'pending', NOW(), NOW())''',
      [
        customerId,
        'RES-SEED-${i + 1}',
        i,
        2 + (i % 4)
      ],
    );
    final reservationId = res.insertId!;

    // add two items
    for (var j = 0; j < 2; j++) {
      final menuId = (j + i) % menuItems.length + 1;
      final qty = 1 + (j % 2);
      final priceResult =
          await conn.query('SELECT price FROM menu_items WHERE id = ?', [menuId]);
      final price = (priceResult.first['price'] as num).toDouble();
      await conn.query(
        '''INSERT INTO reservation_items (reservation_id, menu_item_id, quantity, price, created_at)
        VALUES (?, ?, ?, ?, NOW())''',
        [reservationId, menuId, qty, price],
      );
    }

    // recalc totals
    final totals = await conn.query(
        'SELECT SUM(quantity*price) as subtotal FROM reservation_items WHERE reservation_id=?',
        [reservationId]);
    final subtotal = (totals.first['subtotal'] as num?)?.toDouble() ?? 0;
    final serviceCharge = subtotal * 0.1;
    final total = subtotal + serviceCharge;
    await conn.query(
        '''UPDATE reservations SET subtotal=?, service_charge=?, total=? WHERE id=?''',
        [subtotal, serviceCharge, total, reservationId]);
  }

  await conn.close();
  // ignore: avoid_print
  print('Seeding completed.');
}

