import '../models/sale_model.dart';
import '../models/inventory_model.dart';
import '../models/analytics_model.dart';
import '../models/customer_model.dart';
import '../config/app_constants.dart';
import 'sales_service.dart';
import 'inventory_service.dart';
import 'customer_service.dart';

class AnalyticsService {
  final SalesService _salesService;
  final InventoryService _inventoryService;
  final CustomerService _customerService;

  AnalyticsService(
      this._salesService, this._inventoryService, this._customerService);

  // ── Sales Summary ─────────────────────────────────────────────────────────

  Future<SalesSummary> getSalesSummary({
    List<String>? storeIds,
    required DateTime from,
    required DateTime to,
  }) async {
    List<SaleModel> allSales = [];
    if (storeIds != null) {
      for (final storeId in storeIds) {
        final s = await _salesService.getSalesByStore(storeId, from, to);
        allSales.addAll(s);
      }
    } else {
      allSales = await _salesService.getAllSales(from, to);
    }

    double totalRevenue = 0;
    int totalItems = 0;
    final revenueByStore = <String, double>{};
    final revenueByCategory = <String, double>{};
    final revenueByPayment = <String, double>{};

    for (final sale in allSales) {
      totalRevenue += sale.totalAmount;
      totalItems += sale.itemCount;
      revenueByStore[sale.storeName] =
          (revenueByStore[sale.storeName] ?? 0) + sale.totalAmount;
      revenueByPayment[sale.paymentMode.displayName] =
          (revenueByPayment[sale.paymentMode.displayName] ?? 0) +
              sale.totalAmount;
      for (final item in sale.items) {
        revenueByCategory[item.category] =
            (revenueByCategory[item.category] ?? 0) + item.totalPrice;
      }
    }

    return SalesSummary(
      totalRevenue: totalRevenue,
      totalTransactions: allSales.length,
      averageTransactionValue:
          allSales.isEmpty ? 0 : totalRevenue / allSales.length,
      totalItemsSold: totalItems,
      revenueByStore: revenueByStore,
      revenueByCategory: revenueByCategory,
      revenueByPaymentMode: revenueByPayment,
      periodStart: from,
      periodEnd: to,
    );
  }

  // ── Product Performance ───────────────────────────────────────────────────

  Future<List<ProductPerformance>> getProductPerformance({
    String? storeId,
    required DateTime from,
    required DateTime to,
    int limit = 20,
  }) async {
    List<SaleModel> sales;
    if (storeId != null) {
      sales = await _salesService.getSalesByStore(storeId, from, to);
    } else {
      sales = await _salesService.getAllSales(from, to);
    }

    final Map<String, Map<String, dynamic>> productMap = {};
    final daysInPeriod = to.difference(from).inDays + 1;
    final daysWithSales = <String, Set<String>>{};

    for (final sale in sales) {
      final dateKey =
          '${sale.timestamp.year}-${sale.timestamp.month}-${sale.timestamp.day}';
      for (final item in sale.items) {
        productMap.putIfAbsent(
          item.productId,
          () => {
            'name': item.productName,
            'category': item.category,
            'qty': 0,
            'revenue': 0.0,
          },
        );
        productMap[item.productId]!['qty'] =
            (productMap[item.productId]!['qty'] as int) + item.quantity;
        productMap[item.productId]!['revenue'] =
            (productMap[item.productId]!['revenue'] as double) +
                item.totalPrice;
        daysWithSales
            .putIfAbsent(item.productId, () => {})
            .add(dateKey);
      }
    }

    final performances = productMap.entries.map((e) {
      final days = daysWithSales[e.key]?.length ?? 1;
      final qty = e.value['qty'] as int;
      return ProductPerformance(
        productId: e.key,
        productName: e.value['name'] as String,
        category: e.value['category'] as String,
        quantitySold: qty,
        revenue: e.value['revenue'] as double,
        daysWithSales: days,
        avgDailySales: qty / daysInPeriod,
      );
    }).toList();

    performances.sort((a, b) => b.quantitySold.compareTo(a.quantitySold));
    return performances.take(limit).toList();
  }

