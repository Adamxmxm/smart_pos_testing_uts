import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/order_model.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/catalog_provider.dart';
import '../../../providers/open_nota_provider.dart';
import 'open_nota_dialog.dart';
import 'payment_dialog.dart';
import 'add_to_cart_dialog.dart';

class CartPanel extends ConsumerStatefulWidget {
  final bool isBottomSheet;

  const CartPanel({super.key, this.isBottomSheet = false});

  @override
  ConsumerState<CartPanel> createState() => _CartPanelState();
}

class _CartPanelState extends ConsumerState<CartPanel> {
  final _customerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final currentCustomer = ref.read(cartProvider).customerName;
    if (currentCustomer != null) {
      _customerController.text = currentCustomer;
    }
  }

  @override
  void dispose() {
    _customerController.dispose();
    super.dispose();
  }

  void _saveToOpenNota() async {
    final cartState = ref.read(cartProvider);
    if (cartState.isEmpty) return;

    final customer = _customerController.text.trim().isEmpty
        ? 'Pelanggan Meja ${DateTime.now().minute}'
        : _customerController.text.trim();

    try {
      await ref.read(openNotaProvider.notifier).saveCurrentBill(
            customerName: customer,
            items: cartState.items,
            totalAmount: cartState.totalAmount,
            existingOrderId: cartState.activeOpenOrderId,
          );

      ref.read(cartProvider.notifier).clearCart();
      _customerController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tagihan berhasil disimpan ke Open Nota!'),
            backgroundColor: AppColors.primaryNavy,
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (widget.isBottomSheet) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan Open Nota: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _openPaymentModal(PaymentMethod method) {
    final cartState = ref.read(cartProvider);
    if (cartState.isEmpty) return;

    final customer = _customerController.text.trim().isEmpty
        ? 'Pelanggan Walk-in'
        : _customerController.text.trim();

    ref.read(cartProvider.notifier).setCustomerName(customer);

    showDialog(
      context: context,
      builder: (ctx) => PaymentDialog(
        totalAmount: cartState.totalAmount,
        customerName: customer,
        items: cartState.items,
        existingOrderId: cartState.activeOpenOrderId,
        initialMethod: method,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final openState = ref.watch(openNotaProvider);
    final catalogState = ref.watch(catalogProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: widget.isBottomSheet
            ? null
            : const Border(
                left: BorderSide(color: AppColors.border, width: 1.5),
              ),
      ),
      child: Column(
        children: [
          // Header Keranjang & Tombol Open Nota
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shopping_bag_outlined, color: AppColors.primaryNavy, size: 20),
                      const SizedBox(width: 6),
                      const Flexible(
                        child: Text(
                          'Keranjang',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryNavy,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accentOrangeLight,
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
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Button Daftar Open Nota (with count badge)
                InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => const OpenNotaDialog(),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.pastelYellowLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.pastelYellowDark.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.receipt_long_rounded, size: 15, color: AppColors.primaryNavyDark),
                        const SizedBox(width: 4),
                        const Text(
                          'Open Nota',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryNavyDark,
                          ),
                        ),
                        if (openState.count > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.accentOrange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${openState.count}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Active Open Order indicator banner
          if (cartState.activeOpenOrderId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.pastelYellowLight,
              child: Row(
                children: [
                  const Icon(Icons.edit_note_rounded, color: AppColors.pastelYellowDark, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Memuat Nota: ${cartState.activeInvoiceNumber ?? ''}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryNavyDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () => ref.read(cartProvider.notifier).clearCart(),
                    child: const Icon(Icons.close_rounded, size: 16, color: AppColors.primaryNavyDark),
                  ),
                ],
              ),
            ),

          // Input Nama Pelanggan / Nomor Meja
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Semantics(
              identifier: 'input_nama_pelanggan',
              child: TextField(
              controller: _customerController,
              decoration: const InputDecoration(
                hintText: 'Nama Pelanggan / No. Meja (Opsional)',
                prefixIcon: Icon(Icons.person_outline, size: 18),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
              onChanged: (val) {
                ref.read(cartProvider.notifier).setCustomerName(val.trim());
              },
            ),
            ),
          ),

          // Daftar Item Keranjang
          Expanded(
            child: cartState.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.remove_shopping_cart_outlined, size: 48, color: AppColors.textMuted),
                        SizedBox(height: 12),
                        Text(
                          'Keranjang belanja kosong',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Pilih produk dari katalog untuk memesan',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: cartState.items.length,
                    separatorBuilder: (context, index) => const Divider(height: 16),
                    itemBuilder: (context, index) {
                      final item = cartState.items[index];
                      // Find product to get stock
                      final prod = catalogState.products.cast<dynamic>().firstWhere(
                            (p) => p.id == item.productId,
                            orElse: () => null,
                          );
                      final stock = prod?.stock ?? 999999;

                      return Row(
                        children: [
                          // Item Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (item.notes != null && item.notes!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Note: ${item.notes!}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.accentOrangeDark,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 2),
                                Text(
                                  CurrencyFormatter.format(item.unitPrice),
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),

                          // Quantity Controls
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Semantics(
                                identifier: 'btn_qty_kurang_$index',
                                child: InkWell(
                                onTap: () => ref.read(cartProvider.notifier).decrementQuantity(item.productId),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceMuted,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: const Icon(Icons.remove_rounded, size: 16, color: AppColors.textDark),
                                ),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  if (prod != null) {
                                    AddToCartModal.show(context, product: prod);
                                  }
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  child: Text(
                                    '${item.quantity}',
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryNavy,
                                    ),
                                  ),
                                ),
                              ),
                              Semantics(
                                identifier: 'btn_qty_tambah_$index',
                                child: InkWell(
                                onTap: () => ref.read(cartProvider.notifier).incrementQuantity(item.productId, maxStock: stock),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceMuted,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: const Icon(Icons.add_rounded, size: 16, color: AppColors.textDark),
                                ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(width: 10),

                          // Subtotal
                          SizedBox(
                            width: 75,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                CurrencyFormatter.format(item.subtotal),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),

          // Total & Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Tagihan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(cartState.totalAmount),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Open Nota Button (Yellow highlight)
                SizedBox(
                  width: double.infinity,
                  child: Semantics(
                    identifier: 'btn_simpan_tagihan',
                    child: OutlinedButton.icon(
                    onPressed: cartState.isEmpty ? null : _saveToOpenNota,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.pastelYellowLight,
                      side: const BorderSide(color: AppColors.pastelYellowDark, width: 1.2),
                      foregroundColor: AppColors.primaryNavyDark,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.save_as_rounded, size: 18, color: AppColors.primaryNavyDark),
                    label: const Text(
                      'Simpan Tagihan (Open Nota)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ),
                ),

                const SizedBox(height: 8),

                // Payment Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        identifier: 'btn_bayar_tunai',
                        child: ElevatedButton.icon(
                        onPressed: cartState.isEmpty ? null : () => _openPaymentModal(PaymentMethod.TUNAI),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryNavy,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.payments_rounded, size: 18),
                        label: const Text('Bayar Tunai'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Semantics(
                        identifier: 'btn_non_tunai',
                        child: ElevatedButton.icon(
                        onPressed: cartState.isEmpty ? null : () => _openPaymentModal(PaymentMethod.NON_TUNAI),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentOrange,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.qr_code_rounded, size: 18),
                        label: const Text('Non-Tunai'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
