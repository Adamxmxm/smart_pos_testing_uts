import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/supabase_config.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/open_nota_provider.dart';
import '../account/account_screen.dart';
import '../products/product_management_screen.dart';
import '../reports/reports_screen.dart';
import '../widgets/mobile_bottom_nav.dart';
import '../widgets/responsive_sidebar.dart';
import '../widgets/smart_pos_logo.dart';
import 'widgets/add_to_cart_dialog.dart';
import 'widgets/cart_bottom_sheet.dart';
import 'widgets/cart_panel.dart';
import 'widgets/category_tabs.dart';
import 'widgets/open_nota_dialog.dart';
import 'widgets/product_card.dart';

class PosMainLayout extends ConsumerStatefulWidget {
  const PosMainLayout({super.key});

  @override
  ConsumerState<PosMainLayout> createState() => _PosMainLayoutState();
}

class _PosMainLayoutState extends ConsumerState<PosMainLayout> {
  int _currentNavIndex = 0;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        if (isMobile) {
          return _buildMobileScaffold();
        } else {
          return _buildTabletWebScaffold(constraints.maxWidth);
        }
      },
    );
  }

  // ================= MOBILE LAYOUT (<600px) =================
  Widget _buildMobileScaffold() {
    final cartState = ref.watch(cartProvider);
    final openNotaState = ref.watch(openNotaProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 14,
        title: const SmartPosLogo(
          iconSize: 26,
          fontSize: 15,
          isDarkBackground: false,
        ),
        actions: [
          // Open Nota Icon Button (with count badge)
          IconButton(
            tooltip: 'Open Nota (${openNotaState.count})',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.receipt_long_rounded, color: AppColors.primaryNavy, size: 22),
                if (openNotaState.count > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.pastelYellowDark,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${openNotaState.count}',
                        style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => const OpenNotaDialog(),
              );
            },
          ),

          // Cart Icon Button (with item count badge)
          IconButton(
            tooltip: 'Keranjang (${cartState.totalItemCount})',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_bag_outlined, color: AppColors.primaryNavy, size: 22),
                if (cartState.totalItemCount > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.accentOrange,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${cartState.totalItemCount}',
                        style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => CartBottomSheet.show(context),
          ),
          const SizedBox(width: 4),

          // Connection status badge
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
              decoration: BoxDecoration(
                color: SupabaseConfig.isConfigured ? AppColors.successLight : AppColors.pastelYellowLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 3.5,
                    backgroundColor: SupabaseConfig.isConfigured ? AppColors.success : AppColors.pastelYellowDark,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    SupabaseConfig.isConfigured ? 'Online' : 'Demo',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: SupabaseConfig.isConfigured ? AppColors.success : AppColors.pastelYellowDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _buildCurrentScreen(isMobile: true),
      bottomNavigationBar: MobileBottomNav(
        currentIndex: _currentNavIndex,
        onTap: (index) => setState(() => _currentNavIndex = index),
      ),
      floatingActionButton: _currentNavIndex == 0 && (cartState.totalItemCount > 0 || openNotaState.count > 0)
          ? Container(
              margin: const EdgeInsets.only(left: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (openNotaState.count > 0 && cartState.isEmpty)
                    FloatingActionButton.extended(
                      heroTag: 'fab_open_nota',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => const OpenNotaDialog(),
                        );
                      },
                      backgroundColor: AppColors.pastelYellowLight,
                      icon: const Icon(Icons.receipt_long_rounded, color: AppColors.primaryNavyDark),
                      label: Text(
                        'Open Nota (${openNotaState.count})',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryNavyDark, fontSize: 12.5),
                      ),
                    ),
                  if (cartState.totalItemCount > 0) ...[
                    const SizedBox(width: 8),
                    FloatingActionButton.extended(
                      heroTag: 'fab_cart',
                      onPressed: () => CartBottomSheet.show(context),
                      backgroundColor: AppColors.accentOrange,
                      icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
                      label: Text(
                        '${cartState.totalItemCount} Item • ${CurrencyFormatter.format(cartState.totalAmount)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ],
                ],
              ),
            )
          : null,
    );
  }

  // ================= TABLET & WEB LAYOUT (>=600px) =================
  Widget _buildTabletWebScaffold(double screenWidth) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Permanent Navy Sidebar on the left
          ResponsiveSidebar(
            selectedIndex: _currentNavIndex,
            onDestinationSelected: (idx) => setState(() => _currentNavIndex = idx),
          ),

          // Main View Area
          Expanded(
            child: _buildCurrentScreen(isMobile: false, screenWidth: screenWidth),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentScreen({required bool isMobile, double screenWidth = 1000}) {
    switch (_currentNavIndex) {
      case 0:
        return _buildPosCatalogAndCart(isMobile: isMobile, screenWidth: screenWidth);
      case 1:
        return const ProductManagementScreen();
      case 2:
        return const ReportsScreen();
      case 3:
        return const AccountScreen();
      default:
        return _buildPosCatalogAndCart(isMobile: isMobile, screenWidth: screenWidth);
    }
  }

  // ================= POS CATALOG & CART VIEW =================
  Widget _buildPosCatalogAndCart({required bool isMobile, double screenWidth = 1000}) {
    final catalogState = ref.watch(catalogProvider);

    final catalogView = Column(
      children: [
        // Topbar Search & Categories
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: AppColors.surface,
          child: Column(
            children: [
              // Search Input & Status (for desktop)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari produk atau menu...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  ref.read(catalogProvider.notifier).setSearchQuery('');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        isDense: true,
                      ),
                      onChanged: (val) {
                        ref.read(catalogProvider.notifier).setSearchQuery(val);
                      },
                    ),
                  ),
                  if (!isMobile) ...[
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: SupabaseConfig.isConfigured ? AppColors.successLight : AppColors.pastelYellowLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 4,
                            backgroundColor:
                                SupabaseConfig.isConfigured ? AppColors.success : AppColors.pastelYellowDark,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            SupabaseConfig.isConfigured ? 'Supabase Terhubung' : 'Demo Mode (Offline)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color:
                                  SupabaseConfig.isConfigured ? AppColors.success : AppColors.pastelYellowDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Category Filter Tabs
              CategoryTabs(
                categories: catalogState.categories,
                selectedCategoryId: catalogState.selectedCategoryId,
                onSelectCategory: (id) => ref.read(catalogProvider.notifier).selectCategory(id),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Product Catalog Grid
        Expanded(
          child: catalogState.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.accentOrange))
              : catalogState.filteredProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.search_off_rounded, size: 52, color: AppColors.textMuted),
                          SizedBox(height: 12),
                          Text(
                            'Tidak ada produk ditemukan',
                            style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isMobile
                            ? 2
                            : (screenWidth > 1200
                                ? 4
                                : (screenWidth > 900 ? 3 : 2)),
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: isMobile ? 0.69 : 0.70,
                      ),
                      itemCount: catalogState.filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = catalogState.filteredProducts[index];
                        return ProductCard(
                          product: product,
                          onAddToCart: () => AddToCartModal.show(context, product: product),
                        );
                      },
                    ),
        ),
      ],
    );

    if (isMobile) {
      return catalogView;
    }

    // Tablet/Desktop Split View (65% Catalog : 35% Cart Panel)
    return Row(
      children: [
        Expanded(
          flex: 65,
          child: catalogView,
        ),
        const Expanded(
          flex: 35,
          child: CartPanel(),
        ),
      ],
    );
  }
}
