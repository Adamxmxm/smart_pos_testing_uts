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

  /// Metode yang dipilih dari keranjang. Dialog langsung menampilkan
  /// form sesuai metode ini (tanpa tab pilihan lagi).
  final PaymentMethod initialMethod;

  const PaymentDialog({
    super.key,
    required this.totalAmount,
    this.customerName,
    required this.items,
    this.existingOrderId,
    this.initialMethod = PaymentMethod.TUNAI,
  });

  @override
  ConsumerState<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<PaymentDialog> {
  final _cashController = TextEditingController();
  final _refNumberController = TextEditingController();
  double _cashGiven = 0;
  String _selectedNonCashMethod = 'QRIS';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _cashGiven = widget.totalAmount;
    _cashController.text = CurrencyFormatter.formatWithoutSymbol(widget.totalAmount);
  }

  @override
  void dispose() {
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
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isCash = widget.initialMethod == PaymentMethod.TUNAI;
    final accent = isCash ? AppColors.primaryNavy : AppColors.accentOrange;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      backgroundColor: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(accent, isCash),
              Padding(
                padding: EdgeInsets.fromLTRB(isMobile ? 16 : 20, 16, isMobile ? 16 : 20, isMobile ? 16 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: isCash ? _buildCashContent() : _buildNonCashContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= HEADER (judul metode + total tagihan) =================
  Widget _buildHeader(Color accent, bool isCash) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 8, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, accent.withValues(alpha: 0.82)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCash ? Icons.payments_rounded : Icons.qr_code_scanner_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Proses Pembayaran',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11.5),
                    ),
                    Text(
                      isCash ? 'Tunai (Cash)' : 'Non-Tunai',
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Semantics(
                identifier: 'btn_tutup_pembayaran',
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22, color: Colors.white),
                  onPressed: _isProcessing ? null : () => Navigator.pop(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Tagihan',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                    ),
                    if (widget.customerName != null && widget.customerName!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person_outline_rounded, size: 13, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text(
                              widget.customerName!,
                              style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                Text(
                  CurrencyFormatter.format(widget.totalAmount),
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= TUNAI =================
  List<Widget> _buildCashContent() {
    final change = _cashGiven - widget.totalAmount;
    final enough = change >= 0;

    return [
      Semantics(
        identifier: 'input_uang_diterima',
        child: TextFormField(
          controller: _cashController,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
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
      ),
      const SizedBox(height: 12),

      // Preset nominal cepat
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildQuickCashButton('Uang Pas', () => _setCash(widget.totalAmount), id: 'chip_uang_pas', highlight: true),
          _buildQuickCashButton('Rp 10k', () => _setCash(10000), id: 'chip_rp_10k'),
          _buildQuickCashButton('Rp 20k', () => _setCash(20000), id: 'chip_rp_20k'),
          _buildQuickCashButton('Rp 50k', () => _setCash(50000), id: 'chip_rp_50k'),
          _buildQuickCashButton('Rp 100k', () => _setCash(100000), id: 'chip_rp_100k'),
        ],
      ),
      const SizedBox(height: 14),

      // Kembalian / Uang kurang (animasi saat berubah)
      AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: enough ? AppColors.successLight : AppColors.errorLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: (enough ? AppColors.success : AppColors.error).withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  enough ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                  size: 18,
                  color: enough ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 8),
                Text(
                  enough ? 'Kembalian:' : 'Uang Kurang:',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: enough ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
            Text(
              CurrencyFormatter.format(change.abs()),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: enough ? AppColors.success : AppColors.error,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // Numpad interaktif
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            _numpadRow([
              _buildCashNumpadButton('1', () => _onCashNumpadDigit('1')),
              _buildCashNumpadButton('2', () => _onCashNumpadDigit('2')),
              _buildCashNumpadButton('3', () => _onCashNumpadDigit('3')),
            ]),
            const SizedBox(height: 6),
            _numpadRow([
              _buildCashNumpadButton('4', () => _onCashNumpadDigit('4')),
              _buildCashNumpadButton('5', () => _onCashNumpadDigit('5')),
              _buildCashNumpadButton('6', () => _onCashNumpadDigit('6')),
            ]),
            const SizedBox(height: 6),
            _numpadRow([
              _buildCashNumpadButton('7', () => _onCashNumpadDigit('7')),
              _buildCashNumpadButton('8', () => _onCashNumpadDigit('8')),
              _buildCashNumpadButton('9', () => _onCashNumpadDigit('9')),
            ]),
            const SizedBox(height: 6),
            _numpadRow([
              _buildCashNumpadButton(
                'C',
                _onCashNumpadClear,
                bgColor: AppColors.errorLight,
                textColor: AppColors.error,
              ),
              _buildCashNumpadButton('0', () => _onCashNumpadDigit('0')),
              _buildCashNumpadButton('000', () => _onCashNumpadDigit('000')),
              _buildCashNumpadButton(
                '⌫',
                _onCashNumpadBackspace,
                bgColor: AppColors.surface,
                textColor: AppColors.primaryNavy,
                icon: Icons.backspace_outlined,
              ),
            ]),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // Tombol selesai
      Semantics(
        identifier: 'btn_selesaikan_tunai',
        child: ElevatedButton.icon(
          onPressed: (_isProcessing || change < 0) ? null : () => _processPayment(PaymentMethod.TUNAI),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryNavy,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: _isProcessing
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.check_circle_outline_rounded, size: 20),
          label: const Text('Selesaikan Pembayaran Tunai', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    ];
  }

  Widget _numpadRow(List<Widget> buttons) {
    final children = <Widget>[];
    for (var i = 0; i < buttons.length; i++) {
      if (i > 0) children.add(const SizedBox(width: 6));
      children.add(buttons[i]);
    }
    return Row(children: children);
  }

  // ================= NON TUNAI =================
  List<Widget> _buildNonCashContent() {
    const methods = [
      {'name': 'QRIS', 'id': 'chip_qris', 'icon': Icons.qr_code_2_rounded},
      {'name': 'Transfer Bank', 'id': 'chip_transfer_bank', 'icon': Icons.account_balance_rounded},
      {'name': 'Mesin EDC', 'id': 'chip_mesin_edc', 'icon': Icons.credit_card_rounded},
    ];

    return [
      const Text(
        'Pilih Metode',
        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textMuted),
      ),
      const SizedBox(height: 8),
      Row(
        children: methods.map((m) {
          final name = m['name'] as String;
          final isSel = _selectedNonCashMethod == name;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Semantics(
                identifier: m['id'] as String,
                child: InkWell(
                  onTap: () => setState(() => _selectedNonCashMethod = name),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.accentOrangeLight : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSel ? AppColors.accentOrange : AppColors.border,
                        width: isSel ? 1.6 : 1.0,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          m['icon'] as IconData,
                          size: 22,
                          color: isSel ? AppColors.accentOrange : AppColors.textMuted,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                            color: isSel ? AppColors.accentOrangeDark : AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 14),

      // Petunjuk sesuai metode
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: Container(
          key: ValueKey(_selectedNonCashMethod),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.accentOrangeLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.accentOrange.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(
                _selectedNonCashMethod == 'QRIS'
                    ? Icons.qr_code_2_rounded
                    : (_selectedNonCashMethod == 'Mesin EDC' ? Icons.credit_card_rounded : Icons.account_balance_rounded),
                color: AppColors.accentOrange,
                size: 38,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedNonCashMethod == 'QRIS'
                      ? 'Arahkan pelanggan scan QRIS Statis/Dinamis toko.'
                      : (_selectedNonCashMethod == 'Mesin EDC'
                          ? 'Gesek/Tap kartu Debit/Kredit pada mesin EDC.'
                          : 'Konfirmasi bukti transfer ke rekening operasional toko.'),
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textDark, height: 1.35),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),

      Semantics(
        identifier: 'input_referensi',
        child: TextFormField(
          controller: _refNumberController,
          decoration: const InputDecoration(
            labelText: 'Nomor Referensi / Approval Code (Opsional)',
            prefixIcon: Icon(Icons.tag_rounded, size: 18),
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ),
      const SizedBox(height: 18),

      Semantics(
        identifier: 'btn_konfirmasi_nontunai',
        child: ElevatedButton.icon(
          onPressed: _isProcessing ? null : () => _processPayment(PaymentMethod.NON_TUNAI),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentOrange,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: _isProcessing
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.check_circle_outline_rounded, size: 20),
          label: Text(
            'Konfirmasi Bayar ($_selectedNonCashMethod)',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    ];
  }

  Widget _buildQuickCashButton(String label, VoidCallback onTap, {String? id, bool highlight = false}) {
    final chip = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: highlight ? AppColors.primaryNavy : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: highlight ? AppColors.primaryNavy : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: highlight ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
    );
    return id == null ? chip : Semantics(identifier: id, child: chip);
  }

  Widget _buildCashNumpadButton(
    String label,
    VoidCallback onTap, {
    Color? bgColor,
    Color? textColor,
    IconData? icon,
  }) {
    final numpadId = icon != null
        ? 'numpad_backspace'
        : (label == 'C' ? 'numpad_clear' : 'numpad_$label');
    return Expanded(
      child: Semantics(
        identifier: numpadId,
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
      ),
    );
  }
}
