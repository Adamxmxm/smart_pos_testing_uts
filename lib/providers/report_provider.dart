import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';
import '../services/supabase_service.dart';

enum ReportDateFilter { today, thisWeek, thisMonth, allTime, custom }

class ReportState {
  final bool isLoading;
  final ReportDateFilter filter;
  final DateTime? customStart;
  final DateTime? customEnd;
  final List<OrderModel> completedOrders;
  final String? errorMessage;

  ReportState({
    this.isLoading = false,
    this.filter = ReportDateFilter.today,
    this.customStart,
    this.customEnd,
    this.completedOrders = const [],
    this.errorMessage,
  });

  double get totalOmset => completedOrders.fold<double>(0.0, (sum, o) => sum + o.totalAmount);

  int get totalTransactions => completedOrders.length;

  double get avgBasket => totalTransactions == 0 ? 0.0 : totalOmset / totalTransactions;

  String get dateRangeLabel {
    switch (filter) {
      case ReportDateFilter.today:
        return 'Hari Ini';
      case ReportDateFilter.thisWeek:
        return 'Minggu Ini';
      case ReportDateFilter.thisMonth:
        return 'Bulan Ini';
      case ReportDateFilter.allTime:
        return 'Semua Waktu';
      case ReportDateFilter.custom:
        return 'Kustom (${customStart?.day}/${customStart?.month} - ${customEnd?.day}/${customEnd?.month})';
    }
  }

  ReportState copyWith({
    bool? isLoading,
    ReportDateFilter? filter,
    DateTime? customStart,
    DateTime? customEnd,
    List<OrderModel>? completedOrders,
    String? errorMessage,
  }) {
    return ReportState(
      isLoading: isLoading ?? this.isLoading,
      filter: filter ?? this.filter,
      customStart: customStart ?? this.customStart,
      customEnd: customEnd ?? this.customEnd,
      completedOrders: completedOrders ?? this.completedOrders,
      errorMessage: errorMessage,
    );
  }
}

class ReportNotifier extends StateNotifier<ReportState> {
  final SupabaseService _service;

  ReportNotifier(this._service) : super(ReportState(isLoading: true)) {
    loadReports();
  }

  Future<void> loadReports() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final (start, end) = _calculateDateRange(state.filter, state.customStart, state.customEnd);
      final orders = await _service.fetchCompletedOrders(start: start, end: end);
      state = state.copyWith(isLoading: false, completedOrders: orders);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setFilter(ReportDateFilter filter, {DateTime? customStart, DateTime? customEnd}) {
    state = state.copyWith(
      filter: filter,
      customStart: customStart,
      customEnd: customEnd,
    );
    loadReports();
  }

  void onOrderCompleted(OrderModel order) {
    state = state.copyWith(
      completedOrders: [order, ...state.completedOrders],
    );
  }

  (DateTime?, DateTime?) _calculateDateRange(
    ReportDateFilter filter,
    DateTime? customStart,
    DateTime? customEnd,
  ) {
    final now = DateTime.now();
    switch (filter) {
      case ReportDateFilter.today:
        final start = DateTime(now.year, now.month, now.day, 0, 0, 0);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return (start, end);
      case ReportDateFilter.thisWeek:
        final start = now.subtract(Duration(days: now.weekday - 1));
        return (DateTime(start.year, start.month, start.day), DateTime(now.year, now.month, now.day, 23, 59, 59));
      case ReportDateFilter.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return (start, end);
      case ReportDateFilter.allTime:
        return (null, null);
      case ReportDateFilter.custom:
        return (customStart, customEnd);
    }
  }
}

final reportProvider = StateNotifierProvider<ReportNotifier, ReportState>((ref) {
  return ReportNotifier(SupabaseService.instance);
});
