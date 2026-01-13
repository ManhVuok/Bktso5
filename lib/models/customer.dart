class Customer {
  final int? id;
  final String email;
  final String password;
  final String fullName;
  final String? phoneNumber;
  final String? address;
  final int loyaltyPoints;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  Customer({
    this.id,
    required this.email,
    required this.password,
    required this.fullName,
    this.phoneNumber,
    this.address,
    this.loyaltyPoints = 0,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      email: map['email'] as String,
      password: map['password'] as String,
      fullName: map['full_name'] as String,
      phoneNumber: map['phone_number'] as String?,
      address: map['address'] as String?,
      loyaltyPoints: map['loyalty_points'] as int? ?? 0,
      createdAt: map['created_at'] is DateTime 
          ? map['created_at'] as DateTime 
          : DateTime.parse(map['created_at'].toString()),
      updatedAt: map['updated_at'] is DateTime 
          ? map['updated_at'] as DateTime 
          : DateTime.parse(map['updated_at'].toString()),
      isActive: (map['is_active'] as int? ?? 1) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'address': address,
      'loyalty_points': loyaltyPoints,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'address': address,
      'loyalty_points': loyaltyPoints,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
    };
  }
}

