import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_item_model.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';

class CartState {
  final List<OrderItemModel> items;
  final String? customerName;
  final String? activeOpenOrderId; // Non-null if currently editing an Open Nota
  final String? activeInvoiceNumber;

  CartState({
    this.items = const [],
    this.customerName,
    this.activeOpenOrderId,
    this.activeInvoiceNumber,
  });

  int get totalItemCount => items.fold<int>(0, (sum, item) => sum + item.quantity);

  double get totalAmount => items.fold<double>(0.0, (sum, item) => sum + item.subtotal);

  bool get isEmpty => items.isEmpty;

  CartState copyWith({
    List<OrderItemModel>? items,
    String? customerName,
    String? activeOpenOrderId,
    String? activeInvoiceNumber,
    bool clearActiveOpenOrder = false,
  }) {
    return CartState(
      items: items ?? this.items,
      customerName: customerName ?? this.customerName,
      activeOpenOrderId: clearActiveOpenOrder ? null : (activeOpenOrderId ?? this.activeOpenOrderId),
      activeInvoiceNumber: clearActiveOpenOrder ? null : (activeInvoiceNumber ?? this.activeInvoiceNumber),
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState());

  void setCustomerName(String? name) {
    state = state.copyWith(customerName: name);
  }

  void addToCart(ProductModel product) {
    addOrUpdateItemWithQuantity(product, 1);
  }

  void addOrUpdateItemWithQuantity(ProductModel product, int quantity, {String? notes}) {
    if (product.stock <= 0 || quantity <= 0) return;
    final effectiveQty = quantity > product.stock ? product.stock : quantity;

    final existingIndex = state.items.indexWhere((i) => i.productId == product.id);
    if (existingIndex != -1) {
      final current = state.items[existingIndex];
      final newQty = (current.quantity + effectiveQty).clamp(1, product.stock);
      final updated = current.copyWith(
        quantity: newQty,
        notes: (notes != null && notes.isNotEmpty) ? notes : current.notes,
      );
      final list = List<OrderItemModel>.from(state.items);
      list[existingIndex] = updated;
      state = state.copyWith(items: list);
    } else {
      final newItem = OrderItemModel(
        productId: product.id,
        productName: product.name,
        quantity: effectiveQty,
        unitPrice: product.price,
        subtotal: product.price * effectiveQty,
        imageUrl: product.imageUrl,
        notes: notes,
      );
      state = state.copyWith(items: [...state.items, newItem]);
    }
  }

  void updateItemNotes(String productId, String? notes) {
    final idx = state.items.indexWhere((i) => i.productId == productId);
    if (idx != -1) {
      final current = state.items[idx];
      final updated = current.copyWith(notes: notes);
      final list = List<OrderItemModel>.from(state.items);
      list[idx] = updated;
      state = state.copyWith(items: list);
    }
  }

  void setItemQuantity(String productId, int quantity, {int maxStock = 999999}) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    final idx = state.items.indexWhere((i) => i.productId == productId);
    if (idx != -1) {
      final targetQty = quantity.clamp(1, maxStock);
      final current = state.items[idx];
      final updated = current.copyWith(quantity: targetQty);
      final list = List<OrderItemModel>.from(state.items);
      list[idx] = updated;
      state = state.copyWith(items: list);
    }
  }

  void incrementQuantity(String productId, {int maxStock = 999999}) {
    final idx = state.items.indexWhere((i) => i.productId == productId);
    if (idx != -1) {
      final current = state.items[idx];
      if (current.quantity >= maxStock) return;

      final updated = current.copyWith(quantity: current.quantity + 1);
      final list = List<OrderItemModel>.from(state.items);
      list[idx] = updated;
      state = state.copyWith(items: list);
    }
  }

  void decrementQuantity(String productId) {
    final idx = state.items.indexWhere((i) => i.productId == productId);
    if (idx != -1) {
      final current = state.items[idx];
      if (current.quantity > 1) {
        final updated = current.copyWith(quantity: current.quantity - 1);
        final list = List<OrderItemModel>.from(state.items);
        list[idx] = updated;
        state = state.copyWith(items: list);
      } else {
        removeItem(productId);
      }
    }
  }

  void removeItem(String productId) {
    final list = state.items.where((i) => i.productId != productId).toList();
    state = state.copyWith(items: list);
  }

  void restoreOrder(OrderModel order) {
    state = CartState(
      items: List.from(order.items),
      customerName: order.customerName,
      activeOpenOrderId: order.id,
      activeInvoiceNumber: order.invoiceNumber,
    );
  }

  void clearCart() {
    state = CartState();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
