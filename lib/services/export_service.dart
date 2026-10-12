import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/utils/currency_formatter.dart';
import '../core/utils/date_formatter.dart';
import '../models/order_model.dart';

class ExportService {
  static const String shopName = 'SMART POS - LAPORAN PENJUALAN';
  static const String shopSub = 'Jl. Sudirman No. 123, Jakarta • Telp: 0812-3456-7890';

  /// Export sales report to structured PDF
  static Future<void> exportSalesReportToPdf({
    required List<OrderModel> orders,
    required double totalOmset,
    required int totalTransactions,
    required double avgBasket,
    required String dateRangeLabel,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      shopName,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#0F172A'),
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      shopSub,
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Dicetak: ${DateFormatter.formatDateTime(DateTime.now())}',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                    ),
                    pw.Text(
                      'Periode: $dateRangeLabel',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#F97316'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 1.5, color: PdfColor.fromHex('#0F172A')),
            pw.SizedBox(height: 12),
          ],
        ),
        build: (context) => [
          // KPI Summary Cards in PDF
          pw.Row(
            children: [
              _buildKpiCard('Total Omset', CurrencyFormatter.format(totalOmset), '#0F172A'),
              pw.SizedBox(width: 12),
              _buildKpiCard('Total Transaksi', '$totalTransactions Struk', '#F97316'),
              pw.SizedBox(width: 12),
              _buildKpiCard('Rata-rata Keranjang', CurrencyFormatter.format(avgBasket), '#0F172A'),
            ],
          ),
          pw.SizedBox(height: 20),

          // Transaction Table
          pw.Text(
            'Rincian Transaksi Penjualan',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#0F172A'),
            ),
          ),
          pw.SizedBox(height: 8),

          pw.TableHelper.fromTextArray(
            headers: ['No', 'Invoice', 'Waktu', 'Pelanggan', 'Metode', 'Jml Item', 'Total'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
            headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#0F172A')),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            data: List.generate(orders.length, (index) {
              final o = orders[index];
              final totalItems = o.items.fold<int>(0, (sum, i) => sum + i.quantity);
              return [
                '${index + 1}',
                o.invoiceNumber,
                DateFormatter.formatDateTime(o.createdAt),
                o.customerName ?? '-',
                o.paymentMethod?.name ?? 'TUNAI',
                '$totalItems',
                CurrencyFormatter.format(o.totalAmount),
              ];
            }),
          ),
        ],
      ),
    );

    final pdfBytes = await pdf.save();
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Laporan_Penjualan_${DateFormatter.formatForInvoice(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _buildKpiCard(String title, String value, String colorHex) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          border: pw.Border.all(color: PdfColors.grey300),
          color: PdfColors.grey100,
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex(colorHex),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Export sales report to Microsoft Excel (.xlsx)
  static Future<void> exportSalesReportToExcel({
    required List<OrderModel> orders,
    required double totalOmset,
    required int totalTransactions,
    required double avgBasket,
    required String dateRangeLabel,
  }) async {
    final excel = Excel.createExcel();
    final Sheet sheet = excel['Laporan Penjualan'];
    excel.setDefaultSheet('Laporan Penjualan');

    // Title Row
    sheet.appendRow([
      TextCellValue('SMART POS - LAPORAN REKAP PENJUALAN'),
    ]);
    sheet.appendRow([
      TextCellValue('Periode: $dateRangeLabel'),
      TextCellValue('Tanggal Export: ${DateFormatter.formatDateTime(DateTime.now())}'),
    ]);
    sheet.appendRow([]); // empty row

    // KPI Summary
    sheet.appendRow([
      TextCellValue('Total Omset:'),
      TextCellValue(CurrencyFormatter.format(totalOmset)),
    ]);
    sheet.appendRow([
      TextCellValue('Total Transaksi:'),
      IntCellValue(totalTransactions),
    ]);
    sheet.appendRow([
      TextCellValue('Rata-rata Nilai Keranjang:'),
      TextCellValue(CurrencyFormatter.format(avgBasket)),
    ]);
    sheet.appendRow([]); // empty row

    // Header Table
    sheet.appendRow([
      TextCellValue('No'),
      TextCellValue('No Invoice'),
      TextCellValue('Tanggal & Waktu'),
      TextCellValue('Pelanggan'),
      TextCellValue('Metode Pembayaran'),
      TextCellValue('Jumlah Item'),
      TextCellValue('Total Transaksi (Rp)'),
      TextCellValue('Diterima (Rp)'),
      TextCellValue('Kembali (Rp)'),
    ]);

    // Data rows
    for (int i = 0; i < orders.length; i++) {
      final o = orders[i];
      final totalQty = o.items.fold<int>(0, (sum, item) => sum + item.quantity);
      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(o.invoiceNumber),
        TextCellValue(DateFormatter.formatDateTime(o.createdAt)),
        TextCellValue(o.customerName ?? '-'),
        TextCellValue(o.paymentMethod?.name ?? 'TUNAI'),
        IntCellValue(totalQty),
        DoubleCellValue(o.totalAmount),
        DoubleCellValue(o.payAmount),
        DoubleCellValue(o.changeAmount),
      ]);
    }

    final fileBytes = excel.encode();
    if (fileBytes != null) {
      await FileSaver.instance.saveFile(
        name: 'Laporan_Penjualan_${DateFormatter.formatForInvoice(DateTime.now())}.xlsx',
        bytes: Uint8List.fromList(fileBytes),
        ext: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );
    }
  }
}
