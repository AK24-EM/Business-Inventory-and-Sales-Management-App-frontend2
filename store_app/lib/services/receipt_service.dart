import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../models/sale_model.dart';

/// Service for generating and printing receipts
/// Supports PDF generation, thermal printer, and sharing
class ReceiptService {
  static final ReceiptService _instance = ReceiptService._internal();
  factory ReceiptService() => _instance;
  ReceiptService._internal();

  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  final _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

  /// Generate PDF receipt
  Future<Uint8List> generatePDFReceipt({
    required SaleModel sale,
    required String storeName,
    required String storeAddress,
    required String storePhone,
    String? storeGST,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Store Header
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    storeName,
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    storeAddress,
                    style: const pw.TextStyle(fontSize: 10),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.Text(
                    'Phone: $storePhone',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  if (storeGST != null)
                    pw.Text(
                      'GST: $storeGST',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                ],
              ),
            ),
            pw.Divider(thickness: 2),

            // Invoice Details
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Invoice: ${sale.invoiceNumber}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  _dateFormat.format(sale.timestamp),
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ],
            ),
            pw.SizedBox(height: 4),

            // Customer Info
            if (sale.customerName != null) ...[
              pw.Text(
                'Customer: ${sale.customerName}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              if (sale.customerPhone != null)
                pw.Text(
                  'Phone: ${sale.customerPhone}',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              pw.SizedBox(height: 4),
            ],

            // Employee Info
            pw.Text(
              'Billed by: ${sale.employeeName}',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.Divider(),

            // Items Header
            pw.Row(
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Text(
                    'Item',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    'Qty',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    'Price',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    'Total',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
            pw.Divider(),

            // Items
            ...sale.items.map((item) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          item.productName,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          '${item.quantity}',
                          style: const pw.TextStyle(fontSize: 9),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          _currencyFormat.format(item.unitPrice),
                          style: const pw.TextStyle(fontSize: 9),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          _currencyFormat.format(item.totalPrice),
                          style: const pw.TextStyle(fontSize: 9),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                )),

            pw.Divider(),

            // Totals
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 10)),
                pw.Text(
                  _currencyFormat.format(sale.subtotal),
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),

            if (sale.discountAmount > 0)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Discount:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    '-${_currencyFormat.format(sale.discountAmount)}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),

            if (sale.loyaltyPointsRedeemed > 0)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Loyalty Discount:',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '-${_currencyFormat.format(sale.loyaltyPointsRedeemed)}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),

            pw.Divider(thickness: 2),

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TOTAL:',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  _currencyFormat.format(sale.totalAmount),
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 8),

            // Payment Method
            pw.Text(
              'Payment: ${_getPaymentMethodName(sale.paymentMode)}',
              style: const pw.TextStyle(fontSize: 10),
            ),

            // Loyalty Points
            if (sale.loyaltyPointsEarned > 0) ...[
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.all(4),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 1),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      '🎉 Loyalty Points Earned: ${sale.loyaltyPointsEarned}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Thank you for shopping with us!',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ),
            ],

            pw.SizedBox(height: 12),

            // Footer
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'Thank you for your purchase!',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Visit us again!',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  /// Print receipt directly
  Future<void> printReceipt({
    required SaleModel sale,
    required String storeName,
    required String storeAddress,
    required String storePhone,
    String? storeGST,
  }) async {
    final pdfData = await generatePDFReceipt(
      sale: sale,
      storeName: storeName,
      storeAddress: storeAddress,
      storePhone: storePhone,
      storeGST: storeGST,
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdfData,
      name: 'Receipt_${sale.invoiceNumber}',
    );
  }

  /// Share receipt
  Future<void> shareReceipt({
    required SaleModel sale,
    required String storeName,
    required String storeAddress,
    required String storePhone,
    String? storeGST,
  }) async {
    final pdfData = await generatePDFReceipt(
      sale: sale,
      storeName: storeName,
      storeAddress: storeAddress,
      storePhone: storePhone,
      storeGST: storeGST,
    );

    await Printing.sharePdf(
      bytes: pdfData,
      filename: 'Receipt_${sale.invoiceNumber}.pdf',
    );
  }

  /// Generate thermal printer format (ESC/POS commands)
  Future<String> generateThermalReceipt({
    required SaleModel sale,
    required String storeName,
    required String storeAddress,
    required String storePhone,
    String? storeGST,
  }) async {
    final buffer = StringBuffer();

    // Center align
    buffer.writeln('\x1B\x61\x01');

    // Store name (large, bold)
    buffer.writeln('\x1B\x21\x30'); // Double height + width
    buffer.writeln(storeName);
    buffer.writeln('\x1B\x21\x00'); // Reset

    // Store details
    buffer.writeln(storeAddress);
    buffer.writeln('Phone: $storePhone');
    if (storeGST != null) {
      buffer.writeln('GST: $storeGST');
    }

    // Line
    buffer.writeln('================================');

    // Left align
    buffer.writeln('\x1B\x61\x00');

    // Invoice details
    buffer.writeln('Invoice: ${sale.invoiceNumber}');
    buffer.writeln('Date: ${_dateFormat.format(sale.timestamp)}');

    if (sale.customerName != null) {
      buffer.writeln('Customer: ${sale.customerName}');
      if (sale.customerPhone != null) {
        buffer.writeln('Phone: ${sale.customerPhone}');
      }
    }

    buffer.writeln('Billed by: ${sale.employeeName}');
    buffer.writeln('--------------------------------');

    // Items
    for (final item in sale.items) {
      buffer.writeln(item.productName);
      buffer.writeln(
        '  ${item.quantity} x ${_currencyFormat.format(item.unitPrice)} = ${_currencyFormat.format(item.totalPrice)}',
      );
    }

    buffer.writeln('--------------------------------');

    // Totals
    buffer.writeln(
      'Subtotal: ${_currencyFormat.format(sale.subtotal).padLeft(22)}',
    );

    if (sale.discountAmount > 0) {
      buffer.writeln(
        'Discount: -${_currencyFormat.format(sale.discountAmount).padLeft(21)}',
      );
    }

    if (sale.loyaltyPointsRedeemed > 0) {
      buffer.writeln(
        'Loyalty: -${_currencyFormat.format(sale.loyaltyPointsRedeemed).padLeft(22)}',
      );
    }

    buffer.writeln('================================');

    // Bold for total
    buffer.writeln('\x1B\x21\x08');
    buffer.writeln(
      'TOTAL: ${_currencyFormat.format(sale.totalAmount).padLeft(24)}',
    );
    buffer.writeln('\x1B\x21\x00'); // Reset

    buffer.writeln('');
    buffer.writeln('Payment: ${_getPaymentMethodName(sale.paymentMode)}');

    if (sale.loyaltyPointsEarned > 0) {
      buffer.writeln('');
      buffer.writeln('Loyalty Points Earned: ${sale.loyaltyPointsEarned}');
    }

    buffer.writeln('');
    buffer.writeln('\x1B\x61\x01'); // Center align
    buffer.writeln('Thank you for your purchase!');
    buffer.writeln('Visit us again!');

    // Cut paper
    buffer.writeln('\x1D\x56\x00');

    return buffer.toString();
  }

  /// Generate WhatsApp message for receipt
  String generateWhatsAppReceipt({
    required SaleModel sale,
    required String storeName,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('🧾 *RECEIPT*');
    buffer.writeln('');
    buffer.writeln('📍 *$storeName*');
    buffer.writeln('Invoice: ${sale.invoiceNumber}');
    buffer.writeln('Date: ${_dateFormat.format(sale.timestamp)}');
    buffer.writeln('');

    buffer.writeln('📦 *ITEMS*');
    buffer.writeln('```');
    for (final item in sale.items) {
      buffer.writeln(
        '${item.productName}\n  ${item.quantity} x ${_currencyFormat.format(item.unitPrice)} = ${_currencyFormat.format(item.totalPrice)}',
      );
    }
    buffer.writeln('```');
    buffer.writeln('');

    buffer.writeln('💰 *SUMMARY*');
    buffer.writeln('Subtotal: ${_currencyFormat.format(sale.subtotal)}');

    if (sale.discountAmount > 0) {
      buffer.writeln('Discount: -${_currencyFormat.format(sale.discountAmount)}');
    }

    if (sale.loyaltyPointsRedeemed > 0) {
      buffer.writeln(
        'Loyalty Discount: -${_currencyFormat.format(sale.loyaltyPointsRedeemed)}',
      );
    }

    buffer.writeln('*Total: ${_currencyFormat.format(sale.totalAmount)}*');
    buffer.writeln('');

    buffer.writeln('Payment: ${_getPaymentMethodName(sale.paymentMode)}');

    if (sale.loyaltyPointsEarned > 0) {
      buffer.writeln('');
      buffer.writeln('🎉 Loyalty Points Earned: *${sale.loyaltyPointsEarned}*');
    }

    buffer.writeln('');
    buffer.writeln('Thank you for shopping with us! 🙏');

    return buffer.toString();
  }

  String _getPaymentMethodName(PaymentMode mode) {
    return mode.displayName;
  }
}
