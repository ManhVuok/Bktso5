class ReservationItem {
  final int? id;
  final int reservationId;
  final int menuItemId;
  final int quantity;
  final double price;
  final DateTime createdAt;

  ReservationItem({
    this.id,
    required this.reservationId,
    required this.menuItemId,
    required this.quantity,
    required this.price,
    required this.createdAt,
  });

  factory ReservationItem.fromMap(Map<String, dynamic> map) {
    return ReservationItem(
      id: map['id'] as int?,
      reservationId: map['reservation_id'] as int,
      menuItemId: map['menu_item_id'] as int,
      quantity: map['quantity'] as int,
      price: (map['price'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'].toString()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reservation_id': reservationId,
      'menu_item_id': menuItemId,
      'quantity': quantity,
      'price': price,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

