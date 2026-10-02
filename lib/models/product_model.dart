class ProductModel {
  final String id;
  final String? categoryId;
  final String name;
  final double price;
  final int stock;
  final String? imageUrl;

  ProductModel({
    required this.id,
    this.categoryId,
    required this.name,
    required this.price,
    required this.stock,
    this.imageUrl,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? '',
      categoryId: json['category_id']?.toString(),
      name: json['name'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson({bool includeId = false}) {
    final data = <String, dynamic>{
      'category_id': categoryId,
      'name': name,
      'price': price,
      'stock': stock,
      'image_url': imageUrl,
    };
    if (includeId) {
      data['id'] = id;
    }
    return data;
  }

  ProductModel copyWith({
    String? id,
    String? categoryId,
    String? name,
    double? price,
    int? stock,
    String? imageUrl,
  }) {
    return ProductModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
