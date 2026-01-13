import 'package:shelf_router/shelf_router.dart';

import 'controllers/auth_controller.dart';
import 'controllers/customer_controller.dart';
import 'controllers/menu_controller.dart';
import 'controllers/reservation_controller.dart';
import 'controllers/table_controller.dart';

Router buildRouter() {
  final router = Router();

  final authController = AuthController();
  final customerController = CustomerController();
  final menuController = MenuController();
  final reservationController = ReservationController();
  final tableController = TableController();

  // Auth
  router.post('/api/auth/register', authController.register);
  router.post('/api/auth/login', authController.login);
  router.get('/api/auth/me', authController.me);

  // Customers
  router.get('/api/customers', customerController.listCustomers);
  router.get('/api/customers/<id|[0-9]+>', customerController.getCustomer);
  router.put('/api/customers/<id|[0-9]+>', customerController.updateCustomer);
  router.get('/api/customers/<id|[0-9]+>/reservations',
      reservationController.listCustomerReservations);

  // Menu
  router.get('/api/menu-items', menuController.listMenuItems);
  router.get('/api/menu-items/<id|[0-9]+>', menuController.getMenuItem);
  router.post('/api/menu-items', menuController.createMenuItem);
  router.put('/api/menu-items/<id|[0-9]+>', menuController.updateMenuItem);
  router.delete('/api/menu-items/<id|[0-9]+>', menuController.deleteMenuItem);
  router.get('/api/menu-items/search', menuController.searchMenuItems);

  // Reservations
  router.post('/api/reservations', reservationController.createReservation);
  router.get(
      '/api/reservations/<id|[0-9]+>', reservationController.getReservation);
  router.post('/api/reservations/<id|[0-9]+>/items',
      reservationController.addItem);
  router.put('/api/reservations/<id|[0-9]+>/confirm',
      reservationController.confirmReservation);
  router.put('/api/reservations/<id|[0-9]+>/seat',
      reservationController.seatReservation);
  router.post(
      '/api/reservations/<id|[0-9]+>/pay', reservationController.payReservation);
  router.delete(
      '/api/reservations/<id|[0-9]+>', reservationController.cancelReservation);

  // Tables
  router.get('/api/tables', tableController.listTables);
  router.post('/api/tables', tableController.createTable);
  router.put('/api/tables/<id|[0-9]+>', tableController.updateTable);
  router.delete('/api/tables/<id|[0-9]+>', tableController.deleteTable);

  return router;
}