  // ── Sales Trend ───────────────────────────────────────────────────────────

  Future<List<SalesTrend>> getDailySalesTrend({
    String? storeId,
    required DateTime from,
    required DateTime to,
  }) async {
    List<SaleModel> sales;
    if (storeId != null) {
      sales = await _salesService.getSalesByStore(storeId, from, to);
    } else {
      sales = await _salesService.getAllSales(from, to);
    }

    final Map<String, SalesTrend> trendMap = {};
    for (final sale in sales) {
      final dateKey =
          '${sale.timestamp.year}-${sale.timestamp.month.toString().padLeft(2, '0')}-${sale.timestamp.day.toString().padLeft(2, '0')}';
      final existing = trendMap[dateKey];
      if (existing == null) {
        trendMap[dateKey] = SalesTrend(
          date: DateTime(
              sale.timestamp.year, sale.timestamp.month, sale.timestamp.day),
          revenue: sale.totalAmount,
          transactions: 1,
          storeId: storeId,
        );
      } else {
        trendMap[dateKey] = SalesTrend(
          date: existing.date,
          revenue: existing.revenue + sale.totalAmount,
          transactions: existing.transactions + 1,
          storeId: storeId,
        );
      }
    }

    final trends = trendMap.values.toList();
    trends.sort((a, b) => a.date.compareTo(b.date));
    return trends;
  }

  // ── Customer Insights ─────────────────────────────────────────────────────

  Future<List<CustomerInsight>> getCustomerInsights({
    required DateTime from,
    required DateTime to,
  }) async {
    final sales = await _salesService.getAllSales(from, to);
    final Map<String, Map<String, dynamic>> customerMap = {};

    for (final sale in sales) {
      if (sale.customerPhone == null) continue;
      final key = sale.customerPhone!;
      customerMap.putIfAbsent(key, () => {
        'customerId': sale.customerId ?? '',
        'name': sale.customerName ?? 'Unknown',
        'phone': key,
        'purchases': 0,
        'spend': 0.0,
        'categories': <String, int>{},
        'products': <String, int>{},
        'loyaltyPoints': 0,
        'lastPurchase': sale.timestamp,
      });
      final c = customerMap[key]!;
      c['purchases'] = (c['purchases'] as int) + 1;
      c['spend'] = (c['spend'] as double) + sale.totalAmount;
      c['loyaltyPoints'] =
          (c['loyaltyPoints'] as int) + sale.loyaltyPointsEarned;
      if ((c['lastPurchase'] as DateTime).isBefore(sale.timestamp)) {
        c['lastPurchase'] = sale.timestamp;
      }
      for (final item in sale.items) {
        final cats = c['categories'] as Map<String, int>;
        cats[item.category] = (cats[item.category] ?? 0) + item.quantity;
        final prods = c['products'] as Map<String, int>;
        prods[item.productName] =
            (prods[item.productName] ?? 0) + item.quantity;
      }
    }

    return customerMap.values.map((c) {
      final cats = c['categories'] as Map<String, int>;
      final prods = c['products'] as Map<String, int>;
      final sortedCats = cats.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final sortedProds = prods.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final purchases = c['purchases'] as int;
      final spend = c['spend'] as double;
      return CustomerInsight(
        customerId: c['customerId'] as String,
        customerName: c['name'] as String,
        phone: c['phone'] as String,
        totalPurchases: purchases,
        totalSpend: spend,
        averageOrderValue: purchases > 0 ? spend / purchases : 0,
        loyaltyPoints: c['loyaltyPoints'] as int,
        frequentCategories:
            sortedCats.take(3).map((e) => e.key).toList(),
        frequentProducts:
            sortedProds.take(3).map((e) => e.key).toList(),
        lastPurchaseDate: c['lastPurchase'] as DateTime,
      );
    }).toList()
      ..sort((a, b) => b.totalSpend.compareTo(a.totalSpend));
  }

