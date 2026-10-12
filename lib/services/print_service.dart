import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/utils/currency_formatter.dart';
import '../core/utils/date_formatter.dart';
import '../models/order_model.dart';

class PrintService {
  static const String shopName = 'SMART POS APP';
  static const String shopAddress = 'Jl. Sudirman No. 123, Jakarta';
  static const String shopPhone = 'Telp: 0812-3456-7890';

  /// Generates the raw text ESC/POS formatted receipt matching PRD exactly
  static String generateEscPosReceiptText(OrderModel order, {String cashierName = 'Admin POS'}) {
    final buffer = StringBuffer();
    final sepDouble = '=' * 38;
    final sepSingle = '-' * 38;

    buffer.writeln(sepDouble);
    buffer.writeln(_centerText(shopName, 38));
    buffer.writeln(_centerText(shopAddress, 38));
    buffer.writeln(sepDouble);
    buffer.writeln('Invoice : ${order.invoiceNumber}');
    buffer.writeln('Kasir   : $cashierName');
    buffer.writeln('Tanggal : ${DateFormatter.formatDateTime(order.createdAt)}');
    if (order.customerName != null && order.customerName!.isNotEmpty) {
      buffer.writeln('Plggn   : ${order.customerName}');
    }
    buffer.writeln(sepSingle);

    for (final item in order.items) {
      final line1 = '${item.quantity}x ${item.productName}';
      final priceUnit = '@${CurrencyFormatter.formatWithoutSymbol(item.unitPrice)}';
      final subtotal = CurrencyFormatter.formatWithoutSymbol(item.subtotal);
      
      // Calculate spacing
      final itemDetails = '$priceUnit  $subtotal';
      if (line1.length + itemDetails.length + 1 <= 38) {
        final spaces = ' ' * (38 - line1.length - itemDetails.length);
        buffer.writeln('$line1$spaces$itemDetails');
      } else {
        buffer.writeln(line1);
        final spaces = ' ' * (38 - itemDetails.length);
        buffer.writeln('$spaces$itemDetails');
      }
      if (item.notes != null && item.notes!.isNotEmpty) {
        buffer.writeln('  * ${item.notes}');
      }
    }

    buffer.writeln(sepSingle);
    buffer.writeln(_formatKeyValue('Total', CurrencyFormatter.formatWithoutSymbol(order.totalAmount), 38));
    
    final methodLabel = order.paymentMethod?.name ?? 'TUNAI';
    buffer.writeln(_formatKeyValue('Bayar ($methodLabel)', CurrencyFormatter.formatWithoutSymbol(order.payAmount), 38));
    buffer.writeln(_formatKeyValue('Kembali', CurrencyFormatter.formatWithoutSymbol(order.changeAmount), 38));
    buffer.writeln(sepDouble);
    buffer.writeln(_centerText('Terima Kasih Atas', 38));
    buffer.writeln(_centerText('Kunjungan Anda!', 38));
    buffer.writeln(sepDouble);

    return buffer.toString();
  }

  /// Builds a PDF document configured for 58mm / 80mm thermal receipt roll
  static Future<Uint8List> generateReceiptPdf(OrderModel order, {String cashierName = 'Admin POS', bool is80mm = false}) async {
    final pdf = pw.Document();
    final rollWidth = is80mm ? 72 * PdfPageFormat.mm : 58 * PdfPageFormat.mm;
    final pageFormat = PdfPageFormat(rollWidth, double.infinity, marginAll: 4 * PdfPageFormat.mm);

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          return pw.Container(
            width: double.infinity,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  shopName,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  shopAddress,
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 1),
                pw.Text(
                  shopPhone,
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 4),
                pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
                pw.SizedBox(height: 2),

                // Order metadata
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Invoice :', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(order.invoiceNumber, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Kasir :', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(cashierName, style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Tanggal :', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(DateFormatter.formatDateTime(order.createdAt), style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
                if (order.customerName != null && order.customerName!.isNotEmpty)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Pelanggan :', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(order.customerName!, style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),

                pw.SizedBox(height: 4),
                pw.Divider(thickness: 0.8, borderStyle: pw.BorderStyle.dotted),
                pw.SizedBox(height: 2),

                // Order Items
                ...order.items.map((item) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          item.productName,
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              '${item.quantity}x @${CurrencyFormatter.formatWithoutSymbol(item.unitPrice)}',
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                            pw.Text(
                              CurrencyFormatter.formatWithoutSymbol(item.subtotal),
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                          ],
                        ),
                        if (item.notes != null && item.notes!.isNotEmpty)
                          pw.Text(
                            '  * ${item.notes}',
                            style: pw.TextStyle(fontSize: 7.5, fontStyle: pw.FontStyle.italic),
                          ),
                      ],
                    ),
                  );
                }),

                pw.SizedBox(height: 4),
                pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
                pw.SizedBox(height: 3),

                // Totals
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text(CurrencyFormatter.format(order.totalAmount), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Bayar (${order.paymentMethod?.name ?? 'TUNAI'})', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(CurrencyFormatter.format(order.payAmount), style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Kembali', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(CurrencyFormatter.format(order.changeAmount), style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),

                pw.SizedBox(height: 6),
                pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
                pw.SizedBox(height: 4),

                pw.Text('Terima Kasih Atas', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center),
                pw.Text('Kunjungan Anda!', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                pw.SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Direct trigger print dialog via printing package
  static Future<void> printReceipt(OrderModel order, {String cashierName = 'Admin POS', bool is80mm = false}) async {
    final pdfBytes = await generateReceiptPdf(order, cashierName: cashierName, is80mm: is80mm);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Struk_${order.invoiceNumber}',
    );
  }

  static String _centerText(String text, int width) {
    if (text.length >= width) return text;
    final pad = (width - text.length) ~/ 2;
    return ' ' * pad + text;
  }

  static String _formatKeyValue(String key, String value, int width) {
    final totalPad = width - key.length - value.length - 3;
    final dots = totalPad > 0 ? ' ' * totalPad : ' ';
    return '$key :$dots$value';
  }
}
