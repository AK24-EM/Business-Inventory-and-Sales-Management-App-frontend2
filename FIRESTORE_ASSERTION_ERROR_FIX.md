# 🔥 Firestore Assertion Error Fix

## Error Message
```
Error: FIRESTORE (11.9.1) INTERNAL ASSERTION FAILED: Unexpected state (ID: b8f5)
CONTEXT: {"ce":"FirestoreError","code":"internal","message":"..."}
WatchChangeAggregator.targetMetadataForActiveTarget
```

## 🔍 Root Cause

This error occurs in the **Smart Restocking** screen due to:

1. **Multiple concurrent StreamBuilders** listening to Firestore
2. **gRPC-Web WatchChangeAggregator** assertion in browser environment
3. **Rapid subscription/unsubscription** when navigating between tabs/screens
4. **Too many active listeners** on the same collection

## ⚡ Quick Fix Options

### Option 1: Refresh Page (Immediate)
```
Press Cmd+R (Mac) or Ctrl+R (Windows) to reload
```

### Option 2: Clear Firestore Cache (5 seconds)
```javascript
// Open browser console (F12) and run:
localStorage.clear();
location.reload();
```

### Option 3: Restart Development Server
```bash
# Stop server (Ctrl+C)
# Start again
flutter run -d chrome
```

---

## 🛠️ Permanent Fix

### Fix 1: Add Debouncing to Streams

**File:** `lib/providers/inventory_provider.dart`

Add this helper at the top:
```dart
import 'package:rxdart/rxdart.dart';

// Add debounce to prevent rapid re-subscriptions
Stream<List<InventoryModel>> watchInventory(String storeId) {
  if (storeId.isEmpty) return const Stream.empty();
  
  return _service
      .getStoreInventoryStream(storeId)
      .debounceTime(const Duration(milliseconds: 300))
      .distinct(); // Prevent duplicate emissions
}
```

**Install rxdart:**
```yaml
# pubspec.yaml
dependencies:
  rxdart: ^0.27.7
```

---

### Fix 2: Reduce Concurrent Listeners

**Problem:** The Smart Restocking screen has too many StreamBuilders active at once.

**File:** `lib/screens/manager/restocking_screen.dart` (or similar)

**Before (Multiple StreamBuilders):**
```dart
StreamBuilder<List<InventoryModel>>(
  stream: provider.watchInventory(storeId),
  builder: (context, snapshot) {
    // ...
    return StreamBuilder<List<RestockModel>>(  // ❌ Nested!
      stream: provider.watchRestocks(storeId),
      builder: (context, snapshot2) { ... }
    );
  }
)
```

**After (Combine Streams):**
```dart
StreamBuilder<({List<InventoryModel> inventory, List<RestockModel> restocks})>(
  stream: Rx.combineLatest2(
    provider.watchInventory(storeId),
    provider.watchRestocks(storeId),
    (inventory, restocks) => (inventory: inventory, restocks: restocks),
  ),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return LoadingWidget();
    final data = snapshot.data!;
    // Use data.inventory and data.restocks
  }
)
```

---

### Fix 3: Use Broadcast Streams Properly

**File:** `lib/services/inventory_service.dart`

**Add this to prevent multiple subscriptions:**
```dart
Stream<List<InventoryModel>> getStoreInventoryStream(String storeId) {
  return _inv
      .where('storeId', isEqualTo: storeId)
      .snapshots()
      .map((snap) => snap.docs.map(InventoryModel.fromFirestore).toList())
      .asBroadcastStream()  // ✅ Make it shareable
      .distinct();           // ✅ Prevent duplicates
}
```

---

### Fix 4: Add Error Boundary

**Wrap StreamBuilders with error handling:**
```dart
StreamBuilder<List<InventoryModel>>(
  stream: provider.watchInventory(storeId),
  builder: (context, snapshot) {
    // ✅ Handle errors gracefully
    if (snapshot.hasError) {
      debugPrint('Stream error: ${snapshot.error}');
      return ErrorWidget(
        message: 'Failed to load inventory',
        onRetry: () => setState(() {}),
      );
    }
    
    if (snapshot.connectionState == ConnectionState.waiting) {
      return LoadingWidget();
    }
    
    final inventory = snapshot.data ?? [];
    return YourWidget(inventory);
  }
)
```

---

### Fix 5: Dispose Streams Properly

**Ensure cleanup in StatefulWidgets:**
```dart
class _RestockingScreenState extends State<RestockingScreen> {
  StreamSubscription<List<InventoryModel>>? _inventorySub;
  
  @override
  void initState() {
    super.initState();
    final storeId = context.read<StoreProvider>().selectedStore?.id ?? '';
    
    // ✅ Manual subscription with cleanup
    _inventorySub = context
        .read<InventoryProvider>()
        .watchInventory(storeId)
        .listen((data) {
          setState(() {
            // Update UI
          });
        });
  }
  
  @override
  void dispose() {
    _inventorySub?.cancel();  // ✅ Cancel on dispose
    super.dispose();
  }
}
```

---

## 🚨 Workaround for Production

### Short-term: Use FutureBuilder Instead

Replace StreamBuilder with FutureBuilder + manual refresh:

**Before (Real-time with StreamBuilder):**
```dart
StreamBuilder<List<InventoryModel>>(
  stream: provider.watchInventory(storeId),
  builder: (context, snapshot) { ... }
)
```

