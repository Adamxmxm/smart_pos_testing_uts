import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/order_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/print_service.dart';

class ReceiptPreviewDialog extends ConsumerStatefulWidget {
  final OrderModel order;

  const ReceiptPreviewDialog({super.key, required this.order});

  @override
  ConsumerState<ReceiptPreviewDialog> createState() => _ReceiptPreviewDialogState();
}

class _ReceiptPreviewDialogState extends ConsumerState<ReceiptPreviewDialog> {
  bool _is80mm = false;
  bool _isPrinting = false;

  void _triggerPrint() async {
    setState(() => _isPrinting = true);
    try {
      final cashier = ref.read(authProvider).userProfile?.fullName ?? 'Admin POS';
      await PrintService.printReceipt(
        widget.order,
        cashierName: cashier,
        is80mm: _is80mm,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mencetak struk: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cashier = ref.watch(authProvider).userProfile?.fullName ?? 'Admin POS';
    final receiptText = PrintService.generateEscPosReceiptText(widget.order, cashierName: cashier);

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surface,
      insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 680),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.receipt_long_rounded, color: AppColors.accentOrange, size: 24),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Nota Transaksi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryNavy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Roll size selector (58mm vs 80mm)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text('Ukuran Kertas: ', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ChoiceChip(
                    label: const Text('58mm', style: TextStyle(fontSize: 11)),
                    selected: !_is80mm,
                    onSelected: (val) => setState(() => _is80mm = !val),
                    selectedColor: AppColors.accentOrangeLight,
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: const Text('80mm', style: TextStyle(fontSize: 11)),
                    selected: _is80mm,
                    onSelected: (val) => setState(() => _is80mm = val),
                    selectedColor: AppColors.accentOrangeLight,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Receipt Paper View Container
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB), // Warm receipt paper color
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.pastelYellowDark.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      receiptText,
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 12,
                        height: 1.4,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Selesai'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isPrinting ? null : _triggerPrint,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentOrange,
                      ),
                      icon: _isPrinting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.print_rounded, size: 18),
                      label: const Text('Cetak Nota'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
