import 'package:flutter_test/flutter_test.dart';
import 'package:store_app/models/sale_model.dart';

void main() {
  group('SaleModel Tests', () {
    test('Should create SaleModel with all required fields', () {
      final now = DateTime.now();
      final saleItem = SaleItem(
        productId: 'prod123',
        productName: 'Test Product',
        category: 'Electronics',
        quantity: 2,
        unitPrice: 100.0,
        totalPrice: 200.0,
      );

      final sale = SaleModel(
        id: 'sale123',
        storeId: 'store123',
        storeName: 'Test Store',
        items: [saleItem],
        subtotal: 200.0,
        discountAmount: 0,
        totalAmount: 200.0,
        paymentMode: PaymentMode.cash,
        customerId: 'cust123',
        customerName: 'John Doe',
        customerPhone: '9876543210',
        loyaltyPointsEarned: 20,
        loyaltyPointsRedeemed: 0,
        timestamp: now,
        employeeId: 'user123',
        employeeName: 'Jane Smith',
      );

      expect(sale.id, 'sale123');
      expect(sale.storeId, 'store123');
      expect(sale.totalAmount, 200.0);
      expect(sale.items.length, 1);
      expect(sale.items.first.productName, 'Test Product');
      expect(sale.paymentMode, PaymentMode.cash);
    });

    test('Should calculate item count correctly', () {
      final items = [
        SaleItem(
          productId: 'p1',
          productName: 'Product 1',
          category: 'Cat1',
          quantity: 2,
          unitPrice: 100,
          totalPrice: 200,
        ),
        SaleItem(
          productId: 'p2',
          productName: 'Product 2',
          category: 'Cat2',
          quantity: 3,
          unitPrice: 50,
          totalPrice: 150,
        ),
      ];

      final sale = SaleModel(
        id: 'sale123',
        storeId: 'store123',
        storeName: 'Test Store',
        items: items,
        subtotal: 350.0,
        discountAmount: 0,
        totalAmount: 350.0,
        paymentMode: PaymentMode.upi,
        timestamp: DateTime.now(),
        employeeId: 'user123',
        employeeName: 'Cashier',
      );

      // itemCount is a computed getter that sums quantities
      expect(sale.itemCount, 5); // 2 + 3 = 5 total items
      expect(sale.items.length, 2); // 2 different products
    });

    test('Should convert PaymentMode enum to display name', () {
      expect(PaymentMode.cash.displayName, 'Cash');
      expect(PaymentMode.upi.displayName, 'UPI');
      expect(PaymentMode.card.displayName, 'Card');
    });

    test('Should handle loyalty points correctly', () {
      final sale = SaleModel(
        id: 'sale123',
        storeId: 'store123',
        storeName: 'Test Store',
        items: [],
        subtotal: 1000.0,
        discountAmount: 0,
        totalAmount: 1000.0,
        paymentMode: PaymentMode.cash,
        loyaltyPointsEarned: 100,
        loyaltyPointsRedeemed: 50,
        timestamp: DateTime.now(),
        employeeId: 'user123',
        employeeName: 'Cashier',
      );

      expect(sale.loyaltyPointsEarned, 100);
      expect(sale.loyaltyPointsRedeemed, 50);
    });
  });

  group('SaleItem Tests', () {
    test('Should create SaleItem with correct values', () {
      final item = SaleItem(
        productId: 'prod456',
        productName: 'Laptop',
        category: 'Electronics',
        quantity: 1,
        unitPrice: 50000,
        totalPrice: 50000,
      );

      expect(item.productId, 'prod456');
      expect(item.productName, 'Laptop');
      expect(item.category, 'Electronics');
      expect(item.quantity, 1);
      expect(item.unitPrice, 50000);
      expect(item.totalPrice, 50000);
    });

    test('Should handle quantity changes', () {
      final item = SaleItem(
        productId: 'prod789',
        productName: 'Mouse',
        category: 'Accessories',
        quantity: 5,
        unitPrice: 500,
        totalPrice: 2500,
      );

      expect(item.quantity, 5);
      expect(item.totalPrice, 2500);
    });

    test('Should convert SaleItem to map', () {
      final item = SaleItem(
        productId: 'prod123',
        productName: 'Test Product',
        category: 'Test Category',
        quantity: 3,
        unitPrice: 100.0,
        totalPrice: 300.0,
      );

      final map = item.toMap();
      expect(map['productId'], 'prod123');
      expect(map['productName'], 'Test Product');
      expect(map['category'], 'Test Category');
      expect(map['quantity'], 3);
      expect(map['unitPrice'], 100.0);
      expect(map['totalPrice'], 300.0);
    });

    test('Should create SaleItem from map', () {
      final map = {
        'productId': 'prod456',
        'productName': 'Product',
        'category': 'Category',
        'quantity': 2,
        'unitPrice': 50.0,
        'totalPrice': 100.0,
      };

      final item = SaleItem.fromMap(map);
      expect(item.productId, 'prod456');
      expect(item.productName, 'Product');
      expect(item.category, 'Category');
      expect(item.quantity, 2);
      expect(item.unitPrice, 50.0);
      expect(item.totalPrice, 100.0);
    });
  });

  group('PaymentMode Tests', () {
    test('Should have correct payment mode values', () {
      expect(PaymentMode.values.length, 3);
      expect(PaymentMode.values.contains(PaymentMode.cash), true);
      expect(PaymentMode.values.contains(PaymentMode.upi), true);
      expect(PaymentMode.values.contains(PaymentMode.card), true);
    });

    test('Should convert from string correctly', () {
      expect(PaymentModeExtension.fromString('cash'), PaymentMode.cash);
      expect(PaymentModeExtension.fromString('upi'), PaymentMode.upi);
      expect(PaymentModeExtension.fromString('card'), PaymentMode.card);
      expect(PaymentModeExtension.fromString('invalid'), PaymentMode.cash); // default
    });
  });
}
