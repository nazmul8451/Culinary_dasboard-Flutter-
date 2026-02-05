class ProductModel {
  final String id;
  final String sellerId;
  final String name;
  final String description;
  final double price;
  final String category;
  final List<String> images;
  final bool isActive;
  final DateTime createdAt;
  final String? sellerName;
  final int stock;
  final double unitWeight;
  final String unitType; // kg, g, pack

  ProductModel({
    required this.id,
    required this.sellerId,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.images,
    required this.isActive,
    required this.createdAt,
    this.sellerName,
    this.stock = 0,
    this.unitWeight = 0.0,
    this.unitType = 'kg',
  });

  factory ProductModel.fromRealtimeDatabase(
    String id,
    Map<dynamic, dynamic> data,
  ) {
    return ProductModel(
      id: id,
      sellerId: data['sellerId']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      price: (data['price'] ?? 0).toDouble(),
      category: data['category']?.toString() ?? '',
      images: data['images'] != null
          ? List<String>.from(data['images'] as List)
          : [],
      isActive: data['isActive'] as bool? ?? true,
      createdAt: data['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int)
          : DateTime.now(),
      sellerName: data['sellerName']?.toString(),
      stock: data['stock'] as int? ?? 0,
      unitWeight: (data['unitWeight'] ?? 0.0).toDouble(),
      unitType: data['unitType']?.toString() ?? 'kg',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'images': images,
      'isActive': isActive,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'sellerName': sellerName,
      'stock': stock,
      'unitWeight': unitWeight,
      'unitType': unitType,
    };
  }
}
