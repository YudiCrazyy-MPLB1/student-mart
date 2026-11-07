class Product {
  final int id;
  final String name;
  final int price;
  final String category;
  final int categoryId;
  final String description;
  final int stock;
  final String? image;
  final bool isActive;
  final String? barcode;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.categoryId,
    required this.description,
    required this.stock,
    this.image,
    required this.isActive,
    this.barcode,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Helper untuk mengubah int / String menjadi int
    int parseInt(dynamic value) {
      if (value is int) {
        return value;
      }

      if (value is double) {
        return value.toInt();
      }

      if (value is String) {
        return int.tryParse(value) ?? 0;
      }

      return 0;
    }

    // Helper untuk boolean
    bool parseBool(dynamic value) {
      if (value is bool) {
        return value;
      }

      if (value is int) {
        return value == 1;
      }

      if (value is String) {
        return value == '1' || value.toLowerCase() == 'true';
      }

      return true;
    }

    return Product(
      id: parseInt(json['id']),
      barcode: json['barcode']?.toString(),
      name: json['name']?.toString() ?? '',
      price: parseInt(json['price']),
      category: json['category'] is Map
          ? json['category']['name']?.toString() ?? ''
          : json['category']?.toString() ?? '',
      categoryId: parseInt(
        json['category_id'] ??
            (json['category'] is Map ? json['category']['id'] : null),
      ),
      description: json['description']?.toString() ?? '',
      stock: parseInt(json['stock']),
      image: json['image']?.toString(),
      isActive: parseBool(json['is_active']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'price': price,
      'category': category,
      'category_id': categoryId,
      'description': description,
      'stock': stock,
      'image': image,
      'is_active': isActive,
    };
  }
}
