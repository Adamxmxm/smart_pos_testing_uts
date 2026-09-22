/// Configuration constants for Supabase integration.
/// Replace placeholder values with your actual project credentials from Supabase Dashboard.
class SupabaseConfig {
  static const String supabaseUrl = 'https://ojcvwsufnljeiyofpqns.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9qY3Z3c3VmbmxqZWl5b2ZwcW5zIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk5ODM2MjAsImV4cCI6MjEwNTU1OTYyMH0.hgkBB0EL-HfIVAb1Vj-Zcmx7qGIx3_VUU3gqDrH6zRw';

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
