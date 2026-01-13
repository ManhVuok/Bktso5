# Restaurant Web API - 171020459

## Auth
- POST `/api/auth/register`
- POST `/api/auth/login` → response includes `student_id: "171020459"`
- GET `/api/auth/me`

## Customers
- GET `/api/customers` (admin)
- GET `/api/customers/{id}` (admin or self)
- PUT `/api/customers/{id}` (admin or self)
- GET `/api/customers/{id}/reservations`

## Menu
- GET `/api/menu-items` (pagination, filters: search, category, vegetarian_only, spicy_only, available_only)
- GET `/api/menu-items/{id}`
- GET `/api/menu-items/search`
- POST `/api/menu-items` (admin)
- PUT `/api/menu-items/{id}` (admin)
- DELETE `/api/menu-items/{id}` (admin, blocked if item in unfinished reservation)

## Reservations
- POST `/api/reservations` (auth) → creates pending with generated code
- POST `/api/reservations/{id}/items` (owner) → recalculates totals (10% service)
- PUT `/api/reservations/{id}/confirm` (admin) → assigns table, marks table unavailable
- PUT `/api/reservations/{id}/seat` (admin) → set status to `seated` (required before pay)
- GET `/api/reservations/{id}` (owner/admin) with items
- GET `/api/customers/{id}/reservations` (owner/admin, pagination, status filter)
- POST `/api/reservations/{id}/pay` (owner/admin) → supports loyalty points (1pt=1000, max 50%), adds 1% points, frees table, sets status completed
- DELETE `/api/reservations/{id}` (owner pending/confirmed or admin) → frees table if assigned

## Tables
- GET `/api/tables` (filter `available_only=true`)
- POST `/api/tables` (admin)
- PUT `/api/tables/{id}` (admin)
- DELETE `/api/tables/{id}` (admin)

## Notes
- Auth via Bearer JWT. Admin recognized by `ADMIN_EMAIL` in `.env`.
- Database: MySQL, name `db_exam_171020459`.
- See `bin/migrate.dart` and `bin/seed.dart` to prepare DB. Use `.env` for credentials and `JWT_SECRET`.

