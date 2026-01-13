class TableModel {
  final int? id;
  final String tableNumber;
  final int capacity;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  TableModel({
    this.id,
    required this.tableNumber,
    required this.capacity,
    this.isAvailable = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TableModel.fromMap(Map<String, dynamic> map) {
    return TableModel(
      id: map['id'] as int?,
      tableNumber: map['table_number'] as String,
      capacity: map['capacity'] as int,
      isAvailable: (map['is_available'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'].toString()),
      updatedAt: DateTime.parse(map['updated_at'].toString()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'table_number': tableNumber,
      'capacity': capacity,
      'is_available': isAvailable ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

