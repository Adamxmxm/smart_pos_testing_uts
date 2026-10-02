class OrderItemModel {
  final String? id;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final String? imageUrl;
  final String? notes;

  OrderItemModel({
    this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.imageUrl,
    this.notes,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final qty = (json['quantity'] as num?)?.toInt() ?? 1;
    final price = (json['unit_price'] as num?)?.toDouble() ?? 0.0;
    return OrderItemModel(
      id: json['id']?.toString(),
      productId: json['product_id']?.toString() ?? '',
      productName: json['products'] != null
          ? json['products']['name'] ?? 'Produk'
          : (json['product_name'] ?? 'Produk'),
      quantity: qty,
      unitPrice: price,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? (qty * price),
      imageUrl: json['products'] != null
          ? json['products']['image_url']
          : json['image_url'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson(String orderId) => {
    'order_id': orderId,
    'product_id': productId,
    'product_name': productName,
    'quantity': quantity,
    'unit_price': unitPrice,
    'subtotal': subtotal,
    if (notes != null && notes!.isNotEmpty) 'notes': notes,
  };

  OrderItemModel copyWith({
    String? id,
    String? productId,
    String? productName,
    int? quantity,
    double? unitPrice,
    double? subtotal,
    String? imageUrl,
    String? notes,
  }) {
    return OrderItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      subtotal:
          subtotal ??
          (quantity != null
              ? (quantity * (unitPrice ?? this.unitPrice))
              : this.subtotal),
      imageUrl: imageUrl ?? this.imageUrl,
      notes: notes ?? this.notes,
    );
  }
}
