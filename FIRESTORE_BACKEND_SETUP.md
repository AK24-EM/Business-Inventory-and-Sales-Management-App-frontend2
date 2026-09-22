# GCP Firestore Backend Configuration Guide

Complete setup guide for querying sorted data from Firestore backend.

---

## 🎯 **Overview**

This backend is configured to efficiently query and sort data from GCP Firestore. All queries use Firestore's native sorting capabilities for optimal performance.

---

## 📋 **Prerequisites**

1. **GCP Project**: Active Google Cloud Platform project
2. **Firebase Project**: Firebase enabled on the GCP project
3. **Firebase CLI**: Installed globally
4. **Flutter Environment**: For mobile app deployment

```bash
npm install -g firebase-tools
firebase login
```

---

## 🔧 **Step 1: Deploy Firestore Indexes**

Indexes are required for compound queries (filtering + sorting).

```bash
cd /Users/aayushkamble/Desktop/store_invemtory_mamanagement

# Deploy indexes to GCP Firestore
firebase deploy --only firestore:indexes

# Wait for indexes to build (can take 5-15 minutes)
# Check status: https://console.firebase.google.com/project/YOUR_PROJECT/firestore/indexes
```

**Key Indexes Created:**

| Collection | Fields | Purpose |
|------------|--------|---------|
| `sales` | `storeId` ASC, `timestamp` DESC | Store sales by newest |
| `sales` | `customerId` ASC, `timestamp` DESC | Customer purchase history |
| `sales` | `customerPhone` ASC, `timestamp` DESC | Phone-based sales lookup |
| `inventory` | `storeId` ASC, `lastUpdated` DESC | Recent inventory changes |
| `stockMovements` | `storeId` ASC, `timestamp` DESC | Stock movement history |
| `loyaltyTransactions` | `phone` ASC, `timestamp` DESC | Loyalty transaction history |
| `customers` | `registeredStoreId` ASC, `registeredAt` DESC | Store customers by newest |

---

## 🔒 **Step 2: Deploy Firestore Security Rules**

```bash
# Deploy security rules
firebase deploy --only firestore:rules

# Verify rules are active
# Check: https://console.firebase.google.com/project/YOUR_PROJECT/firestore/rules
```

**Security Features:**
- ✅ Role-based access control (Owner, Manager, Employee)
- ✅ Store-level data isolation
- ✅ JWT token validation
- ✅ Custom claims enforcement

---

## 📊 **Step 3: Query Patterns**

### **1. Get Recent Sales for a Store**

**Frontend (Flutter):**
```dart
// Automatically sorted by timestamp DESC
final sales = await salesService.getSalesByStore(
  storeId, 
  DateTime.now().subtract(Duration(days: 30)),
  DateTime.now()
);
```

**Backend Query:**
```dart
_sales
  .where('storeId', isEqualTo: storeId)
  .where('timestamp', isGreaterThanOrEqualTo: startDate)
  .where('timestamp', isLessThanOrEqualTo: endDate)
  .orderBy('timestamp', descending: true)
  .get()
```

**Firestore Index Required:** ✅ `sales: storeId ASC, timestamp DESC`

---

### **2. Get Customer Purchase History (Rahul Sharma)**

**Frontend (Flutter):**
```dart
// Method 1: By Customer ID
final sales = await salesService.getCustomerSales('cust_01');

// Method 2: By Phone Number
final sales = await salesService.getSalesByCustomerPhone('+91 98451 22394');
```

**Backend Query:**
```dart
_sales
  .where('customerPhone', isEqualTo: '+91 98451 22394')
  .orderBy('timestamp', descending: true)
  .get()
```

**Firestore Index Required:** ✅ `sales: customerPhone ASC, timestamp DESC`

---

### **3. Real-Time Sales Stream**

**Frontend (Flutter):**
```dart
// Live updates, sorted by newest first
Stream<List<SaleModel>> stream = salesService.getTodaySalesStream(storeId);

stream.listen((sales) {
  print('Latest sale: ${sales.first.invoiceNumber}');
});
```

**Backend Query:**
```dart
_sales
  .where('storeId', isEqualTo: storeId)
  .where('timestamp', isGreaterThanOrEqualTo: todayStart)
  .orderBy('timestamp', descending: true)
  .snapshots()
```

---

### **4. Get Low Stock Items**

**Frontend (Flutter):**
```dart
final lowStock = await inventoryService.getStoreInventory(
  storeId,
  lowStockOnly: true
);
```

**Backend Query:**
```dart
_inventory
  .where('storeId', isEqualTo: storeId)
  .where('currentStock', isLessThan: minimumStockLevel)
  .orderBy('currentStock', descending: false)
  .get()
```

---

### **5. Get Stock Movement History**

**Frontend (Flutter):**
```dart
Stream<List<StockMovement>> movements = 
  inventoryService.getMovementHistoryStream(storeId, productId);
```

**Backend Query:**
```dart
_stockMovements
  .where('storeId', isEqualTo: storeId)
  .where('productId', isEqualTo: productId)
  .orderBy('timestamp', descending: true)
  .snapshots()
```

**Firestore Index Required:** ✅ `stockMovements: storeId ASC, productId ASC, timestamp DESC`

