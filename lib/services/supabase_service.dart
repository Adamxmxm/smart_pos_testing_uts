import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/supabase_config.dart';
import '../models/category_model.dart';
import '../models/order_item_model.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/user_profile_model.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
  }

  // ================= AUTHENTICATION =================

  /// Sign in with email & password. Throws a user-friendly message on failure.
  Future<UserProfileModel> signIn(String email, String password) async {
    try {
      final res = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = res.user;
      if (user == null) throw Exception('Login gagal. Coba lagi.');

      // Try to fetch profile from DB
      final profileData = await client
          .from(SupabaseConfig.tableProfiles)
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profileData != null) {
        return UserProfileModel.fromJson(profileData);
      }

      // Profile doesn't exist yet, create it
      final newProfile = UserProfileModel(
        id: user.id,
        fullName: user.userMetadata?['full_name'] ??
            (user.email?.split('@').first ?? 'Kasir'),
        email: user.email,
        role: 'cashier',
      );
      await client
          .from(SupabaseConfig.tableProfiles)
          .upsert(newProfile.toJson());
      return newProfile;
    } on AuthException catch (e) {
      // Translate Supabase auth errors to Indonesian
      final msg = _translateAuthError(e.message);
      throw Exception(msg);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Login gagal: $e');
    }
  }

  /// Register new user. Returns profile but does NOT auto-login in provider.
  /// Caller must sign in separately.
  Future<UserProfileModel> signUp(
      String email, String password, String fullName) async {
    try {
      final res = await client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      final user = res.user;
      if (user == null) {
        throw Exception(
            'Pendaftaran gagal. Email mungkin sudah terdaftar atau tidak valid.');
      }

      final profile = UserProfileModel(
        id: user.id,
        fullName: fullName,
        email: email,
        role: 'cashier',
      );

      // If session exists (email confirmation disabled), save profile
      if (res.session != null) {
        try {
          await client
              .from(SupabaseConfig.tableProfiles)
              .upsert(profile.toJson());
        } catch (e) {
          debugPrint('signUp upsert profile error: $e');
        }
      }

      return profile;
    } on AuthException catch (e) {
      throw Exception(_translateAuthError(e.message));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Pendaftaran gagal: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      debugPrint('signOut error: $e');
    }
  }

  User? get currentUser => client.auth.currentSession?.user;

  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  Future<UserProfileModel?> fetchCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;
    try {
      final data = await client
          .from(SupabaseConfig.tableProfiles)
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (data != null) return UserProfileModel.fromJson(data);
    } catch (e) {
      debugPrint('fetchCurrentProfile error: $e');
    }
    // Fallback: build from auth user
    return UserProfileModel(
      id: user.id,
      fullName:
          user.userMetadata?['full_name'] ?? user.email?.split('@').first ?? 'Kasir',
      email: user.email,
      role: 'cashier',
    );
  }

  // ================= CATEGORIES =================

  Future<List<CategoryModel>> fetchCategories() async {
    final res = await client
        .from(SupabaseConfig.tableCategories)
        .select()
        .order('name', ascending: true);
    final list = (res as List).map((e) => CategoryModel.fromJson(e)).toList();
    return [CategoryModel(id: 'all', name: 'Semua'), ...list];
  }

  Future<CategoryModel> addCategory(String name) async {
    final res = await client
        .from(SupabaseConfig.tableCategories)
        .insert({'name': name})
        .select()
        .single();
    return CategoryModel.fromJson(res);
  }

  Future<void> deleteCategory(String id) async {
    await client
        .from(SupabaseConfig.tableCategories)
        .delete()
        .eq('id', id);
  }

  // ================= PRODUCTS =================

  Future<List<ProductModel>> fetchProducts() async {
    final res = await client
        .from(SupabaseConfig.tableProducts)
        .select()
        .order('created_at', ascending: false);
    return (res as List).map((e) => ProductModel.fromJson(e)).toList();
  }

  Future<ProductModel> addProduct(ProductModel product) async {
    final res = await client
        .from(SupabaseConfig.tableProducts)
        .insert(product.toJson())
        .select()
        .single();
    return ProductModel.fromJson(res);
  }

  Future<ProductModel> updateProduct(ProductModel product) async {
    final res = await client
        .from(SupabaseConfig.tableProducts)
        .update(product.toJson())
        .eq('id', product.id)
        .select()
        .single();
    return ProductModel.fromJson(res);
  }

  Future<void> deleteProduct(String id) async {
    await client.from(SupabaseConfig.tableProducts).delete().eq('id', id);
  }

  Future<String?> uploadProductImage(Uint8List imageBytes, String fileName) async {
    try {
      final path =
          'products/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      await client.storage
          .from(SupabaseConfig.bucketProductImages)
          .uploadBinary(
            path,
            imageBytes,
            fileOptions:
                const FileOptions(contentType: 'image/jpeg', upsert: true),
          );
      return client.storage
          .from(SupabaseConfig.bucketProductImages)
          .getPublicUrl(path);
    } catch (e) {
      debugPrint('uploadProductImage error: $e');
      return null;
    }
  }

  // ================= ORDERS & OPEN NOTA =================

  Future<OrderModel> createOrder({
    required String? customerName,
    required OrderStatus status,
    PaymentMethod? paymentMethod,
    required double totalAmount,
    double payAmount = 0,
    double changeAmount = 0,
    required List<OrderItemModel> items,
  }) async {
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final randomSuffix =
        (now.millisecondsSinceEpoch % 100000).toString().padLeft(5, '0');
    final invoiceNumber = 'INV-$dateStr-$randomSuffix';

    final user = currentUser;
    final orderData = {
      'invoice_number': invoiceNumber,
      'customer_name': customerName,
      'status': status.name,
      'payment_method': paymentMethod?.name,
      'total_amount': totalAmount,
      'pay_amount': payAmount,
      'change_amount': changeAmount,
      'user_id': user?.id,
    };

    final orderRes = await client
        .from(SupabaseConfig.tableOrders)
        .insert(orderData)
        .select()
        .single();

    final orderId = orderRes['id'] as String;
    final itemsData = items.map((i) => i.toJson(orderId)).toList();
    await client.from(SupabaseConfig.tableOrderItems).insert(itemsData);

    // Deduct stock if completed immediately
    if (status == OrderStatus.COMPLETED) {
      await _deductStock(items);
    }

    return OrderModel.fromJson(orderRes, items: items);
  }

  Future<void> settleOpenOrder({
    required String orderId,
    required PaymentMethod paymentMethod,
    required double payAmount,
    required double changeAmount,
  }) async {
    await client.from(SupabaseConfig.tableOrders).update({
      'status': OrderStatus.COMPLETED.name,
      'payment_method': paymentMethod.name,
      'pay_amount': payAmount,
      'change_amount': changeAmount,
    }).eq('id', orderId);

    // Deduct stock
    final itemsRes = await client
        .from(SupabaseConfig.tableOrderItems)
        .select('product_id, quantity')
        .eq('order_id', orderId);

    for (final item in (itemsRes as List)) {
      final prodId = item['product_id'] as String?;
      final qty = (item['quantity'] as num?)?.toInt() ?? 0;
      if (prodId != null && qty > 0) {
        final prod = await client
            .from(SupabaseConfig.tableProducts)
            .select('stock')
            .eq('id', prodId)
            .maybeSingle();
        if (prod != null) {
          final currentStock = (prod['stock'] as num?)?.toInt() ?? 0;
          await client.from(SupabaseConfig.tableProducts).update(
              {'stock': (currentStock - qty).clamp(0, 999999)}).eq('id', prodId);
        }
      }
    }
  }

  Future<List<OrderModel>> fetchOpenOrders() async {
    final res = await client
        .from(SupabaseConfig.tableOrders)
        .select('*, order_items(*, products(*))')
        .eq('status', OrderStatus.OPEN.name)
        .order('created_at', ascending: false);
    return (res as List).map((e) => OrderModel.fromJson(e)).toList();
  }

  Future<List<OrderModel>> fetchCompletedOrders(
      {DateTime? start, DateTime? end}) async {
    var query = client
        .from(SupabaseConfig.tableOrders)
        .select('*, order_items(*, products(*))')
        .eq('status', OrderStatus.COMPLETED.name);

    if (start != null) {
      query = query.gte('created_at', start.toIso8601String());
    }
    if (end != null) {
      query = query.lte('created_at', end.toIso8601String());
    }

    final res = await query.order('created_at', ascending: false);
    return (res as List).map((e) => OrderModel.fromJson(e)).toList();
  }

  Future<void> deleteOrder(String orderId) async {
    await client.from(SupabaseConfig.tableOrders).delete().eq('id', orderId);
  }

  // ================= HELPERS =================

  Future<void> _deductStock(List<OrderItemModel> items) async {
    for (final item in items) {
      final prod = await client
          .from(SupabaseConfig.tableProducts)
          .select('stock')
          .eq('id', item.productId)
          .maybeSingle();
      if (prod != null) {
        final currentStock = (prod['stock'] as num?)?.toInt() ?? 0;
        await client.from(SupabaseConfig.tableProducts).update(
            {'stock': (currentStock - item.quantity).clamp(0, 999999)}).eq(
            'id', item.productId);
      }
    }
  }

  String _translateAuthError(String msg) {
    final m = msg.toLowerCase();
    if (m.contains('invalid login credentials') ||
        m.contains('email not found') ||
        m.contains('user not found')) {
      return 'Email atau password salah. Periksa kembali.';
    }
    if (m.contains('email not confirmed')) {
      return 'Email belum dikonfirmasi. Cek kotak masuk email Anda.';
    }
    if (m.contains('user already registered') ||
        m.contains('already been registered')) {
      return 'Email ini sudah terdaftar. Silakan login.';
    }
    if (m.contains('password should be at least')) {
      return 'Password minimal 6 karakter.';
    }
    if (m.contains('unable to validate email address')) {
      return 'Format email tidak valid.';
    }
    if (m.contains('signup is disabled')) {
      return 'Registrasi dinonaktifkan di proyek ini. Hubungi admin.';
    }
    return msg;
  }
}
