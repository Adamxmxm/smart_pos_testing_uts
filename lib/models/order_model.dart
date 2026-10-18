// ignore_for_file: constant_identifier_names
import 'order_item_model.dart';

enum PaymentMethod { TUNAI, NON_TUNAI }

enum OrderStatus { OPEN, COMPLETED, CANCELLED }

class OrderModel {
  final String? id;
  final String invoiceNumber;
  final String? customerName;
  final OrderStatus status;
  final PaymentMethod? paymentMethod;
  final double totalAmount;
  final double payAmount;
  final double changeAmount;
  final List<OrderItemModel> items;
  final DateTime createdAt;
  final String? userId;

  OrderModel({
    this.id,
    required this.invoiceNumber,
    this.customerName,
    required this.status,
    this.paymentMethod,
    required this.totalAmount,
    this.payAmount = 0,
    this.changeAmount = 0,
    required this.items,
    required this.createdAt,
    this.userId,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json, {List<OrderItemModel>? items}) {
    OrderStatus status = OrderStatus.OPEN;
    if (json['status'] == 'COMPLETED') {
      status = OrderStatus.COMPLETED;
    } else if (json['status'] == 'CANCELLED') {
      status = OrderStatus.CANCELLED;
    }

    PaymentMethod? paymentMethod;
    if (json['payment_method'] == 'TUNAI') {
      paymentMethod = PaymentMethod.TUNAI;
    } else if (json['payment_method'] == 'NON_TUNAI') {
      paymentMethod = PaymentMethod.NON_TUNAI;
    }

    List<OrderItemModel> orderItems = items ?? [];
    if (json['order_items'] != null && json['order_items'] is List) {
      orderItems = (json['order_items'] as List)
          .map((itemJson) => OrderItemModel.fromJson(itemJson))
          .toList();
    }

    return OrderModel(
      id: json['id']?.toString(),
      invoiceNumber: json['invoice_number'] ?? '',
      customerName: json['customer_name'],
      status: status,
      paymentMethod: paymentMethod,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      payAmount: (json['pay_amount'] as num?)?.toDouble() ?? 0.0,
      changeAmount: (json['change_amount'] as num?)?.toDouble() ?? 0.0,
      items: orderItems,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      userId: json['user_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson({bool includeId = false}) {
    final data = <String, dynamic>{
      'invoice_number': invoiceNumber,
      'customer_name': customerName,
      'status': status.name,
      'payment_method': paymentMethod?.name,
      'total_amount': totalAmount,
      'pay_amount': payAmount,
      'change_amount': changeAmount,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
    if (includeId && id != null) {
      data['id'] = id;
    }
    return data;
  }

  OrderModel copyWith({
    String? id,
    String? invoiceNumber,
    String? customerName,
    OrderStatus? status,
    PaymentMethod? paymentMethod,
    double? totalAmount,
    double? payAmount,
    double? changeAmount,
    List<OrderItemModel>? items,
    DateTime? createdAt,
    String? userId,
  }) {
    return OrderModel(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerName: customerName ?? this.customerName,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      totalAmount: totalAmount ?? this.totalAmount,
      payAmount: payAmount ?? this.payAmount,
      changeAmount: changeAmount ?? this.changeAmount,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
    );
  }
}
