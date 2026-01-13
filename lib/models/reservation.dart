class Reservation {
  final int? id;
  final int customerId;
  final String reservationNumber;
  final DateTime reservationDate;
  final int numberOfGuests;
  final String? tableNumber;
  final String status;
  final String? specialRequests;
  final double subtotal;
  final double serviceCharge;
  final double discount;
  final double total;
  final String? paymentMethod;
  final String paymentStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  Reservation({
    this.id,
    required this.customerId,
    required this.reservationNumber,
    required this.reservationDate,
    required this.numberOfGuests,
    this.tableNumber,
    this.status = 'pending',
    this.specialRequests,
    this.subtotal = 0,
    this.serviceCharge = 0,
    this.discount = 0,
    this.total = 0,
    this.paymentMethod,
    this.paymentStatus = 'pending',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Reservation.fromMap(Map<String, dynamic> map) {
    return Reservation(
      id: map['id'] as int?,
      customerId: map['customer_id'] as int,
      reservationNumber: map['reservation_number'] as String,
      reservationDate: DateTime.parse(map['reservation_date'].toString()),
      numberOfGuests: map['number_of_guests'] as int,
      tableNumber: map['table_number'] as String?,
      status: map['status'] as String? ?? 'pending',
      specialRequests: map['special_requests'] as String?,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
      serviceCharge: (map['service_charge'] as num?)?.toDouble() ?? 0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0,
      total: (map['total'] as num?)?.toDouble() ?? 0,
      paymentMethod: map['payment_method'] as String?,
      paymentStatus: map['payment_status'] as String? ?? 'pending',
      createdAt: DateTime.parse(map['created_at'].toString()),
      updatedAt: DateTime.parse(map['updated_at'].toString()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'reservation_number': reservationNumber,
      'reservation_date': reservationDate.toIso8601String(),
      'number_of_guests': numberOfGuests,
      'table_number': tableNumber,
      'status': status,
      'special_requests': specialRequests,
      'subtotal': subtotal,
      'service_charge': serviceCharge,
      'discount': discount,
      'total': total,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

