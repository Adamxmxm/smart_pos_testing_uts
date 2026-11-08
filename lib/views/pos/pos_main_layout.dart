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
          Semantics(
            identifier: 'btn_open_nota_appbar',
            child: IconButton(
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
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_currentNavIndex == 0) _buildMobileCartBar(cartState, openNotaState),
          MobileBottomNav(
            currentIndex: _currentNavIndex,
            onTap: (index) => setState(() => _currentNavIndex = index),
          ),
        ],
      ),
    );
  }

  // ================= BAR KERANJANG (mobile, di atas bottom nav) =================
  Widget _buildMobileCartBar(dynamic cartState, dynamic openNotaState) {
    final hasCart = cartState.totalItemCount > 0;
    final hasOpenNota = openNotaState.count > 0;

    Widget? bar;

    if (hasCart) {
      bar = Semantics(
        identifier: 'btn_buka_keranjang',
        child: Material(
          key: const ValueKey('cart_bar'),
          color: Colors.transparent,
          child: InkWell(
            onTap: () => CartBottomSheet.show(context),
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accentOrange, AppColors.accentOrangeDark],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentOrange.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Ikon keranjang + badge jumlah item
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 22),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: TweenAnimationBuilder<double>(
                          key: ValueKey(cartState.totalItemCount),
                          tween: Tween(begin: 1.5, end: 1.0),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.elasticOut,
                          builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${cartState.totalItemCount}',
                              style: const TextStyle(
                                color: AppColors.accentOrangeDark,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Lihat Keranjang',
                          style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Ketuk untuk bayar atau simpan nota',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(anim),
                        child: child,
                      ),
                    ),
                    child: Text(
                      CurrencyFormatter.format(cartState.totalAmount),
                      key: ValueKey(cartState.totalAmount),
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white, size: 24),
                ],
              ),
            ),
          ),
        ),
      );
    } else if (hasOpenNota) {
      bar = Semantics(
        identifier: 'btn_buka_open_nota_bar',
        child: Material(
          key: const ValueKey('nota_bar'),
          color: Colors.transparent,
          child: InkWell(
            onTap: () => showDialog(
              context: context,
              builder: (ctx) => const OpenNotaDialog(),
            ),
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.pastelYellowLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.pastelYellowDark, width: 1.2),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_rounded, color: AppColors.primaryNavyDark),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${openNotaState.count} Open Nota menunggu pembayaran',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryNavyDark,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.primaryNavyDark),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      alignment: Alignment.bottomCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(anim),
            child: child,
          ),
        ),
        child: bar == null
            ? const SizedBox(key: ValueKey('no_bar'), width: double.infinity)
            : Container(
                key: ValueKey(hasCart ? 'wrap_cart' : 'wrap_nota'),
                width: double.infinity,
                color: AppColors.background,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: bar,
              ),
      ),
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
