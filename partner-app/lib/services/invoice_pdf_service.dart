import 'dart:io';
import 'package:project/utils/order_number.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:project/models/invoice_model.dart';
import 'package:project/models/new_order.dart';
import 'package:intl/intl.dart';

class InvoicePdfService {
  static Future<void> generateAndShareInvoice(
    BuildContext context,
    InvoiceData invoice, {
    List<SettlementItem>? settlementInfo,
  }) async {
    final pdf = await _generatePdf(invoice, settlementInfo: settlementInfo);
    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/invoice_${invoice.orderInfo.orderNumber}.pdf');
    await file.writeAsBytes(bytes);
    await OpenFile.open(file.path);
  }

  static Future<void> generateAndPrintInvoice(
    BuildContext context,
    InvoiceData invoice,
  ) async {
    final pdf = await _generateReceiptPdf(invoice);

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  /// Generate thermal receipt style PDF (80mm width)
  static Future<pw.Document> _generateReceiptPdf(InvoiceData invoice) async {
    final pdf = pw.Document();

    // 80mm thermal paper width (approximately 226 points)
    const receiptWidth = 226.0;

    // Format date
    String formattedDate = '';
    try {
      final dateTime = DateTime.parse(invoice.orderInfo.orderDate);
      formattedDate = DateFormat('dd/MM/yy hh:mm a').format(dateTime);
    } catch (e) {
      formattedDate = invoice.orderInfo.orderDate;
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(receiptWidth, double.infinity),
        margin: const pw.EdgeInsets.all(8),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // Store Name
            pw.Text(
              invoice.store.storeName.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              invoice.store.address,
              style: const pw.TextStyle(fontSize: 8),
              textAlign: pw.TextAlign.center,
              maxLines: 2,
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              'Ph: ${invoice.store.sellerMobile}',
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.SizedBox(height: 6),

            // Dashed line
            _buildDashedLine(receiptWidth - 16),
            pw.SizedBox(height: 4),

            // Order Info (center aligned)
            pw.Text('Order ${formatOrderNumber(invoice.orderInfo.orderId)}',
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 2),
            pw.Text(formattedDate,
                style: const pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 2),
            pw.Text('Pay: ${invoice.orderInfo.paymentMethod}',
                style: const pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 4),

            // Dashed line
            _buildDashedLine(receiptWidth - 16),
            pw.SizedBox(height: 4),

            // Customer Info (center aligned, 60% width)
            pw.Container(
              width: (receiptWidth - 16) * 0.6, // 60% width
              alignment: pw.Alignment.center,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('Customer: ${invoice.customer.name}',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                      textAlign: pw.TextAlign.center),
                  pw.Text('Ph: ${invoice.customer.mobile}',
                      style: const pw.TextStyle(fontSize: 8),
                      textAlign: pw.TextAlign.center),
                  if (invoice.customer.address.isNotEmpty)
                    pw.Text(invoice.customer.address,
                        style: const pw.TextStyle(fontSize: 8),
                        maxLines: 2,
                        textAlign: pw.TextAlign.center),
                ],
              ),
            ),
            pw.SizedBox(height: 4),

            // Order Note (if available)
            if (invoice.notes.orderNote.isNotEmpty) ...[
              _buildDashedLine(receiptWidth - 16),
              pw.SizedBox(height: 4),
              pw.Text('Order Note:',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center),
              pw.SizedBox(height: 2),
              pw.Container(
                width: receiptWidth - 16,
                child: pw.Text(
                  invoice.notes.orderNote,
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                  maxLines: 4,
                ),
              ),
              pw.SizedBox(height: 4),
            ],

            // Dashed line
            _buildDashedLine(receiptWidth - 16),
            pw.SizedBox(height: 4),

            // Items Header
            pw.Row(
              children: [
                pw.Expanded(
                  flex: 5,
                  child: pw.Text('ITEM',
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text('QTY',
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                      textAlign: pw.TextAlign.center),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text('AMT',
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                      textAlign: pw.TextAlign.right),
                ),
              ],
            ),
            pw.SizedBox(height: 4),

            // Items
            ...invoice.items.map((item) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 5,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(item.productName,
                            style: const pw.TextStyle(fontSize: 9)),
                        if (item.variantName.isNotEmpty)
                          pw.Text(item.variantName,
                              style: const pw.TextStyle(fontSize: 7)),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text('${item.quantity}',
                        style: const pw.TextStyle(fontSize: 9),
                        textAlign: pw.TextAlign.center),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text('Rs. ${item.subTotal.toStringAsFixed(2)}',
                        style: const pw.TextStyle(fontSize: 9),
                        textAlign: pw.TextAlign.right),
                  ),
                ],
              ),
            )),
            pw.SizedBox(height: 4),

            // Dashed line
            _buildDashedLine(receiptWidth - 16),
            pw.SizedBox(height: 4),

            // Totals
            ...invoice.pricing.lineItems.map((item) {
              if (item.value is num) {
                return _buildReceiptTotalRow(item.label, (item.value as num).toDouble());
              }
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 1),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(item.label, style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('${item.value}', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              );
            }),
            pw.SizedBox(height: 4),

            // Dashed line
            _buildDashedLine(receiptWidth - 16),
            pw.SizedBox(height: 6),

            // Footer
            pw.Text(
              invoice.footer.message,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              invoice.footer.tagline,
              style: const pw.TextStyle(fontSize: 8),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 6),

            // App name
            pw.Text(
              '--- ${invoice.store.appName} ---',
              style: const pw.TextStyle(fontSize: 8),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 10),
          ],
        ),
      ),
    );

    return pdf;
  }

  static pw.Widget _buildDashedLine(double width) {
    return pw.Text(
      '-' * (width ~/ 4),
      style: const pw.TextStyle(fontSize: 8),
    );
  }

  static pw.Widget _buildReceiptTotalRow(String label, double amount) {
    final isNegative = amount < 0;
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
          pw.Text(
            '${isNegative ? "-" : ""}Rs. ${amount.abs().toStringAsFixed(2)}',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
  }

  static Future<File> generateAndSaveInvoice(
    InvoiceData invoice,
  ) async {
    final pdf = await _generatePdf(invoice);
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/invoice_${invoice.orderInfo.orderNumber}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<pw.Document> _generatePdf(InvoiceData invoice, {List<SettlementItem>? settlementInfo}) async {
    final pdf = pw.Document();

    // Define colors
    final primaryColor = PdfColor.fromHex('#9AC444');
    final darkColor = PdfColor.fromHex('#111827');
    final greyColor = PdfColor.fromHex('#6B7280');
    final lightGreyColor = PdfColor.fromHex('#F3F4F6');

    // Format date
    String formattedDate = '';
    try {
      final dateTime = DateTime.parse(invoice.orderInfo.orderDate);
      formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
    } catch (e) {
      formattedDate = invoice.orderInfo.orderDate;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: primaryColor,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      invoice.store.appName,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'TAX INVOICE',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Order ${formatOrderNumber(invoice.orderInfo.orderId)}',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      formattedDate,
                      style: const pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // Store & Customer Info Row
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Store Info
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: lightGreyColor,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'FROM',
                        style: pw.TextStyle(
                          color: greyColor,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        invoice.store.storeName,
                        style: pw.TextStyle(
                          color: darkColor,
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        invoice.store.sellerName,
                        style: pw.TextStyle(
                          color: greyColor,
                          fontSize: 11,
                        ),
                      ),
                      pw.Text(
                        invoice.store.sellerMobile,
                        style: pw.TextStyle(
                          color: greyColor,
                          fontSize: 11,
                        ),
                      ),
                      pw.Text(
                        invoice.store.sellerEmail,
                        style: pw.TextStyle(
                          color: greyColor,
                          fontSize: 11,
                        ),
                      ),
                      if (invoice.store.address.isNotEmpty && invoice.store.address != 'N/A')
                        pw.Text(
                          invoice.store.address,
                          style: pw.TextStyle(
                            color: greyColor,
                            fontSize: 11,
                          ),
                        ),
                      if (invoice.store.panNumber.isNotEmpty && invoice.store.panNumber != 'N/A')
                        pw.Text(
                          'PAN: ${invoice.store.panNumber}',
                          style: pw.TextStyle(
                            color: greyColor,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 16),
              // Customer Info
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: lightGreyColor,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'BILL TO',
                        style: pw.TextStyle(
                          color: greyColor,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        invoice.customer.name,
                        style: pw.TextStyle(
                          color: darkColor,
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        invoice.customer.mobile,
                        style: pw.TextStyle(
                          color: greyColor,
                          fontSize: 11,
                        ),
                      ),
                      pw.Text(
                        invoice.customer.email,
                        style: pw.TextStyle(
                          color: greyColor,
                          fontSize: 11,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        invoice.customer.address,
                        style: pw.TextStyle(
                          color: greyColor,
                          fontSize: 10,
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 24),

          // Order Info
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: lightGreyColor, width: 1),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoColumn('Status', invoice.orderInfo.orderStatus),
                _buildInfoColumn('Payment', invoice.orderInfo.paymentMethod),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // Items Table Header
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: pw.BoxDecoration(
              color: darkColor,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(8),
                topRight: pw.Radius.circular(8),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 4,
                  child: pw.Text(
                    'Item',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    'Qty',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    'Price',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.Expanded(
                  flex: 2,  
                  child: pw.Text(
                    'Total',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
          ),

          // Items Table Body
          ...invoice.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == invoice.items.length - 1;

            return pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: pw.BoxDecoration(
                color: index % 2 == 0 ? PdfColors.white : lightGreyColor,
                border: pw.Border(
                  left: pw.BorderSide(color: lightGreyColor, width: 1),
                  right: pw.BorderSide(color: lightGreyColor, width: 1),
                  bottom: pw.BorderSide(color: lightGreyColor, width: isLast ? 1 : 0),
                  top: pw.BorderSide.none,
                ),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 4,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          item.productName,
                          style: pw.TextStyle(
                            color: darkColor,
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        if (item.variantName.isNotEmpty)
                          pw.Text(
                            item.variantName,
                            style: pw.TextStyle(
                              color: greyColor,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      '${item.quantity}',
                      style: pw.TextStyle(
                        color: darkColor,
                        fontSize: 11,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      'Rs. ${item.discountedPrice.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        color: darkColor,
                        fontSize: 11,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      'Rs. ${item.subTotal.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        color: darkColor,
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          pw.SizedBox(height: 24),

          // Pricing Summary
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Notes
              pw.Expanded(
                flex: 1,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (invoice.notes.orderNote.isNotEmpty && invoice.notes.orderNote != 'N/A') ...[
                      pw.Text(
                        'Order Note',
                        style: pw.TextStyle(
                          color: greyColor,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        invoice.notes.orderNote,
                        style: pw.TextStyle(
                          color: darkColor,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Totals
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: lightGreyColor,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    children: [
                      if (settlementInfo != null && settlementInfo.isNotEmpty)
                        ...settlementInfo.map((item) {
                          if (item.value is num) {
                            return _buildTotalRow(item.label, (item.value as num).toDouble());
                          }
                          return pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 4),
                            child: pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                  item.label,
                                  style: pw.TextStyle(
                                    color: PdfColor.fromHex('#6B7280'),
                                    fontSize: 11,
                                  ),
                                ),
                                pw.Text(
                                  '${item.value}',
                                  style: pw.TextStyle(
                                    color: PdfColor.fromHex('#111827'),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          );
                        })
                      else
                        ...invoice.pricing.lineItems.map((item) {
                          if (item.value is num) {
                            return _buildTotalRow(item.label, (item.value as num).toDouble());
                          }
                          return pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 4),
                            child: pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                  item.label,
                                  style: pw.TextStyle(
                                    color: PdfColor.fromHex('#6B7280'),
                                    fontSize: 11,
                                  ),
                                ),
                                pw.Text(
                                  '${item.value}',
                                  style: pw.TextStyle(
                                    color: PdfColor.fromHex('#111827'),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 32),

          // Footer
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: primaryColor, width: 1),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  invoice.footer.message,
                  style: pw.TextStyle(
                    color: darkColor,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  invoice.footer.tagline,
                  style: pw.TextStyle(
                    color: greyColor,
                    fontSize: 11,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf;
  }

  static pw.Widget _buildInfoColumn(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          label.toUpperCase(),
          style: pw.TextStyle(
            color: PdfColor.fromHex('#6B7280'),
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            color: PdfColor.fromHex('#111827'),
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTotalRow(String label, double amount, {bool isDiscount = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              color: PdfColor.fromHex('#6B7280'),
              fontSize: 11,
            ),
          ),
          pw.Text(
            '${isDiscount ? '-' : ''}Rs. ${amount.abs().toStringAsFixed(2)}',
            style: pw.TextStyle(
              color: isDiscount ? PdfColor.fromHex('#10B981') : PdfColor.fromHex('#111827'),
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
