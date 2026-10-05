import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../services/supabase_service.dart';

class CatalogState {
  final bool isLoading;
  final List<CategoryModel> categories;
  final String selectedCategoryId;
  final String searchQuery;
  final List<ProductModel> products;
  final String? errorMessage;

  CatalogState({
    this.isLoading = false,
    this.categories = const [],
    this.selectedCategoryId = 'all',
    this.searchQuery = '',
    this.products = const [],
    this.errorMessage,
  });

  List<ProductModel> get filteredProducts {
    return products.where((product) {
      // Category filter
      final matchesCategory = selectedCategoryId == 'all' ||
          selectedCategoryId.isEmpty ||
          product.categoryId == selectedCategoryId;

      // Search filter
      final matchesSearch = searchQuery.isEmpty ||
          product.name.toLowerCase().contains(searchQuery.toLowerCase());

      return matchesCategory && matchesSearch;
    }).toList();
  }

  CatalogState copyWith({
    bool? isLoading,
    List<CategoryModel>? categories,
    String? selectedCategoryId,
    String? searchQuery,
    List<ProductModel>? products,
    String? errorMessage,
  }) {
    return CatalogState(
      isLoading: isLoading ?? this.isLoading,
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      searchQuery: searchQuery ?? this.searchQuery,
      products: products ?? this.products,
      errorMessage: errorMessage,
    );
  }
}

class CatalogNotifier extends StateNotifier<CatalogState> {
  final SupabaseService _service;

  CatalogNotifier(this._service) : super(CatalogState(isLoading: true)) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final categories = await _service.fetchCategories();
      final products = await _service.fetchProducts();
      state = state.copyWith(
        isLoading: false,
        categories: categories,
        products: products,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void selectCategory(String categoryId) {
    state = state.copyWith(selectedCategoryId: categoryId);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> addCategory(String name) async {
    try {
      final created = await _service.addCategory(name);
      state = state.copyWith(
        categories: [...state.categories, created],
      );
    } catch (e) {
      // Offline fallback
      final mock = CategoryModel(id: 'cat_${DateTime.now().millisecondsSinceEpoch}', name: name);
      state = state.copyWith(
        categories: [...state.categories, mock],
      );
    }
  }

  Future<void> addProduct(ProductModel product) async {
    final created = await _service.addProduct(product);
    state = state.copyWith(
      products: [created, ...state.products],
    );
  }

  Future<void> updateProduct(ProductModel product) async {
    final updated = await _service.updateProduct(product);
    final updatedList = state.products.map((p) => p.id == updated.id ? updated : p).toList();
    state = state.copyWith(products: updatedList);
  }

  Future<void> deleteProduct(String productId) async {
    await _service.deleteProduct(productId);
    final updatedList = state.products.where((p) => p.id != productId).toList();
    state = state.copyWith(products: updatedList);
  }

  void reduceStockLocally(Map<String, int> stockReductions) {
    final updatedList = state.products.map((p) {
      if (stockReductions.containsKey(p.id)) {
        final reduction = stockReductions[p.id]!;
        return p.copyWith(stock: (p.stock - reduction).clamp(0, 999999));
      }
      return p;
    }).toList();
    state = state.copyWith(products: updatedList);
  }
}

final catalogProvider = StateNotifierProvider<CatalogNotifier, CatalogState>((ref) {
  return CatalogNotifier(SupabaseService.instance);
});
