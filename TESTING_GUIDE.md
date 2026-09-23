# StoreIQ Manager Features - Testing Guide

## 🧪 Quick Start Testing

### Prerequisites
```bash
# Navigate to app directory
cd store_app

# Install dependencies
flutter pub get

# Run the app
flutter run
```

---

## 🔍 Testing Scenarios

### Scenario 1: Smart Restocking
**Objective**: Test AI-powered restock recommendations and PO creation

**Steps**:
1. Login as Manager
2. Navigate to Manager Dashboard
3. Tap "Smart Restock" button or "Restock" tab
4. **Verify**: Products below minimum stock appear
5. **Verify**: Each product shows urgency level (CRITICAL/HIGH/MEDIUM/LOW)
6. Select 2-3 products using checkboxes
7. Adjust quantities using +/- buttons
8. **Verify**: Total cost updates in real-time
9. Tap "Create Purchase Orders" button
10. **Verify**: Success message appears
11. **Verify**: Notification created in notification center
12. Tap notification bell icon
13. **Verify**: "Purchase Orders Created" notification visible

**Expected Results**:
- ✅ Products sorted by urgency
- ✅ Cost calculations correct
- ✅ PO created in Firestore
- ✅ Notification received
- ✅ No errors in console

---

### Scenario 2: Festival Planning
**Objective**: Test festival countdown and stock buffer recommendations

**Prerequisites**: Create a festival in Firestore
```javascript
// Firebase Console -> Firestore -> Add Collection: "festivals"
{
  name: "Diwali 2024",
  startDate: Timestamp(2024-11-01),
  endDate: Timestamp(2024-11-05),
  advanceOrderDays: 14,
  isActive: true,
  createdAt: Timestamp.now()
}
```

**Steps**:
1. Login as Manager
2. Navigate to "Festivals" tab
3. **Verify**: Festival appears with countdown
4. **Verify**: Readiness percentage shown
5. **Verify**: Stock buffer recommendations by category:
   - Sweets: 3.0x
   - Dry Fruits: 2.5x
   - Dairy: 2.0x
   - Snacks: 2.0x
6. Tap "Generate Festival Stock Orders"
7. **Verify**: Navigate to restocking screen
8. Tap "View Last Year's Performance"
9. **Verify**: Modal opens with placeholder message

**Expected Results**:
- ✅ Festival countdown accurate
- ✅ Category multipliers displayed
- ✅ Navigation works correctly
- ✅ No console errors

---

### Scenario 3: Notifications
**Objective**: Test notification system

**Steps**:
1. Login as Manager
2. Create a purchase order (see Scenario 1)
3. Tap notification bell icon
4. **Verify**: Notification list appears
5. **Verify**: New notification has colored dot
6. Tap on a notification
7. **Verify**: Notification marked as read (dot disappears)
8. Tap "Mark all read" button
9. **Verify**: All notifications marked as read

**Manual Notification Test**:
```dart
// Add to manager dashboard temporarily
final notificationService = NotificationService();
await notificationService.sendCustomNotification(
  title: '🧪 Test Notification',
  message: 'This is a test notification',
  userId: currentUser.id,
  storeId: store.id,
);
```

**Expected Results**:
- ✅ Notifications appear in real-time
- ✅ Mark as read works
- ✅ Filtered by user/store correctly

---

### Scenario 4: Analytics Dashboard
**Objective**: Test analytics with real-time data

**Steps**:
1. Login as Manager
2. Tap "Analytics" tab
3. **Verify**: 4 tabs visible (Overview, Sales Trend, Products, Customers)
4. Select "Last 30 Days" period
5. **Verify**: KPI cards show data:
   - Total Revenue
   - Transactions
   - Average Basket
   - Units Sold
6. Switch to "Sales Trend" tab
7. **Verify**: Line chart displays daily revenue
8. Switch to "Products" tab
9. **Verify**: Top products listed with bar chart
10. Switch to "Customers" tab
11. **Verify**: Customer insights displayed

**Expected Results**:
- ✅ Real-time data from Firestore
- ✅ Charts render correctly
- ✅ Period selection works
- ✅ All tabs functional

---

## 🐛 Common Issues & Solutions

### Issue 1: "Please select a store"
**Cause**: No store assigned to manager
**Solution**: 
1. Login as Owner
2. Go to User Management
3. Edit manager user
4. Assign a store

### Issue 2: No products in restocking
**Cause**: All products above minimum stock
**Solution**: Manually lower inventory or adjust minimum stock levels

### Issue 3: Notifications not appearing
**Cause**: Firestore security rules not configured
**Solution**: Deploy security rules:
```bash
firebase deploy --only firestore:rules
```

### Issue 4: Festival not showing
**Cause**: Festival date in past or not active
**Solution**: Create festival with future date and `isActive: true`

### Issue 5: PO creation fails
**Cause**: User not authenticated properly
**Solution**: Check auth state, re-login if needed

---

## 📊 Data Requirements

### Minimum Data for Testing

**1. Products** (at least 10):
```javascript
{
  name: "Product Name",
  category: "Sweets", // Or Dairy, Snacks, etc.
  purchasePrice: 50,
  sellingPrice: 65,
  supplierId: "supplier_id",
  active: true
}
```

**2. Inventory** (with low stock):
```javascript
{
  storeId: "store_001",
  productId: "prod_001",
  currentStock: 5,
  minimumStock: 20, // Below this triggers restock
  maximumStock: 100
}
```

**3. Suppliers**:
```javascript
{
  name: "Supplier Name",
  contactPerson: "John Doe",
  phone: "+919876543210",
  email: "supplier@example.com",
  productIds: ["prod_001", "prod_002"]
}
```

