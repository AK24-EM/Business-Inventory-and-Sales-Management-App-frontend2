import 'package:flutter_test/flutter_test.dart';
import 'package:store_app/models/customer_model.dart';

void main() {
  group('CustomerModel Tests', () {
    test('Should create customer with required fields', () {
      final now = DateTime.now();
      final customer = CustomerModel(
        id: 'cust123',
        name: 'John Doe',
        phone: '9876543210',
        registeredAt: now,
        registeredStoreId: 'store123',
        registeredByUserId: 'user123',
      );

      expect(customer.id, 'cust123');
      expect(customer.name, 'John Doe');
      expect(customer.phone, '9876543210');
      expect(customer.isActive, true); // default value
    });

    test('Should create customer with optional fields', () {
      final customer = CustomerModel(
        id: 'cust456',
        name: 'Jane Smith',
        phone: '9876543211',
        email: 'jane@example.com',
        address: '123 Main St',
        registeredAt: DateTime.now(),
        registeredStoreId: 'store123',
        registeredByUserId: 'user123',
      );

      expect(customer.email, 'jane@example.com');
      expect(customer.address, '123 Main St');
    });

    test('Should handle isActive status', () {
      final activeCustomer = CustomerModel(
        id: 'cust1',
        name: 'Active',
        phone: '1111111111',
        registeredAt: DateTime.now(),
        registeredStoreId: 'store123',
        registeredByUserId: 'user123',
        isActive: true,
      );

      final inactiveCustomer = CustomerModel(
        id: 'cust2',
        name: 'Inactive',
        phone: '2222222222',
        registeredAt: DateTime.now(),
        registeredStoreId: 'store123',
        registeredByUserId: 'user123',
        isActive: false,
      );

      expect(activeCustomer.isActive, true);
      expect(inactiveCustomer.isActive, false);
    });
  });

  group('LoyaltyAccount Tests', () {
    test('Should create loyalty account correctly', () {
      final now = DateTime.now();
      final account = LoyaltyAccount(
        id: '9876543210',
        primaryCustomerId: 'cust123',
        phone: '9876543210',
        totalPoints: 500,
        redeemedPoints: 100,
        availablePoints: 400,
        createdAt: now,
        lastActivity: now,
      );

      expect(account.phone, '9876543210');
      expect(account.totalPoints, 500);
      expect(account.redeemedPoints, 100);
      expect(account.availablePoints, 400);
    });

    test('Should calculate points correctly', () {
      final account = LoyaltyAccount(
        id: 'phone',
        primaryCustomerId: 'cust',
        phone: '9876543210',
        totalPoints: 1000,
        redeemedPoints: 600,
        availablePoints: 400,
        createdAt: DateTime.now(),
        lastActivity: DateTime.now(),
      );

      expect(account.totalPoints, account.redeemedPoints + account.availablePoints);
    });
  });

  group('LoyaltyTransaction Tests', () {
    test('Should create earn transaction', () {
      final txn = LoyaltyTransaction(
        id: 'txn123',
        loyaltyAccountId: '9876543210',
        phone: '9876543210',
        customerId: 'cust123',
        customerName: 'John Doe',
        type: LoyaltyTransactionType.earn,
        points: 50,
        saleId: 'sale123',
        storeId: 'store123',
        storeName: 'Test Store',
        processedByUserId: 'user123',
        processedByUserName: 'Cashier',
        timestamp: DateTime.now(),
        notes: 'Earned from purchase',
      );

      expect(txn.type, LoyaltyTransactionType.earn);
      expect(txn.points, 50);
      expect(txn.saleId, 'sale123');
    });

    test('Should create redeem transaction', () {
      final txn = LoyaltyTransaction(
        id: 'txn456',
        loyaltyAccountId: '9876543210',
        phone: '9876543210',
        customerId: 'cust123',
        customerName: 'John Doe',
        type: LoyaltyTransactionType.redeem,
        points: 100,
        saleId: 'sale456',
        storeId: 'store123',
        storeName: 'Test Store',
        processedByUserId: 'user123',
        processedByUserName: 'Cashier',
        timestamp: DateTime.now(),
        notes: 'Redeemed at POS',
      );

      expect(txn.type, LoyaltyTransactionType.redeem);
      expect(txn.points, 100);
    });

    test('Should handle adjustment transaction', () {
      final txn = LoyaltyTransaction(
        id: 'txn789',
        loyaltyAccountId: '9876543210',
        phone: '9876543210',
        type: LoyaltyTransactionType.adjust,
        points: -50,
        storeId: 'store123',
        storeName: 'Test Store',
        processedByUserId: 'admin123',
        processedByUserName: 'Admin',
        timestamp: DateTime.now(),
        notes: 'Manual adjustment',
      );

      expect(txn.type, LoyaltyTransactionType.adjust);
      expect(txn.points, -50);
      expect(txn.notes, 'Manual adjustment');
    });
  });

  group('LoyaltyTransactionType Tests', () {
    test('Should have all transaction types', () {
      expect(LoyaltyTransactionType.values.length, 4); // earn, redeem, adjust, expire
      expect(LoyaltyTransactionType.values.contains(LoyaltyTransactionType.earn), true);
      expect(LoyaltyTransactionType.values.contains(LoyaltyTransactionType.redeem), true);
      expect(LoyaltyTransactionType.values.contains(LoyaltyTransactionType.adjust), true);
      expect(LoyaltyTransactionType.values.contains(LoyaltyTransactionType.expire), true);
    });
  });
}
