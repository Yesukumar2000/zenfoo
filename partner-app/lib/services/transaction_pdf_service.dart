import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import 'package:project/models/transaction_response.dart';

/// Builds a printable PDF report of the seller's transaction records,
/// matching the styling used by [InvoicePdfService].
class TransactionPdfService {
  static const _primaryHex = '#9AC444';
  static const _darkHex = '#111827';
  static const _greyHex = '#6B7280';
  static const _lightGreyHex = '#F3F4F6';

  /// Generate a PDF for [items] (already filtered) and open it.
  static Future<void> generateAndOpenReport({
    required List<TransactionItem> items,
    TransactionSummary? summary,
    String currency = '',
    String rangeLabel = 'Overall',
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final pdf = await _buildPdf(
      items: items,
      summary: summary,
      currency: currency,
      rangeLabel: rangeLabel,
      fromDate: fromDate,
      toDate: toDate,
    );
    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/transactions_$stamp.pdf');
    await file.writeAsBytes(bytes);
    await OpenFile.open(file.path);
  }

  static Future<pw.Document> _buildPdf({
    required List<TransactionItem> items,
    TransactionSummary? summary,
    required String currency,
    required String rangeLabel,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final pdf = pw.Document();

    final primaryColor = PdfColor.fromHex(_primaryHex);
    final darkColor = PdfColor.fromHex(_darkHex);
    final greyColor = PdfColor.fromHex(_greyHex);
    final lightGreyColor = PdfColor.fromHex(_lightGreyHex);

    final generatedOn =
        DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    String periodText = rangeLabel;
    if (fromDate != null || toDate != null) {
      final from =
          fromDate != null ? DateFormat('dd MMM yyyy').format(fromDate) : '…';
      final to =
          toDate != null ? DateFormat('dd MMM yyyy').format(toDate) : '…';
      periodText = '$rangeLabel ($from - $to)';
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => context.pageNumber == 1
            ? pw.SizedBox()
            : pw.Container(
                alignment: pw.Alignment.centerRight,
                margin: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Text(
                  'Transactions Report',
                  style: pw.TextStyle(color: greyColor, fontSize: 9),
                ),
              ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(color: greyColor, fontSize: 9),
          ),
        ),
        build: (context) => [
          // Header band
          pw.Container(
            padding: const pw.EdgeInsets.all(18),
            decoration: pw.BoxDecoration(
              color: primaryColor,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'TRANSACTIONS REPORT',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Period: $periodText',
                      style: const pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      '${items.length} record(s)',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Generated $generatedOn',
                      style: const pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),

          // Summary tiles
          if (summary != null) ...[
            pw.Row(
              children: [
                _summaryTile('Total Earnings', summary.totalEarnings, currency,
                    lightGreyColor, greyColor, darkColor),
                pw.SizedBox(width: 10),
                _summaryTile('Available to Withdraw', summary.adminDueAmount,
                    currency, lightGreyColor, greyColor, darkColor),
                pw.SizedBox(width: 10),
                _summaryTile('Settled / Paid Out', summary.paidAmount, currency,
                    lightGreyColor, greyColor, darkColor),
                pw.SizedBox(width: 10),
                _summaryTile('Pending Payout', summary.pendingAmount, currency,
                    lightGreyColor, greyColor, darkColor),
              ],
            ),
            pw.SizedBox(height: 18),
          ],

          // Table
          _buildTable(items, currency, darkColor, greyColor, lightGreyColor),
          pw.SizedBox(height: 12),

          // Totals row for the listed records
          pw.Container(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Total of listed records: $currency${_sumAmount(items).toStringAsFixed(2)}',
              style: pw.TextStyle(
                color: darkColor,
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    return pdf;
  }

  static pw.Widget _summaryTile(
    String label,
    double? value,
    String currency,
    PdfColor bg,
    PdfColor grey,
    PdfColor dark,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label.toUpperCase(),
              style: pw.TextStyle(
                color: grey,
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
              maxLines: 2,
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              '$currency${(value ?? 0).toStringAsFixed(2)}',
              style: pw.TextStyle(
                color: dark,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildTable(
    List<TransactionItem> items,
    String currency,
    PdfColor dark,
    PdfColor grey,
    PdfColor lightGrey,
  ) {
    pw.Widget cell(String text,
        {pw.TextAlign align = pw.TextAlign.left,
        bool bold = false,
        PdfColor? color}) {
      return pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          color: color ?? dark,
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      );
    }

    final headerStyle = pw.TextStyle(
      color: PdfColors.white,
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
    );

    return pw.Table(
      border: pw.TableBorder.all(color: lightGrey, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.2), // Date
        1: const pw.FlexColumnWidth(2.6), // Description
        2: const pw.FlexColumnWidth(1.0), // Order
        3: const pw.FlexColumnWidth(1.1), // Status
        4: const pw.FlexColumnWidth(1.2), // Commission
        5: const pw.FlexColumnWidth(1.3), // Amount
      },
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: dark),
          children: [
            pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text('Date', style: headerStyle)),
            pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text('Description', style: headerStyle)),
            pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text('Order', style: headerStyle)),
            pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text('Status', style: headerStyle)),
            pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text('Commission',
                    style: headerStyle, textAlign: pw.TextAlign.right)),
            pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text('Amount',
                    style: headerStyle, textAlign: pw.TextAlign.right)),
          ],
        ),
        // Rows
        ...items.asMap().entries.map((entry) {
          final i = entry.key;
          final t = entry.value;
          final isPaid = (t.paymentStatus ?? '').toLowerCase() == 'paid';
          final isCredit = t.isCredit ?? true;
          final amount = t.payableAmount ?? t.amount ?? 0;
          final sign = isCredit ? '+' : '-';
          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: i.isEven ? PdfColors.white : lightGrey,
            ),
            children: [
              pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: cell(_formatDate(t.createdAt))),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    cell(t.typeLabel ?? t.type ?? '-', bold: true),
                    if ((t.itemName ?? '').isNotEmpty)
                      cell(t.itemName!, color: grey),
                  ],
                ),
              ),
              pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: cell(t.orderId != null ? '#${t.orderId}' : '-')),
              pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: cell(isPaid ? 'Paid' : 'Unpaid',
                      color: isPaid
                          ? PdfColor.fromHex('#10B981')
                          : PdfColor.fromHex('#FF9500'))),
              pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: cell(
                      (t.adminCommission ?? 0) > 0
                          ? '$currency${t.adminCommission!.toStringAsFixed(2)}'
                          : '-',
                      align: pw.TextAlign.right)),
              pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: cell(
                      '$sign$currency${amount.abs().toStringAsFixed(2)}',
                      align: pw.TextAlign.right,
                      bold: true,
                      color: isCredit
                          ? PdfColor.fromHex('#10B981')
                          : PdfColor.fromHex('#EF4444'))),
            ],
          );
        }),
      ],
    );
  }

  static double _sumAmount(List<TransactionItem> items) {
    double total = 0;
    for (final t in items) {
      final amount = (t.payableAmount ?? t.amount ?? 0).abs();
      total += (t.isCredit ?? true) ? amount : -amount;
    }
    return total;
  }

  static String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }
}
