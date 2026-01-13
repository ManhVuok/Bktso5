# Restaurant Management System - Web API

**Mã Sinh Viên:** 171020459  
**Database:** db_exam_171020459

## Cài đặt

1. Cài đặt dependencies:
```bash
dart pub get
```

2. Tạo file `.env` và cấu hình:
```env
HOST=0.0.0.0
PORT=8080
DB_HOST=localhost
DB_PORT=3305
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=db_exam_171020459
JWT_SECRET=super-secret-key
ADMIN_EMAIL=admin@example.com
```

3. Tạo database:
```sql
CREATE DATABASE db_exam_171020459;
```

4. Chạy migrations:
```bash
dart run bin/migrate.dart
```

5. Chạy seeder:
```bash
dart run bin/seed.dart
```

6. Chạy server:
```bash
dart run bin/server.dart
```

Server sẽ chạy tại: `http://localhost:8080`

## API Endpoints

Xem file `API_DOCUMENTATION.md` để biết chi tiết các endpoints.

## Cấu trúc Project

```
web_api_171020459/
├── bin/
│   ├── server.dart          # Entry point
│   ├── migrate.dart         # Database migrations
│   └── seed.dart            # Seeder data
├── lib/
│   ├── config/
│   │   └── database.dart   # Database connection
│   ├── models/              # Data models
│   ├── controllers/         # Route handlers
│   ├── middleware/          # Auth middleware
│   ├── utils/               # Utilities
│   └── routes.dart          # Route definitions
└── migrations/              # SQL migration files
```

