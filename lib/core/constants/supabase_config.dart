/// Configuration constants for Supabase integration.
/// Replace placeholder values with your actual project credentials from Supabase Dashboard.
class SupabaseConfig {
  static const String supabaseUrl = 'https://YOUR_SUPABASE_PROJECT_URL.supabase.co';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  // Table Names conforming to PRD schema
  static const String tableProfiles = 'profiles';
  static const String tableCategories = 'categories';
  static const String tableProducts = 'products';
  static const String tableOrders = 'orders';
  static const String tableOrderItems = 'order_items';

  // Storage Bucket
  static const String bucketProductImages = 'product-images';

  /// Returns true if valid custom credentials have been supplied
  static bool get isConfigured {
    return supabaseUrl.startsWith('https://') &&
        !supabaseUrl.contains('YOUR_SUPABASE_PROJECT_URL') &&
        supabaseAnonKey.length > 20 &&
        !supabaseAnonKey.contains('YOUR_SUPABASE_ANON_KEY');
  }
}
