import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../config/app_constants.dart';
import '../models/sale_model.dart';
import '../models/store_model.dart';

class BillingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _sales =>
      _db.collection(AppConstants.salesCollection);
  CollectionReference<Map<String, dynamic>> get _stores =>
      _db.collection(AppConstants.storesCollection);

  /// Get sale by ID for invoice generation
  Future<SaleModel?> getSaleById(String saleId) async {
    final doc = await _sales.doc(saleId).get();
    if (!doc.exists) return null;
    return SaleModel.fromFirestore(doc);
  }

  /// Get store details for invoice header
  Future<StoreModel?> getStoreById(String storeId) async {
    final doc = await _stores.doc(storeId).get();
    if (!doc.exists) return null;
    return StoreModel.fromFirestore(doc);
  }

  /// Generate invoice text (for receipt printing or display)
  Future<String> generateInvoiceText(String saleId) async {
    final sale = await getSaleById(saleId);
    if (sale == null) return 'Sale not found';

    final store = await getStoreById(sale.storeId);
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('           ${store?.name ?? sale.storeName}');
    if (store != null) {
      buffer.writeln('        ${store.address}');
      if (store.phone.isNotEmpty) {
        buffer.writeln('        Phone: ${store.phone}');
      }
    }
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln();
    
    // Invoice details
    buffer.writeln('Invoice: ${sale.invoiceNumber ?? sale.id}');
    buffer.writeln('Date: ${dateFormat.format(sale.timestamp)}');
    buffer.writeln('Cashier: ${sale.employeeName}');
    if (sale.customerName != null) {
      buffer.writeln('Customer: ${sale.customerName}');
      if (sale.customerPhone != null) {
        buffer.writeln('Phone: ${sale.customerPhone}');
      }
    }
    buffer.writeln('Payment: ${sale.paymentMode.displayName}');
    buffer.writeln();
    buffer.writeln('───────────────────────────────────────');
    
    // Items
    buffer.writeln('Item                    Qty  Price  Total');
    buffer.writeln('───────────────────────────────────────');
    
    for (final item in sale.items) {
      final name = item.productName.length > 20
          ? '${item.productName.substring(0, 17)}...'
          : item.productName.padRight(20);
      final qty = item.quantity.toString().padLeft(3);
      final price = '₹${item.unitPrice.toStringAsFixed(2)}'.padLeft(7);
      final total = '₹${item.totalPrice.toStringAsFixed(2)}'.padLeft(7);
      buffer.writeln('$name $qty $price $total');
    }
    
    buffer.writeln('───────────────────────────────────────');
    
    // Totals
    buffer.writeln('Subtotal:              ₹${sale.subtotal.toStringAsFixed(2)}');
    
    if (sale.discountAmount > 0) {
      buffer.writeln('Discount:             -₹${sale.discountAmount.toStringAsFixed(2)}');
    }
    
    if (sale.loyaltyPointsRedeemed > 0) {
      buffer.writeln('Loyalty Redeemed:     -₹${sale.loyaltyPointsRedeemed.toStringAsFixed(2)}');
    }
    
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('TOTAL:                 ₹${sale.totalAmount.toStringAsFixed(2)}');
    buffer.writeln('═══════════════════════════════════════');
    
    // Loyalty info
    if (sale.loyaltyPointsEarned > 0 && sale.customerPhone != null) {
      buffer.writeln();
      buffer.writeln('Loyalty Points Earned: ${sale.loyaltyPointsEarned}');
      buffer.writeln('Thank you for shopping with us!');
    }
    
    buffer.writeln();
    buffer.writeln('         Visit Again!');
    buffer.writeln('═══════════════════════════════════════');
    
    return buffer.toString();
  }

  /// Generate invoice data for PDF or detailed display
  Future<Map<String, dynamic>> generateInvoiceData(String saleId) async {
    final sale = await getSaleById(saleId);
    if (sale == null) {
      throw Exception('Sale not found');
    }

    final store = await getStoreById(sale.storeId);
    
    return {
      'sale': sale,
      'store': store,
      'invoiceNumber': sale.invoiceNumber ?? 'INV-${sale.id}',
      'date': sale.timestamp,
      'formattedDate': DateFormat('dd MMM yyyy').format(sale.timestamp),
      'formattedTime': DateFormat('hh:mm a').format(sale.timestamp),
      'items': sale.items.map((item) => {
        'name': item.productName,
        'category': item.category,
        'quantity': item.quantity,
        'unitPrice': item.unitPrice,
        'totalPrice': item.totalPrice,
      }).toList(),
      'subtotal': sale.subtotal,
      'discount': sale.discountAmount,
      'loyaltyRedeemed': sale.loyaltyPointsRedeemed,
      'total': sale.totalAmount,
      'paymentMode': sale.paymentMode.displayName,
      'customerName': sale.customerName,
      'customerPhone': sale.customerPhone,
      'employeeName': sale.employeeName,
      'loyaltyPointsEarned': sale.loyaltyPointsEarned,
      'totalItems': sale.itemCount,
      'storeInfo': store != null ? {
        'name': store.name,
        'address': store.address,
        'phone': store.phone,
      } : {
        'name': sale.storeName,
      },
    };
  }

  /// Get sales by date range for billing reports
  Future<List<SaleModel>> getSalesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? storeId,
    String? employeeId,
  }) async {
    Query<Map<String, dynamic>> query = _sales;
    
    if (storeId != null) {
      query = query.where('storeId', isEqualTo: storeId);
    }
    
    if (employeeId != null) {
      query = query.where('employeeId', isEqualTo: employeeId);
    }
    
    final snap = await query.get();
    final sales = snap.docs.map(SaleModel.fromFirestore).toList();
    
    // Filter by date range (client-side)
    return sales.where((sale) {
      return !sale.timestamp.isBefore(startDate) &&
          !sale.timestamp.isAfter(endDate);
    }).toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Calculate sales summary for billing reports
  Future<Map<String, dynamic>> calculateSalesSummary({
    required DateTime startDate,
    required DateTime endDate,
    String? storeId,
  }) async {
    final sales = await getSalesByDateRange(
      startDate: startDate,
      endDate: endDate,
      storeId: storeId,
    );

    if (sales.isEmpty) {
      return {
        'totalSales': 0,
        'totalRevenue': 0.0,
        'totalItems': 0,
        'totalDiscount': 0.0,
        'totalLoyaltyRedeemed': 0.0,
        'cashSales': 0,
        'upiSales': 0,
        'cardSales': 0,
        'cashAmount': 0.0,
        'upiAmount': 0.0,
        'cardAmount': 0.0,
        'avgBillValue': 0.0,
        'sales': <SaleModel>[],
      };
    }

    final totalSales = sales.length;
    final totalRevenue = sales.fold<double>(0, (sum, s) => sum + s.totalAmount);
    final totalItems = sales.fold<int>(0, (sum, s) => sum + s.itemCount);
    final totalDiscount = sales.fold<double>(0, (sum, s) => sum + s.discountAmount);
    final totalLoyaltyRedeemed = sales.fold<double>(0, (sum, s) => sum + s.loyaltyPointsRedeemed);
    
    final cashSales = sales.where((s) => s.paymentMode == PaymentMode.cash).length;
    final upiSales = sales.where((s) => s.paymentMode == PaymentMode.upi).length;
    final cardSales = sales.where((s) => s.paymentMode == PaymentMode.card).length;
    
    final cashAmount = sales
        .where((s) => s.paymentMode == PaymentMode.cash)
        .fold<double>(0, (sum, s) => sum + s.totalAmount);
    final upiAmount = sales
        .where((s) => s.paymentMode == PaymentMode.upi)
        .fold<double>(0, (sum, s) => sum + s.totalAmount);
    final cardAmount = sales
        .where((s) => s.paymentMode == PaymentMode.card)
        .fold<double>(0, (sum, s) => sum + s.totalAmount);

    return {
      'totalSales': totalSales,
      'totalRevenue': totalRevenue,
      'totalItems': totalItems,
      'totalDiscount': totalDiscount,
      'totalLoyaltyRedeemed': totalLoyaltyRedeemed,
      'cashSales': cashSales,
      'upiSales': upiSales,
      'cardSales': cardSales,
      'cashAmount': cashAmount,
      'upiAmount': upiAmount,
      'cardAmount': cardAmount,
      'avgBillValue': totalRevenue / totalSales,
      'sales': sales,
    };
  }

  /// Get payment mode breakdown
  Map<String, dynamic> getPaymentModeBreakdown(List<SaleModel> sales) {
    final cashSales = sales.where((s) => s.paymentMode == PaymentMode.cash);
    final upiSales = sales.where((s) => s.paymentMode == PaymentMode.upi);
    final cardSales = sales.where((s) => s.paymentMode == PaymentMode.card);

    return {
      'cash': {
        'count': cashSales.length,
        'amount': cashSales.fold<double>(0, (sum, s) => sum + s.totalAmount),
      },
      'upi': {
        'count': upiSales.length,
        'amount': upiSales.fold<double>(0, (sum, s) => sum + s.totalAmount),
      },
      'card': {
        'count': cardSales.length,
        'amount': cardSales.fold<double>(0, (sum, s) => sum + s.totalAmount),
      },
    };
  }

  /// Export invoice list for a period
  Future<List<Map<String, dynamic>>> exportInvoiceList({
    required DateTime startDate,
    required DateTime endDate,
    String? storeId,
  }) async {
    final sales = await getSalesByDateRange(
      startDate: startDate,
      endDate: endDate,
      storeId: storeId,
    );

    return sales.map((sale) => {
      'invoiceNumber': sale.invoiceNumber ?? sale.id,
      'date': DateFormat('dd/MM/yyyy').format(sale.timestamp),
      'time': DateFormat('HH:mm').format(sale.timestamp),
      'customerName': sale.customerName ?? 'Walk-in',
      'customerPhone': sale.customerPhone ?? '',
      'items': sale.itemCount,
      'amount': sale.totalAmount,
      'paymentMode': sale.paymentMode.displayName,
      'employeeName': sale.employeeName,
    }).toList();
  }
}
