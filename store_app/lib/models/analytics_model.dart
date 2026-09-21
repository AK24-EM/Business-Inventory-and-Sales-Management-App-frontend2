// Analytics data models – computed summaries for dashboard and reports

class SalesSummary {
  final double totalRevenue;
  final int totalTransactions;
  final double averageTransactionValue;
  final int totalItemsSold;
  final Map<String, double> revenueByStore;
  final Map<String, double> revenueByCategory;
  final Map<String, double> revenueByPaymentMode;
  final DateTime periodStart;
  final DateTime periodEnd;

  const SalesSummary({
    required this.totalRevenue,
    required this.totalTransactions,
    required this.averageTransactionValue,
    required this.totalItemsSold,
    required this.revenueByStore,
    required this.revenueByCategory,
    required this.revenueByPaymentMode,
    required this.periodStart,
    required this.periodEnd,
  });
}

class ProductPerformance {
  final String productId;
  final String productName;
  final String category;
  final int quantitySold;
  final double revenue;
  final int daysWithSales;
  final double avgDailySales;

  const ProductPerformance({
    required this.productId,
    required this.productName,
    required this.category,
    required this.quantitySold,
    required this.revenue,
    required this.daysWithSales,
    required this.avgDailySales,
  });
}

class CustomerInsight {
  final String customerId;
  final String customerName;
  final String phone;
  final int totalPurchases;
  final double totalSpend;
  final double averageOrderValue;
  final int loyaltyPoints;
  final List<String> frequentCategories;
  final List<String> frequentProducts;
  final DateTime lastPurchaseDate;

  const CustomerInsight({
    required this.customerId,
    required this.customerName,
    required this.phone,
    required this.totalPurchases,
    required this.totalSpend,
    required this.averageOrderValue,
    required this.loyaltyPoints,
    required this.frequentCategories,
    required this.frequentProducts,
    required this.lastPurchaseDate,
  });

  String get segment {
    if (totalPurchases >= 20 && totalSpend >= 10000) return 'VIP';
    if (totalPurchases >= 10) return 'Loyal';
    if (totalPurchases >= 5) return 'Regular';
    return 'Occasional';
  }
}

class RestockingRequirement {
  final String productId;
  final String productName;
  final String category;
  final String storeId;
  final String storeName;
  final String? supplierId;
  final String? supplierName;
  final int currentStock;
  final int minimumStockLevel;
  final int recommendedOrderQuantity;
  final double purchasePrice;
  final double estimatedCost;
  final bool isModifiedByOwner;
  final int? ownerApprovedQuantity;

  const RestockingRequirement({
    required this.productId,
    required this.productName,
    required this.category,
    required this.storeId,
    required this.storeName,
    this.supplierId,
    this.supplierName,
    required this.currentStock,
    required this.minimumStockLevel,
    required this.recommendedOrderQuantity,
    required this.purchasePrice,
    required this.estimatedCost,
    this.isModifiedByOwner = false,
    this.ownerApprovedQuantity,
  });

  int get finalOrderQuantity => ownerApprovedQuantity ?? recommendedOrderQuantity;
}

class SalesTrend {
  final DateTime date;
  final double revenue;
  final int transactions;
  final String? storeId;

  const SalesTrend({
    required this.date,
    required this.revenue,
    required this.transactions,
    this.storeId,
  });
}

class ProductAssociation {
  final String product1Id;
  final String product1Name;
  final String product2Id;
  final String product2Name;
  final int coOccurrenceCount;
  final double confidence; // 0-1
  final double lift;

  const ProductAssociation({
    required this.product1Id,
    required this.product1Name,
    required this.product2Id,
    required this.product2Name,
    required this.coOccurrenceCount,
    required this.confidence,
    required this.lift,
  });
}

class AIInsight {
  final String id;
  final AIInsightType type;
  final String title;
  final String description;
  final Map<String, dynamic> data;
  final double confidence;
  final DateTime generatedAt;
  final bool isActedUpon;

  const AIInsight({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.data,
    required this.confidence,
    required this.generatedAt,
    this.isActedUpon = false,
  });
}

enum AIInsightType {
  customerPackage,
  restockingInsight,
  demandForecast,
  supplierIssue,
  crossSellOpportunity,
  customerSegment,
  priceOptimization,
}