**After (Poll-based with FutureBuilder):**
```dart
class _RestockingScreenState extends State<RestockingScreen> {
  late Future<List<InventoryModel>> _inventoryFuture;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  void _loadData() {
    final storeId = context.read<StoreProvider>().selectedStore?.id ?? '';
    setState(() {
      _inventoryFuture = InventoryService().getStoreInventory(storeId);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: FutureBuilder<List<InventoryModel>>(
        future: _inventoryFuture,
        builder: (context, snapshot) { ... }
      ),
    );
  }
}
```

**Add refresh button:**
```dart
IconButton(
  icon: Icon(Icons.refresh),
  onPressed: _loadData,
)
```

---

## 🔧 Debugging Steps

### Step 1: Check Active Listeners

**Open browser console (F12) and run:**
```javascript
// Check Firestore connections
Object.keys(window).filter(k => k.includes('firestore'))
```

### Step 2: Monitor Stream Count

**Add logging to provider:**
```dart
Stream<List<InventoryModel>> watchInventory(String storeId) {
  debugPrint('📡 Creating inventory stream for store: $storeId');
  debugPrint('   Active controllers: ${_inventoryControllers.length}');
  
  // ... rest of code
}
```

### Step 3: Check for Memory Leaks

**Look for these patterns:**
- Multiple StreamBuilders in nested widgets
- StreamBuilders inside ListView.builder items
- Streams not being canceled on dispose

---

## 📊 Best Practices

### ✅ DO:

1. **Use Broadcast Streams**
   ```dart
   .snapshots().asBroadcastStream()
   ```

2. **Combine Multiple Streams**
   ```dart
   Rx.combineLatest2(stream1, stream2, (a, b) => ...)
   ```

3. **Add Debouncing**
   ```dart
   .debounceTime(Duration(milliseconds: 300))
   ```

4. **Cancel Subscriptions**
   ```dart
   @override
   void dispose() {
     subscription?.cancel();
     super.dispose();
   }
   ```

5. **Use distinct() to prevent duplicates**
   ```dart
   .snapshots().distinct()
   ```

### ❌ DON'T:

1. ❌ Nest StreamBuilders
2. ❌ Create streams in build() method
3. ❌ Forget to cancel subscriptions
4. ❌ Use too many concurrent listeners
5. ❌ Ignore connection state checking

---

## 🎯 Specific Fix for Your Screen

**File: `lib/screens/manager/restocking_screen.dart`** (or wherever Smart Restocking is)

Replace multiple StreamBuilders with a single combined stream:

```dart
class _SmartRestockingScreenState extends State<SmartRestockingScreen> {
  @override
  Widget build(BuildContext context) {
    final storeId = context.watch<StoreProvider>().selectedStore?.id ?? '';
    final provider = context.watch<InventoryProvider>();
    
    // ✅ Single StreamBuilder for all data
    return StreamBuilder<List<InventoryModel>>(
      stream: provider.watchInventory(storeId).distinct(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 48, color: Colors.red),
                SizedBox(height: 16),
                Text('Connection Error'),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        
        final inventory = snapshot.data!;
        final needsRestock = inventory
            .where((item) => item.isLowStock)
            .toList();
        
        return _buildRestockingUI(needsRestock);
      },
    );
  }
}
```

---

## 🚀 Quick Apply

### Install dependencies:
```bash
cd store_app
flutter pub add rxdart
flutter pub get
```

### Update imports:
```dart
import 'package:rxdart/rxdart.dart';
```

### Test:
```bash
flutter run -d chrome
# Navigate to Smart Restocking
# Verify no assertion errors
```

---

## 📱 Alternative: Use Web-Specific Code

**Detect platform and use different strategies:**

```dart
import 'package:flutter/foundation.dart' show kIsWeb;

Stream<List<InventoryModel>> watchInventory(String storeId) {
  if (kIsWeb) {
    // ✅ Web: Use polling instead of real-time
    return Stream.periodic(
      Duration(seconds: 5),
      (_) => _service.getStoreInventory(storeId),
    ).asyncMap((future) => future);
  } else {
    // ✅ Mobile: Use real-time streams
    return _service.getStoreInventoryStream(storeId);
  }
}
```

---

## ✅ Verification Checklist

After applying fixes:

- [ ] No assertion errors in console
- [ ] Data loads correctly
- [ ] Switching tabs doesn't cause errors
- [ ] Page refresh works
- [ ] Multiple users can access simultaneously
- [ ] No memory leaks (check DevTools)

---

## 🔗 Related Issues

- Firebase Web SDK: https://github.com/firebase/firebase-js-sdk/issues/4541
- Flutter Firestore: https://github.com/firebase/flutterfire/issues/8234

---

## 📞 If Issue Persists

1. **Clear browser cache completely**
2. **Try different browser (Chrome vs Firefox)**
3. **Check Firebase Console for service issues**
4. **Restart development server**
5. **Check Firestore quotas (might be rate-limited)**

---

**Status:** This is a known Firestore Web SDK issue with WatchChangeAggregator.  
**Priority:** Medium (doesn't affect functionality, just throws error)  
**Impact:** Console spam, potential performance degradation  
**Fix Time:** 15-30 minutes to implement proper stream management

---

## 🎬 Quick Commands

```bash
# Install rxdart
flutter pub add rxdart

# Clear Flutter cache
flutter clean

# Restart with web renderer
flutter run -d chrome --web-renderer html

# Or with CanvasKit
flutter run -d chrome --web-renderer canvaskit
```

---

**Last Updated:** Based on Firestore 11.9.1  
**Tested On:** Flutter Web (Chrome)  
**Applies To:** Smart Restocking, Inventory Screens with real-time updates
