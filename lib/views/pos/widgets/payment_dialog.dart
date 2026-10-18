import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/order_item_model.dart';
import '../../../models/order_model.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/catalog_provider.dart';
import '../../../providers/open_nota_provider.dart';
import '../../../providers/report_provider.dart';
import '../../../services/supabase_service.dart';
import 'receipt_preview_dialog.dart';

class PaymentDialog extends ConsumerStatefulWidget {
  final double totalAmount;
  final String? customerName;
  final List<OrderItemModel> items;
  final String? existingOrderId;

  const PaymentDialog({
    super.key,
    required this.totalAmount,
    this.customerName,
    required this.items,
    this.existingOrderId,
  });

  @override
  ConsumerState<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<PaymentDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _cashController = TextEditingController();
  final _refNumberController = TextEditingController();
  double _cashGiven = 0;
  String _selectedNonCashMethod = 'QRIS';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cashGiven = widget.totalAmount;
    _cashController.text = CurrencyFormatter.formatWithoutSymbol(widget.totalAmount);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cashController.dispose();
    _refNumberController.dispose();
    super.dispose();
  }

  bool _isFirstCashInput = true;

  void _setCash(double amount) {
    setState(() {
      _cashGiven = amount;
      _cashController.text = CurrencyFormatter.formatWithoutSymbol(amount);
    });
  }

  void _onCashNumpadDigit(String digit) {
    final currentStr = _cashGiven.toInt().toString();
    String newStr;
    if (_isFirstCashInput || currentStr == '0') {
      newStr = digit;
      _isFirstCashInput = false;
    } else {
      if (currentStr.length >= 9) return;
      newStr = '$currentStr$digit';
    }
    final val = double.tryParse(newStr) ?? 0;
    _setCash(val);
  }

  void _onCashNumpadBackspace() {
    final currentStr = _cashGiven.toInt().toString();
    if (currentStr.length <= 1) {
      _setCash(0);
      _isFirstCashInput = true;
    } else {
      final newStr = currentStr.substring(0, currentStr.length - 1);
      final val = double.tryParse(newStr) ?? 0;
      _setCash(val);
    }
  }

  void _onCashNumpadClear() {
    _setCash(0);
    _isFirstCashInput = true;
  }

  void _processPayment(PaymentMethod method) async {
    if (method == PaymentMethod.TUNAI && _cashGiven < widget.totalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nominal uang tunai kurang dari total tagihan!'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final payAmount = method == PaymentMethod.TUNAI ? _cashGiven : widget.totalAmount;
      final changeAmount = method == PaymentMethod.TUNAI ? (_cashGiven - widget.totalAmount) : 0.0;

      OrderModel completedOrder;

      if (widget.existingOrderId != null) {
        await SupabaseService.instance.settleOpenOrder(
          orderId: widget.existingOrderId!,
          paymentMethod: method,
          payAmount: payAmount,
          changeAmount: changeAmount,
        );
        ref.read(openNotaProvider.notifier).loadOpenOrders();

        completedOrder = OrderModel(
          id: widget.existingOrderId,
          invoiceNumber: ref.read(cartProvider).activeInvoiceNumber ?? 'INV-${DateTime.now().millisecondsSinceEpoch}',
          customerName: widget.customerName,
          status: OrderStatus.COMPLETED,
          paymentMethod: method,
          totalAmount: widget.totalAmount,
          payAmount: payAmount,
          changeAmount: changeAmount,
          items: widget.items,
          createdAt: DateTime.now(),
        );
      } else {
        completedOrder = await SupabaseService.instance.createOrder(
          customerName: widget.customerName,
          status: OrderStatus.COMPLETED,
          paymentMethod: method,
          totalAmount: widget.totalAmount,
          payAmount: payAmount,
          changeAmount: changeAmount,
          items: widget.items,
        );
      }

      // Update local catalog stock
      final stockReductions = <String, int>{};
      for (final item in widget.items) {
        stockReductions[item.productId] = item.quantity;
      }
      ref.read(catalogProvider.notifier).reduceStockLocally(stockReductions);

      // Record in reports provider
      ref.read(reportProvider.notifier).onOrderCompleted(completedOrder);

      // Clear the active cart
      ref.read(cartProvider.notifier).clearCart();

      if (mounted) {
        Navigator.pop(context); // Close payment dialog

        // Show receipt preview & print dialog
        showDialog(
          context: context,
          builder: (ctx) => ReceiptPreviewDialog(order: completedOrder),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final change = _cashGiven - widget.totalAmount;

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surface,
      insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 18 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Proses Pembayaran',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Total to Pay Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryNavy,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Tagihan',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                        if (widget.customerName != null && widget.customerName!.isNotEmpty)
                          Text(
                            widget.customerName!,
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                      ],
                    ),
                    Text(
                      CurrencyFormatter.format(widget.totalAmount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Payment Method Tabs
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppColors.accentOrange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textMuted,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  tabs: const [
                    Tab(icon: Icon(Icons.payments_rounded, size: 18), text: 'Tunai (Cash)'),
                    Tab(icon: Icon(Icons.qr_code_scanner_rounded, size: 18), text: 'Non-Tunai'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tab Views
              SizedBox(
                height: 440,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // ================= TUNAI =================
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Cash Input Field
                          TextFormField(
                            controller: _cashController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                            decoration: InputDecoration(
                              labelText: 'Uang Diterima (Rp)',
                              prefixText: 'Rp ',
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: _onCashNumpadClear,
                              ),
                            ),
                            onChanged: (val) {
                              final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
                              setState(() {
                                _cashGiven = double.tryParse(clean) ?? 0;
                                _isFirstCashInput = false;
                              });
                            },
                          ),
                          const SizedBox(height: 10),

                          // Quick Cash Preset Chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildQuickCashButton('Uang Pas', () => _setCash(widget.totalAmount)),
                                const SizedBox(width: 6),
                                _buildQuickCashButton('Rp 10k', () => _setCash(10000)),
                                const SizedBox(width: 6),
                                _buildQuickCashButton('Rp 20k', () => _setCash(20000)),
                                const SizedBox(width: 6),
                                _buildQuickCashButton('Rp 50k', () => _setCash(50000)),
                                const SizedBox(width: 6),
                                _buildQuickCashButton('Rp 100k', () => _setCash(100000)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Change / Shortage Preview Box
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: change >= 0 ? AppColors.successLight : AppColors.errorLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  change >= 0 ? 'Kembalian:' : 'Uang Kurang:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: change >= 0 ? AppColors.success : AppColors.error,
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.format(change.abs()),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: change >= 0 ? AppColors.success : AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Interactive On-Screen Numpad Grid
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    _buildCashNumpadButton('1', () => _onCashNumpadDigit('1')),
                                    const SizedBox(width: 6),
                                    _buildCashNumpadButton('2', () => _onCashNumpadDigit('2')),
                                    const SizedBox(width: 6),
                                    _buildCashNumpadButton('3', () => _onCashNumpadDigit('3')),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    _buildCashNumpadButton('4', () => _onCashNumpadDigit('4')),
                                    const SizedBox(width: 6),
                                    _buildCashNumpadButton('5', () => _onCashNumpadDigit('5')),
                                    const SizedBox(width: 6),
                                    _buildCashNumpadButton('6', () => _onCashNumpadDigit('6')),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    _buildCashNumpadButton('7', () => _onCashNumpadDigit('7')),
                                    const SizedBox(width: 6),
                                    _buildCashNumpadButton('8', () => _onCashNumpadDigit('8')),
                                    const SizedBox(width: 6),
                                    _buildCashNumpadButton('9', () => _onCashNumpadDigit('9')),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    _buildCashNumpadButton(
                                      'C',
                                      _onCashNumpadClear,
                                      bgColor: AppColors.errorLight,
                                      textColor: AppColors.error,
                                    ),
                                    const SizedBox(width: 6),
                                    _buildCashNumpadButton('0', () => _onCashNumpadDigit('0')),
                                    const SizedBox(width: 6),
                                    _buildCashNumpadButton('000', () => _onCashNumpadDigit('000')),
                                    const SizedBox(width: 6),
                                    _buildCashNumpadButton(
                                      '⌫',
                                      _onCashNumpadBackspace,
                                      bgColor: AppColors.surface,
                                      textColor: AppColors.primaryNavy,
                                      icon: Icons.backspace_outlined,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Submit Cash Button
                          ElevatedButton(
                            onPressed: (_isProcessing || change < 0) ? null : () => _processPayment(PaymentMethod.TUNAI),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryNavy,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isProcessing
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Selesaikan Pembayaran Tunai', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),

                    // ================= NON TUNAI =================
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Sub-options: QRIS, Transfer, EDC
                        Row(
                          children: ['QRIS', 'Transfer Bank', 'Mesin EDC'].map((method) {
                            final isSel = _selectedNonCashMethod == method;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 3),
                                child: InkWell(
                                  onTap: () => setState(() => _selectedNonCashMethod = method),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSel ? AppColors.accentOrangeLight : AppColors.surfaceMuted,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSel ? AppColors.accentOrange : AppColors.border,
                                        width: 1.2,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      method,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                        color: isSel ? AppColors.accentOrangeDark : AppColors.textDark,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),

                        // QRIS / EDC Banner Info
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _selectedNonCashMethod == 'QRIS'
                                    ? Icons.qr_code_2_rounded
                                    : (_selectedNonCashMethod == 'Mesin EDC' ? Icons.credit_card_rounded : Icons.account_balance_rounded),
                                color: AppColors.accentOrange,
                                size: 36,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedNonCashMethod == 'QRIS'
                                      ? 'Arahkan pelanggan scan QRIS Statis/Dinamis toko.'
                                      : (_selectedNonCashMethod == 'Mesin EDC'
                                          ? 'Gesek/Tap kartu Debit/Kredit pada mesin EDC.'
                                          : 'Konfirmasi bukti transfer ke rekening operasional toko.'),
                                  style: const TextStyle(fontSize: 11.5, color: AppColors.textDark),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Reference Number Input
                        TextFormField(
                          controller: _refNumberController,
                          decoration: const InputDecoration(
                            labelText: 'Nomor Referensi / Approval Code (Opsional)',
                            prefixIcon: Icon(Icons.tag_rounded, size: 18),
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                        ),
                        const Spacer(),

                        // Submit Non-Cash
                        ElevatedButton(
                          onPressed: _isProcessing ? null : () => _processPayment(PaymentMethod.NON_TUNAI),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentOrange,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _isProcessing
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text('Konfirmasi Bayar ($_selectedNonCashMethod)'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickCashButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildCashNumpadButton(
    String label,
    VoidCallback onTap, {
    Color? bgColor,
    Color? textColor,
    IconData? icon,
  }) {
    return Expanded(
      child: Material(
        color: bgColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
            ),
            child: icon != null
                ? Icon(icon, size: 18, color: textColor ?? AppColors.textDark)
                : Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor ?? AppColors.textDark,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
