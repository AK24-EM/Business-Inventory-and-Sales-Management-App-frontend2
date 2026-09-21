class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'StoreIQ';
  static const String appVersion = '1.0.0';
  static const int maxStores = 3;

  // Loyalty Program
  static const double pointsPerRupee = 1.0; // 1 point per ₹1 spent
  static const int pointsRedemptionThreshold = 100; // min to redeem
  static const double pointsToRupeeValue = 0.10; // ₹0.10 per point
  static const double maxRedemptionPercentage = 0.20; // max 20% of bill

  // Stock Thresholds
  static const int defaultMinStockLevel = 10;
  static const int lowStockWarningBuffer = 5; // warn when within 5 of min

  // Restocking
  static const int defaultRestockMultiplier = 2; // order 2x avg monthly sales
  static const int minDataDaysForForecast = 30; // need 30 days of data

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String storesCollection = 'stores';
  static const String productsCollection = 'products';
  static const String inventoryCollection = 'inventory';
  static const String stockMovementsCollection = 'stockMovements';
  static const String stockTransfersCollection = 'stockTransfers';
  static const String salesCollection = 'sales';
  static const String customersCollection = 'customers';
  static const String loyaltyAccountsCollection = 'loyaltyAccounts';
  static const String loyaltyTransactionsCollection = 'loyaltyTransactions';
  static const String suppliersCollection = 'suppliers';
  static const String purchaseOrdersCollection = 'purchaseOrders';
  static const String damagedProductsCollection = 'damagedProducts';
  static const String festivalsCollection = 'festivals';
  static const String festivalAlertsCollection = 'festivalAlerts';
  static const String notificationsCollection = 'notifications';

  // Date Formats
  static const String displayDateFormat = 'dd MMM yyyy';
  static const String displayDateTimeFormat = 'dd MMM yyyy, hh:mm a';
  static const String apiDateFormat = 'yyyy-MM-dd';

  // Product Categories
  static const List<String> productCategories = [
    'Grocery',
    'Beverages',
    'Dairy',
    'Bakery',
    'Snacks',
    'Personal Care',
    'Household',
    'Stationery',
    'Electronics',
    'Clothing',
    'Fruits & Vegetables',
    'Frozen Foods',
    'Health & Medicine',
    'Other',
  ];

  // Unit Types
  static const List<String> unitTypes = [
    'pcs',
    'kg',
    'g',
    'litre',
    'ml',
    'box',
    'pack',
    'dozen',
    'pair',
    'bottle',
    'can',
    'sachet',
  ];

  // Damaged Product Reasons
  static const List<String> damageReasons = [
    'Broken/Cracked packaging',
    'Expired product',
    'Damaged in transit',
    'Manufacturing defect',
    'Water damage',
    'Pest damage',
    'Other',
  ];

  // Report Periods
  static const List<String> reportPeriods = [
    'Today',
    'Yesterday',
    'Last 7 Days',
    'This Month',
    'Last Month',
    'Last 3 Months',
    'Last 6 Months',
    'This Year',
    'Custom Range',
  ];

  // AI
  static const int minSalesForAIRecommendation = 50;
  static const int minCustomersForSegmentation = 20;
  static const double associationMinConfidence = 0.3;
  static const int associationMinSupport = 5;
}
