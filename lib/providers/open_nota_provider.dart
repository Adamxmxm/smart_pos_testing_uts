import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_item_model.dart';
import '../models/order_model.dart';
import '../services/supabase_service.dart';

class OpenNotaState {
  final bool isLoading;
  final List<OrderModel> openOrders;
  final String? errorMessage;

  OpenNotaState({
    this.isLoading = false,
    this.openOrders = const [],
    this.errorMessage,
  });

  int get count => openOrders.length;

  OpenNotaState copyWith({
    bool? isLoading,
    List<OrderModel>? openOrders,
    String? errorMessage,
  }) {
    return OpenNotaState(
      isLoading: isLoading ?? this.isLoading,
      openOrders: openOrders ?? this.openOrders,
      errorMessage: errorMessage,
    );
  }
}

class OpenNotaNotifier extends StateNotifier<OpenNotaState> {
  final SupabaseService _service;

  OpenNotaNotifier(this._service) : super(OpenNotaState(isLoading: true)) {
    loadOpenOrders();
  }

  Future<void> loadOpenOrders() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final orders = await _service.fetchOpenOrders();
      state = state.copyWith(isLoading: false, openOrders: orders);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<OrderModel> saveCurrentBill({
    required String? customerName,
    required List<OrderItemModel> items,
    required double totalAmount,
    String? existingOrderId,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      if (existingOrderId != null) {
        // If already existing, remove the previous record first or update it
        await _service.deleteOrder(existingOrderId);
      }

      final created = await _service.createOrder(
        customerName: customerName ?? 'Pelanggan Walk-in',
        status: OrderStatus.OPEN,
        totalAmount: totalAmount,
        items: items,
      );

      final updatedList = [created, ...state.openOrders.where((o) => o.id != existingOrderId)];
      state = state.copyWith(isLoading: false, openOrders: updatedList);
      return created;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> removeOpenOrder(String orderId) async {
    try {
      await _service.deleteOrder(orderId);
      final updatedList = state.openOrders.where((o) => o.id != orderId).toList();
      state = state.copyWith(openOrders: updatedList);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
}

final openNotaProvider = StateNotifierProvider<OpenNotaNotifier, OpenNotaState>((ref) {
  return OpenNotaNotifier(SupabaseService.instance);
});