---

## 🚀 **Step 4: Testing Queries**

### **Test 1: Verify Rahul Sharma's Sales**

```dart
// In Flutter app or Firestore console
final sales = await FirebaseFirestore.instance
  .collection('sales')
  .where('customerPhone', isEqualTo: '+91 98451 22394')
  .orderBy('timestamp', descending: true)
  .get();

print('Total purchases: ${sales.docs.length}');
sales.docs.forEach((doc) {
  print('${doc.data()['timestamp']} - ₹${doc.data()['totalAmount']}');
});
```

### **Test 2: Verify Index Usage**

```bash
# Enable Firestore debug logging in Flutter
flutter run --dart-define=FIRESTORE_DEBUG=true

# Check logs for:
# ✅ "Using index: sales_storeId_timestamp"
# ❌ "Index not found, using collection scan" (BAD!)
```

---

## 📈 **Performance Optimization**

### **Best Practices:**

1. **Always Use Indexes**
   - Never query without an index in production
   - Monitor index usage in Firebase Console

2. **Limit Query Results**
   ```dart
   .orderBy('timestamp', descending: true)
   .limit(50)  // Limit to 50 most recent
   ```

3. **Use Pagination for Large Datasets**
   ```dart
   // First page
   var query = _sales
     .orderBy('timestamp', descending: true)
     .limit(20);
   
   // Next page
   var lastDoc = previousSnapshot.docs.last;
   query = query.startAfterDocument(lastDoc);
   ```

4. **Cache Frequently Accessed Data**
   ```dart
   // Enable persistence
   FirebaseFirestore.instance.settings = Settings(
     persistenceEnabled: true,
     cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
   );
   ```

---

## 🔍 **Monitoring & Debugging**

### **Firebase Console Monitoring**

1. **Check Index Build Status:**
   ```
   https://console.firebase.google.com/project/YOUR_PROJECT/firestore/indexes
   ```

2. **Monitor Query Performance:**
   ```
   https://console.firebase.google.com/project/YOUR_PROJECT/firestore/usage
   ```

3. **View Security Rules:**
   ```
   https://console.firebase.google.com/project/YOUR_PROJECT/firestore/rules
   ```

### **Common Issues**

| Issue | Solution |
|-------|----------|
| "Index not found" error | Deploy indexes: `firebase deploy --only firestore:indexes` |
| "Permission denied" error | Check firestore.rules, verify JWT token has correct claims |
| Slow queries | Add `.limit()` and pagination, enable persistence |
| Unsorted results | Ensure `.orderBy()` is present in query |

---

## 🎯 **Client Request Examples**

### **Example 1: "Show me recent sales data sorted by newest, for customer Rahul Sharma"**

**Query:**
```dart
final sales = await salesService.getSalesByCustomerPhone('+91 98451 22394');

// Result: List<SaleModel> sorted by timestamp DESC
// sales[0] = Most recent purchase
// sales[1] = Second most recent
// ...
```

**Response:**
```json
[
  {
    "id": "sale_xyz789",
    "customerName": "Rahul Sharma",
    "customerPhone": "+91 98451 22394",
    "totalAmount": 1210.0,
    "timestamp": "2026-09-22T14:30:00Z",
    "items": [...]
  },
  {
    "id": "sale_abc123",
    "customerName": "Rahul Sharma",
    "customerPhone": "+91 98451 22394",
    "totalAmount": 850.0,
    "timestamp": "2026-09-15T10:15:00Z",
    "items": [...]
  }
]
```

---

### **Example 2: "Show all inventory sorted by stock level"**

**Query:**
```dart
final inventory = await inventoryService.getStoreInventory(storeId);
inventory.sort((a, b) => a.currentStock.compareTo(b.currentStock));
```

---

### **Example 3: "Show loyalty transactions for a customer"**

**Query:**
```dart
final transactions = await loyaltyService.getTransactionHistory(
  phone: '+91 98451 22394',
  limit: 50
);

// Already sorted by timestamp DESC in Firestore
```

---

## 🛠️ **Deployment Checklist**

- [ ] Firebase project created and linked to GCP
- [ ] Firestore indexes deployed: `firebase deploy --only firestore:indexes`
- [ ] Security rules deployed: `firebase deploy --only firestore:rules`
- [ ] Indexes fully built (check Firebase Console)
- [ ] Flutter app configured with Firebase
- [ ] Test queries verified in Firestore Console
- [ ] Performance monitoring enabled
- [ ] Caching configured for offline support

---

## 📞 **Support**

- **Firestore Documentation**: https://firebase.google.com/docs/firestore
- **Index Management**: https://firebase.google.com/docs/firestore/query-data/indexing
- **Query Best Practices**: https://firebase.google.com/docs/firestore/best-practices

---

## 🎉 **Summary**

Your backend is now configured to:
- ✅ Query sales data sorted by timestamp (newest first)
- ✅ Get customer-specific purchase history (e.g., Rahul Sharma)
- ✅ Real-time data streams with automatic sorting
- ✅ Efficient index-based queries
- ✅ Role-based security enforcement
- ✅ Optimal performance with Firestore native sorting

**Next Step:** Deploy indexes and test queries in your Flutter app!
