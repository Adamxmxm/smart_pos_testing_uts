import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/order_model.dart';
import '../../providers/report_provider.dart';
import '../../services/export_service.dart';
import '../pos/widgets/receipt_preview_dialog.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  bool _isExportingPdf = false;
  bool _isExportingExcel = false;

  void _exportPdf(ReportState state) async {
    if (state.completedOrders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data transaksi untuk diekspor.')),
      );
      return;
    }

    setState(() => _isExportingPdf = true);
    try {
      await ExportService.exportSalesReportToPdf(
        orders: state.completedOrders,
        totalOmset: state.totalOmset,
        totalTransactions: state.totalTransactions,
        avgBasket: state.avgBasket,
        dateRangeLabel: state.dateRangeLabel,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal export PDF: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

  void _exportExcel(ReportState state) async {
    if (state.completedOrders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data transaksi untuk diekspor.')),
      );
      return;
    }

    setState(() => _isExportingExcel = true);
    try {
      await ExportService.exportSalesReportToExcel(
        orders: state.completedOrders,
        totalOmset: state.totalOmset,
        totalTransactions: state.totalTransactions,
        avgBasket: state.avgBasket,
        dateRangeLabel: state.dateRangeLabel,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Laporan Excel (.xlsx) berhasil diunduh!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal export Excel: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isExportingExcel = false);
    }
  }

  void _selectCustomDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now(),
      ),
    );

    if (range != null) {
      ref.read(reportProvider.notifier).setFilter(
            ReportDateFilter.custom,
            customStart: range.start,
            customEnd: range.end,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isMobile ? 'Laporan Penjualan' : 'Laporan & Analitik Penjualan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 16 : 18),
        ),
        actions: [
          if (isMobile) ...[
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: PopupMenuButton<String>(
                tooltip: 'Export Laporan',
                onSelected: (val) {
                  if (val == 'pdf') _exportPdf(reportState);
                  if (val == 'excel') _exportExcel(reportState);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isExportingPdf || _isExportingExcel)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      else ...[
                        const Icon(Icons.file_download_outlined, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        const Text(
                          'Export',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ],
                  ),
                ),
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'pdf',
                    enabled: !_isExportingPdf,
                    child: Row(
                      children: const [
                        Icon(Icons.picture_as_pdf_rounded, color: AppColors.error, size: 18),
                        SizedBox(width: 8),
                        Text('Export PDF (.pdf)', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'excel',
                    enabled: !_isExportingExcel,
                    child: Row(
                      children: const [
                        Icon(Icons.table_view_rounded, color: AppColors.success, size: 18),
                        SizedBox(width: 8),
                        Text('Export Excel (.xlsx)', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Export PDF Button
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: OutlinedButton.icon(
                onPressed: _isExportingPdf ? null : () => _exportPdf(reportState),
                icon: _isExportingPdf
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.picture_as_pdf_rounded, size: 18, color: AppColors.error),
                label: const Text('Export PDF'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
            ),
            // Export Excel Button
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ElevatedButton.icon(
                onPressed: _isExportingExcel ? null : () => _exportExcel(reportState),
                icon: _isExportingExcel
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.table_view_rounded, size: 18),
                label: const Text('Export Excel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildDateFilterChip('Hari Ini', ReportDateFilter.today, reportState.filter),
                  const SizedBox(width: 8),
                  _buildDateFilterChip('Minggu Ini', ReportDateFilter.thisWeek, reportState.filter),
                  const SizedBox(width: 8),
                  _buildDateFilterChip('Bulan Ini', ReportDateFilter.thisMonth, reportState.filter),
                  const SizedBox(width: 8),
                  _buildDateFilterChip('Semua Waktu', ReportDateFilter.allTime, reportState.filter),
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: const Icon(Icons.date_range_rounded, size: 16, color: AppColors.primaryNavy),
                    label: Text(reportState.filter == ReportDateFilter.custom ? reportState.dateRangeLabel : 'Kustom Tanggal'),
                    backgroundColor: reportState.filter == ReportDateFilter.custom ? AppColors.pastelYellow : AppColors.surface,
                    side: const BorderSide(color: AppColors.border),
                    onPressed: _selectCustomDateRange,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3 Summary KPI Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 650;
                final cards = [
                  _buildKpiCard(
                    title: 'Total Omset Penjualan',
                    value: CurrencyFormatter.format(reportState.totalOmset),
                    subtitle: 'Periode ${reportState.dateRangeLabel}',
                    icon: Icons.monetization_on_rounded,
                    color: AppColors.primaryNavy,
                    iconBg: AppColors.primaryNavyLight,
                  ),
                  _buildKpiCard(
                    title: 'Total Transaksi',
                    value: '${reportState.totalTransactions} Struk',
                    subtitle: 'Transaksi Selesai (Completed)',
                    icon: Icons.receipt_long_rounded,
                    color: AppColors.accentOrange,
                    iconBg: AppColors.accentOrangeLight,
                  ),
                  _buildKpiCard(
                    title: 'Rata-rata Keranjang (AOV)',
                    value: CurrencyFormatter.format(reportState.avgBasket),
                    subtitle: 'Nilai per transaksi pelanggan',
                    icon: Icons.shopping_basket_rounded,
                    color: AppColors.primaryNavy,
                    iconBg: AppColors.pastelYellowLight,
                  ),
                ];

                if (isNarrow) {
                  return Column(
                    children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: c)).toList(),
                  );
                }

                return Row(
                  children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: c))).toList(),
                );
              },
            ),

            const SizedBox(height: 24),

            // Transaction History Table
            const Text(
              'Riwayat Transaksi Penjualan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 10),

            reportState.completedOrders.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: const [
                          Icon(Icons.receipt_outlined, size: 48, color: AppColors.textMuted),
                          SizedBox(height: 10),
                          Text('Belum ada transaksi pada periode ini', style: TextStyle(color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: reportState.completedOrders.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final order = reportState.completedOrders[index];
                        final totalQty = order.items.fold<int>(0, (sum, i) => sum + i.quantity);

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: order.paymentMethod == PaymentMethod.TUNAI
                                ? AppColors.surfaceMuted
                                : AppColors.accentOrangeLight,
                            child: Icon(
                              order.paymentMethod == PaymentMethod.TUNAI
                                  ? Icons.payments_rounded
                                  : Icons.qr_code_2_rounded,
                              color: order.paymentMethod == PaymentMethod.TUNAI
                                  ? AppColors.primaryNavy
                                  : AppColors.accentOrangeDark,
                              size: 18,
                            ),
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  order.invoiceNumber,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppColors.successLight,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'COMPLETED',
                                  style: TextStyle(
                                    color: AppColors.success,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '${order.customerName ?? 'Pelanggan'} • $totalQty item • ${DateFormatter.formatDateTime(order.createdAt)}',
                              style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    CurrencyFormatter.format(order.totalAmount),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppColors.primaryNavy,
                                    ),
                                  ),
                                  Text(
                                    order.paymentMethod?.name ?? 'TUNAI',
                                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.print_outlined, size: 18, color: AppColors.primaryNavy),
                                tooltip: 'Cetak Struk Ulang',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => ReceiptPreviewDialog(order: order),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilterChip(String label, ReportDateFilter filterValue, ReportDateFilter currentFilter) {
    final isSelected = filterValue == currentFilter;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          ref.read(reportProvider.notifier).setFilter(filterValue);
        }
      },
      selectedColor: AppColors.primaryNavy,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textDark,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 12.5,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primaryNavy : AppColors.border,
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color iconBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms);
  }
}
