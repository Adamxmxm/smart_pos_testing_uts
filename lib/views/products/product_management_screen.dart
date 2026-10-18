import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/product_model.dart';
import '../../providers/catalog_provider.dart';
import 'product_form_dialog.dart';

class ProductManagementScreen extends ConsumerStatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  ConsumerState<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends ConsumerState<ProductManagementScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddProductDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const ProductFormDialog(),
    );
  }

  void _openEditProductDialog(ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => ProductFormDialog(productToEdit: product),
    );
  }

  void _confirmDelete(ProductModel product) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Hapus Produk',
      transitionDuration: const Duration(milliseconds: 250),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.2),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut)),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
      pageBuilder: (ctx, anim1, anim2) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
              SizedBox(width: 8),
              Text('Hapus Produk?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text('Apakah Anda yakin ingin menghapus produk "${product.name}"?'),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(catalogProvider.notifier).deleteProduct(product.id);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Produk "${product.name}" telah dihapus.'),
                    backgroundColor: AppColors.primaryNavy,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(catalogProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isMobile ? 'Produk & Stok' : 'Manajemen Produk & Stok',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 16 : 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: _openAddProductDialog,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(isMobile ? 'Tambah' : 'Tambah Produk'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentOrange,
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 16, vertical: 8),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter & Search Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.surface,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari produk berdasarkan nama...',
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
                const SizedBox(width: 12),
                Text(
                  '${catalogState.filteredProducts.length} Produk',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Product List with Skeletonizer
          Expanded(
            child: Skeletonizer(
              enabled: catalogState.isLoading,
              child: catalogState.filteredProducts.isEmpty && !catalogState.isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 52, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          const Text('Belum ada produk di katalog', style: TextStyle(color: AppColors.textMuted)),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _openAddProductDialog,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Tambah Produk Pertama'),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: catalogState.isLoading ? 6 : catalogState.filteredProducts.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final product = catalogState.isLoading
                            ? ProductModel(
                                id: 'mock',
                                name: 'Nama Produk Mockup',
                                price: 25000,
                                stock: 20,
                              )
                            : catalogState.filteredProducts[index];

                        final isOutOfStock = product.stock <= 0;
                        final isLowStock = product.stock > 0 && product.stock <= 5;

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              // Product Thumbnail
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  color: AppColors.surfaceMuted,
                                  child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                                      ? Image.network(
                                          product.imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (ctx, err, st) =>
                                              const Icon(Icons.fastfood_rounded, color: AppColors.textMuted),
                                        )
                                      : const Icon(Icons.fastfood_rounded, color: AppColors.textMuted),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Product Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        Text(
                                          CurrencyFormatter.format(product.price),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.accentOrange,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isOutOfStock
                                                ? AppColors.errorLight
                                                : (isLowStock ? AppColors.accentOrangeLight : AppColors.surfaceMuted),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            isOutOfStock ? 'Stok Habis' : 'Stok: ${product.stock}',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                              color: isOutOfStock
                                                  ? AppColors.error
                                                  : (isLowStock ? AppColors.accentOrangeDark : AppColors.textDark),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Actions
                              if (!catalogState.isLoading) ...[
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 19, color: AppColors.textDark),
                                  tooltip: 'Edit Produk',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  onPressed: () => _openEditProductDialog(product),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 19, color: AppColors.error),
                                  tooltip: 'Hapus Produk',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  onPressed: () => _confirmDelete(product),
                                ),
                              ],
                            ],
                          ),
                        ).animate().fadeIn(duration: 200.ms);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