  // ── Product Associations (Market Basket) ─────────────────────────────────

  Future<List<ProductAssociation>> getProductAssociations({
    String? storeId,
    required DateTime from,
    required DateTime to,
  }) async {
    List<SaleModel> sales;
    if (storeId != null) {
      sales = await _salesService.getSalesByStore(storeId, from, to);
    } else {
      sales = await _salesService.getAllSales(from, to);
    }

    if (sales.length < AppConstants.minSalesForAIRecommendation) return [];

    final Map<String, int> productFreq = {};
    final Map<String, int> pairFreq = {};

    for (final sale in sales) {
      final products = sale.items.map((i) => i.productId).toSet().toList();
      for (final p in products) {
        productFreq[p] = (productFreq[p] ?? 0) + 1;
      }
      for (int i = 0; i < products.length; i++) {
        for (int j = i + 1; j < products.length; j++) {
          final pair = [products[i], products[j]]..sort();
          final key = '${pair[0]}__${pair[1]}';
          pairFreq[key] = (pairFreq[key] ?? 0) + 1;
        }
      }
    }

    final productNames = <String, String>{};
    for (final sale in sales) {
      for (final item in sale.items) {
        productNames[item.productId] = item.productName;
      }
    }

    final List<ProductAssociation> associations = [];
    for (final entry in pairFreq.entries) {
      if (entry.value < AppConstants.associationMinSupport) continue;
      final ids = entry.key.split('__');
      final p1Freq = productFreq[ids[0]] ?? 1;
      final p2Freq = productFreq[ids[1]] ?? 1;
      final confidence = entry.value / p1Freq;
      if (confidence < AppConstants.associationMinConfidence) continue;
      final expected = (p1Freq * p2Freq) / sales.length;
      final lift = expected > 0 ? entry.value / expected : 0;
      associations.add(ProductAssociation(
        product1Id: ids[0],
        product1Name: productNames[ids[0]] ?? ids[0],
        product2Id: ids[1],
        product2Name: productNames[ids[1]] ?? ids[1],
        coOccurrenceCount: entry.value,
        confidence: confidence,
        lift: lift.toDouble(),
      ));
    }

    associations.sort((a, b) => b.lift.compareTo(a.lift));
    return associations.take(20).toList();
  }

  // ── Restocking Requirements ───────────────────────────────────────────────

  Future<List<RestockingRequirement>> getRestockingRequirements(
      List<String> storeIds) async {
    final List<RestockingRequirement> requirements = [];
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    for (final storeId in storeIds) {
      // Get low stock items
      final allInv = await _inventoryService
          .getStoreInventoryStream(storeId)
          .first;
      final lowStockItems = allInv.where((i) => i.isLowStock).toList();

      // Get sales data for recommendation
      final sales =
          await _salesService.getSalesByStore(storeId, thirtyDaysAgo, now);

      final Map<String, int> soldQty = {};
      for (final sale in sales) {
        for (final item in sale.items) {
          soldQty[item.productId] =
              (soldQty[item.productId] ?? 0) + item.quantity;
        }
      }

      for (final inv in lowStockItems) {
        final monthlySales = soldQty[inv.productId] ?? 0;
        final recommended = monthlySales > 0
            ? (monthlySales * AppConstants.defaultRestockMultiplier)
            : (inv.minimumStockLevel * 2);

        requirements.add(RestockingRequirement(
          productId: inv.productId,
          productName: inv.productName,
          category: inv.category,
          storeId: storeId,
          storeName: storeId, // will be enriched with store name by provider
          currentStock: inv.currentStock,
          minimumStockLevel: inv.minimumStockLevel,
          recommendedOrderQuantity: recommended,
          purchasePrice: 0, // enriched by provider
          estimatedCost: 0,
        ));
      }
    }

    return requirements;
  }
}