**4. Festivals**:
```javascript
{
  name: "Diwali 2024",
  startDate: Timestamp(future date),
  endDate: Timestamp(future date + 5 days),
  advanceOrderDays: 14,
  isActive: true,
  createdAt: Timestamp.now()
}
```

**5. Sales** (for analytics):
```javascript
{
  storeId: "store_001",
  employeeId: "emp_001",
  customerId: "cust_001",
  items: [{productId: "prod_001", quantity: 2, unitPrice: 65}],
  totalAmount: 130,
  paymentMethod: "UPI",
  timestamp: Timestamp.now()
}
```

---

## 🔐 Security Rules to Deploy

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner() {
      return request.auth.token.role == 'owner';
    }
    
    function isManager() {
      return request.auth.token.role == 'manager';
    }
    
    function isEmployee() {
      return request.auth.token.role == 'employee';
    }
    
    function assignedStore() {
      return request.auth.token.storeId;
    }
    
    // Notifications
    match /notifications/{notificationId} {
      allow read: if isAuthenticated() && 
                     (resource.data.targetUserId == request.auth.uid || isOwner());
      allow create: if isOwner();
      allow update: if isAuthenticated() && 
                       resource.data.targetUserId == request.auth.uid;
    }
    
    // Festivals
    match /festivals/{festivalId} {
      allow read: if isAuthenticated();
      allow write: if isOwner();
    }
    
    // Purchase Orders
    match /purchaseOrders/{poId} {
      allow read: if isAuthenticated() && 
                     (isOwner() || resource.data.targetStoreId == assignedStore());
      allow create: if isAuthenticated() && (isOwner() || isManager());
      allow update: if isOwner() || (isManager() && resource.data.targetStoreId == assignedStore());
    }
    
    // Festival Demand Alerts
    match /festivalDemandAlerts/{alertId} {
      allow read: if isAuthenticated() && 
                     (isOwner() || resource.data.storeId == assignedStore());
      allow create: if isOwner();
      allow update: if isAuthenticated() && 
                       (isOwner() || (isManager() && resource.data.storeId == assignedStore()));
    }
  }
}
```

**Deploy**:
```bash
firebase deploy --only firestore:rules
```

---

## 📱 Test on Multiple Devices

### iOS Testing
```bash
flutter run -d iPhone
```

### Android Testing
```bash
flutter run -d android
```

### Web Testing
```bash
flutter run -d chrome
```

### Physical Device
```bash
flutter devices  # List devices
flutter run -d <device-id>
```

---

## 🎯 Performance Testing

### Check App Size
```bash
flutter build apk --analyze-size
```

### Profile Performance
```bash
flutter run --profile
```

### Check Memory Leaks
```bash
flutter run --profile
# Use DevTools to monitor memory
```

---

## ✅ Testing Checklist

### Manager Restocking
- [ ] Screen loads without errors
- [ ] Products display with urgency indicators
- [ ] Sorting works (urgency, alphabetical, category, cost)
- [ ] Selection checkboxes work
- [ ] Quantity adjustment works
- [ ] Total cost calculates correctly
- [ ] PO creation succeeds
- [ ] Success notification appears
- [ ] PO saved in Firestore with correct user details
- [ ] Empty state shows when no low stock

### Festival Planning
- [ ] Screen loads without errors
- [ ] Festival list displays
- [ ] Countdown timer accurate
- [ ] Readiness percentage shown
- [ ] Category multipliers display correctly
- [ ] Generate orders button works
- [ ] Historical analysis modal opens
- [ ] No festivals state shows correctly

### Notifications
- [ ] Notification icon shows count
- [ ] Notification list loads
- [ ] New notifications highlighted
- [ ] Mark as read works
- [ ] Mark all as read works
- [ ] Notifications filtered by user
- [ ] Real-time updates work

### Analytics
- [ ] All 4 tabs load
- [ ] Period selection works
- [ ] KPI cards show correct data
- [ ] Charts render properly
- [ ] Real-time data updates
- [ ] No errors in console

---

## 🚀 Load Testing

### Simulate Multiple POs
```dart
// Create 10 POs rapidly
for (int i = 0; i < 10; i++) {
  await supplierService.createPurchaseOrder(/* ... */);
}
```
**Expected**: All POs created without errors

### Simulate Many Notifications
```dart
// Create 50 notifications
for (int i = 0; i < 50; i++) {
  await notificationService.sendCustomNotification(/* ... */);
}
```
**Expected**: List scrolls smoothly, no lag

---

## 📝 Bug Reporting Template

When reporting bugs, include:

```markdown
**Description**: Clear description of the issue

**Steps to Reproduce**:
1. Step 1
2. Step 2
3. Step 3

**Expected Behavior**: What should happen

**Actual Behavior**: What actually happens

**Screenshots**: If applicable

**Environment**:
- Device: iPhone 14 Pro / Android Pixel 6
- OS Version: iOS 17 / Android 13
- App Version: 1.0.0

**Console Logs**: Any error messages

**Firestore State**: Relevant document snapshots
```

---

## 🎉 Success Criteria

The features are ready for production when:

✅ All test scenarios pass  
✅ No compilation errors  
✅ No runtime errors in console  
✅ Firestore security rules deployed  
✅ All user workflows complete end-to-end  
✅ Performance is smooth (no lag)  
✅ Data persists correctly in Firestore  
✅ Notifications deliver successfully  
✅ Multi-device testing passed  

---

**Status**: Ready for Testing  
**Version**: 1.0.1  
**Last Updated**: December 2024
