import 'package:flutter_test/flutter_test.dart';
import 'package:store_app/services/analytics_service.dart';
import 'package:store_app/models/sale_model.dart';
import 'package:store_app/models/analytics_model.dart';

void main() {
  group('AnalyticsService - Sales Summary Tests', () {
    test('Should compute sales summary correctly', () {
      final now = DateTime.now();
      final from = now.subtract(const Duration(days: 30));
      
      final sales = [
        _createMockSale(
          id: 's1',
          totalAmount: 1000,
          storeName: 'Store A',
          paymentMode: PaymentMode.cash,
          timestamp: now,
        ),
        _createMockSale(
          id: 's2',
          totalAmount: 2000,
          storeName: 'Store A',
          paymentMode: PaymentMode.upi,
          timestamp: now,
        ),
        _createMockSale(
          id: 's3',
          totalAmount: 1500,
          storeName: 'Store B',
          paymentMode: PaymentMode.card,
          timestamp: now,
        ),
      ];

      final summary = AnalyticsService.computeSalesSummary(sales, from, now);

      expect(summary.totalRevenue, 4500);
      expect(summary.totalTransactions, 3);
      expect(summary.averageTransactionValue, 1500);
      // Note: totalItemsSold depends on items in each sale (default is 1 item each)
      expect(summary.totalItemsSold >= 3, true);
      expect(summary.revenueByStore['Store A'], 3000);
      expect(summary.revenueByStore['Store B'], 1500);
      expect(summary.revenueByPaymentMode['Cash'], 1000);
      expect(summary.revenueByPaymentMode['UPI'], 2000);
      expect(summary.revenueByPaymentMode['Card'], 1500);
    });

    test('Should handle empty sales list', () {
      final now = DateTime.now();
      final from = now.subtract(const Duration(days: 30));
      
      final summary = AnalyticsService.computeSalesSummary([], from, now);

      expect(summary.totalRevenue, 0);
      expect(summary.totalTransactions, 0);
      expect(summary.averageTransactionValue, 0);
      expect(summary.totalItemsSold, 0);
    });

    test('Should aggregate revenue by category', () {
      final now = DateTime.now();
      final sales = [
        _createMockSale(
          id: 's1',
          totalAmount: 1000,
          items: [
            SaleItem(
              productId: 'p1',
              productName: 'Product 1',
              category: 'Electronics',
              quantity: 1,
              unitPrice: 500,
              totalPrice: 500,
            ),
            SaleItem(
              productId: 'p2',
              productName: 'Product 2',
              category: 'Clothing',
              quantity: 1,
              unitPrice: 500,
              totalPrice: 500,
            ),
          ],
          timestamp: now,
        ),
      ];

      final summary = AnalyticsService.computeSalesSummary(
        sales,
        now.subtract(const Duration(days: 1)),
        now,
      );

      expect(summary.revenueByCategory['Electronics'], 500);
      expect(summary.revenueByCategory['Clothing'], 500);
    });
  });

  group('AnalyticsService - Product Performance Tests', () {
    test('Should rank products by quantity sold', () {
      final now = DateTime.now();
      final sales = [
        _createMockSale(
          id: 's1',
          items: [
            SaleItem(
              productId: 'p1',
              productName: 'Popular Product',
              category: 'Electronics',
              quantity: 10,
              unitPrice: 100,
              totalPrice: 1000,
            ),
          ],
          timestamp: now,
        ),
        _createMockSale(
          id: 's2',
          items: [
            SaleItem(
              productId: 'p2',
              productName: 'Less Popular',
              category: 'Electronics',
              quantity: 5,
              unitPrice: 100,
              totalPrice: 500,
            ),
          ],
          timestamp: now,
        ),
      ];

      final performance = AnalyticsService.computeProductPerformance(
        sales,
        now.subtract(const Duration(days: 1)),
        now,
      );

      expect(performance.length, 2);
      expect(performance.first.productName, 'Popular Product');
      expect(performance.first.quantitySold, 10);
      expect(performance.last.productName, 'Less Popular');
      expect(performance.last.quantitySold, 5);
    });

    test('Should limit results to specified limit', () {
      final now = DateTime.now();
      final sales = List.generate(
        30,
        (i) => _createMockSale(
          id: 's$i',
          items: [
            SaleItem(
              productId: 'p$i',
              productName: 'Product $i',
              category: 'Category',
              quantity: i + 1,
              unitPrice: 100,
              totalPrice: (i + 1) * 100,
            ),
          ],
          timestamp: now,
        ),
      );

      final performance = AnalyticsService.computeProductPerformance(
        sales,
        now.subtract(const Duration(days: 1)),
        now,
        limit: 10,
      );

      expect(performance.length, 10);
    });

    test('Should calculate revenue per product correctly', () {
      final now = DateTime.now();
      final sales = [
        _createMockSale(
          id: 's1',
          items: [
            SaleItem(
              productId: 'p1',
              productName: 'Product',
              category: 'Cat',
              quantity: 5,
              unitPrice: 200,
              totalPrice: 1000,
            ),
          ],
          timestamp: now,
        ),
        _createMockSale(
          id: 's2',
          items: [
            SaleItem(
              productId: 'p1',
              productName: 'Product',
              category: 'Cat',
              quantity: 3,
              unitPrice: 200,
              totalPrice: 600,
            ),
          ],
          timestamp: now,
        ),
      ];

      final performance = AnalyticsService.computeProductPerformance(
        sales,
        now.subtract(const Duration(days: 1)),
        now,
      );

      expect(performance.length, 1);
      expect(performance.first.quantitySold, 8);
      expect(performance.first.revenue, 1600);
    });
  });

  group('AnalyticsService - Customer Insights Tests', () {
    test('Should compute customer insights correctly', () {
      final now = DateTime.now();
      final sales = [
        _createMockSale(
          id: 's1',
          totalAmount: 1000,
          customerPhone: '9876543210',
          customerName: 'John Doe',
          loyaltyPointsEarned: 100,
          timestamp: now,
        ),
        _createMockSale(
          id: 's2',
          totalAmount: 2000,
          customerPhone: '9876543210',
          customerName: 'John Doe',
          loyaltyPointsEarned: 200,
          timestamp: now,
        ),
      ];

      final insights = AnalyticsService.computeCustomerInsights(sales);

      expect(insights.length, 1);
      expect(insights.first.customerName, 'John Doe');
      expect(insights.first.phone, '9876543210');
      expect(insights.first.totalPurchases, 2);
      expect(insights.first.totalSpend, 3000);
      expect(insights.first.averageOrderValue, 1500);
      expect(insights.first.loyaltyPoints, 300);
    });

    test('Should segment customers correctly', () {
      final now = DateTime.now();
      final sales = List.generate(
        25,
        (i) => _createMockSale(
          id: 's$i',
          totalAmount: 1000,
          customerPhone: '9876543210',
          customerName: 'VIP Customer',
          timestamp: now,
        ),
      );

      final insights = AnalyticsService.computeCustomerInsights(sales);

      expect(insights.first.segment, 'VIP'); // 25 purchases >= 20
    });

    test('Should sort customers by total spend', () {
      final now = DateTime.now();
      final sales = [
        _createMockSale(
          id: 's1',
          totalAmount: 5000,
          customerPhone: '1111111111',
          customerName: 'High Spender',
          timestamp: now,
        ),
        _createMockSale(
          id: 's2',
          totalAmount: 1000,
          customerPhone: '2222222222',
          customerName: 'Low Spender',
          timestamp: now,
        ),
      ];

      final insights = AnalyticsService.computeCustomerInsights(sales);

      expect(insights.first.customerName, 'High Spender');
      expect(insights.last.customerName, 'Low Spender');
    });
  });

  group('AnalyticsService - Sales Trends Tests', () {
    test('Should compute daily sales trends', () {
      final day1 = DateTime(2024, 1, 1);
      final day2 = DateTime(2024, 1, 2);
      
      final sales = [
        _createMockSale(
          id: 's1',
          totalAmount: 1000,
          timestamp: day1,
        ),
        _createMockSale(
          id: 's2',
          totalAmount: 2000,
          timestamp: day1,
        ),
        _createMockSale(
          id: 's3',
          totalAmount: 1500,
          timestamp: day2,
        ),
      ];

      final trends = AnalyticsService.computeDailySalesTrend(sales);

      expect(trends.length, 2);
      expect(trends.first.date, DateTime(2024, 1, 1));
      expect(trends.first.revenue, 3000);
      expect(trends.first.transactions, 2);
      expect(trends.last.date, DateTime(2024, 1, 2));
      expect(trends.last.revenue, 1500);
      expect(trends.last.transactions, 1);
    });

    test('Should sort trends by date', () {
      final sales = [
        _createMockSale(
          id: 's1',
          totalAmount: 1000,
          timestamp: DateTime(2024, 1, 3),
        ),
        _createMockSale(
          id: 's2',
          totalAmount: 1000,
          timestamp: DateTime(2024, 1, 1),
        ),
        _createMockSale(
          id: 's3',
          totalAmount: 1000,
          timestamp: DateTime(2024, 1, 2),
        ),
      ];

      final trends = AnalyticsService.computeDailySalesTrend(sales);

      expect(trends.first.date, DateTime(2024, 1, 1));
      expect(trends.last.date, DateTime(2024, 1, 3));
    });
  });
}

// Helper function to create mock sales
SaleModel _createMockSale({
  required String id,
  double totalAmount = 1000,
  String storeName = 'Test Store',
  PaymentMode paymentMode = PaymentMode.cash,
  String? customerPhone,
  String? customerName,
  int loyaltyPointsEarned = 0,
  List<SaleItem>? items,
  required DateTime timestamp,
}) {
  return SaleModel(
    id: id,
    storeId: 'store123',
    storeName: storeName,
    items: items ?? [
      SaleItem(
        productId: 'p1',
        productName: 'Default Product',
        category: 'Default Category',
        quantity: 1,
        unitPrice: totalAmount,
        totalPrice: totalAmount,
      ),
    ],
    subtotal: totalAmount,
    discountAmount: 0,
    totalAmount: totalAmount,
    paymentMode: paymentMode,
    customerId: customerPhone,
    customerName: customerName,
    customerPhone: customerPhone,
    loyaltyPointsEarned: loyaltyPointsEarned,
    loyaltyPointsRedeemed: 0,
    timestamp: timestamp,
    employeeId: 'user123',
    employeeName: 'Test User',
  );
}
