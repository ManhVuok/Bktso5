class MenuItem {
  final int? id;
  final String name;
  final String? description;
  final String category; // "Appetizer", "Main Course", "Dessert", "Beverage", "Soup"
  final double price;
  final String? imageUrl;
  final int preparationTime;
  final bool isVegetarian;
  final bool isSpicy;
  final bool isAvailable;
  final double rating;
  final DateTime createdAt;
  final DateTime updatedAt;

  MenuItem({
    this.id,
    required this.name,
    this.description,
    required this.category,
    required this.price,
    this.imageUrl,
    required this.preparationTime,
    this.isVegetarian = false,
    this.isSpicy = false,
    this.isAvailable = true,
    this.rating = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MenuItem.fromMap(Map<String, dynamic> map) {
    return MenuItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      category: map['category'] as String,
      price: (map['price'] as num).toDouble(),
      imageUrl: map['image_url'] as String?,
      preparationTime: map['preparation_time'] as int? ?? 0,
      isVegetarian: (map['is_vegetarian'] as int? ?? 0) == 1,
      isSpicy: (map['is_spicy'] as int? ?? 0) == 1,
      isAvailable: (map['is_available'] as int? ?? 1) == 1,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['created_at'] is DateTime 
          ? map['created_at'] as DateTime 
          : DateTime.parse(map['created_at'].toString()),
      updatedAt: map['updated_at'] is DateTime 
          ? map['updated_at'] as DateTime 
          : DateTime.parse(map['updated_at'].toString()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'image_url': imageUrl,
      'preparation_time': preparationTime,
      'is_vegetarian': isVegetarian ? 1 : 0,
      'is_spicy': isSpicy ? 1 : 0,
      'is_available': isAvailable ? 1 : 0,
      'rating': rating,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'image_url': imageUrl,
      'preparation_time': preparationTime,
      'is_vegetarian': isVegetarian,
      'is_spicy': isSpicy,
      'is_available': isAvailable,
      'rating': rating,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

