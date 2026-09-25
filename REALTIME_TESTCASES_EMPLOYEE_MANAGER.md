# Real-Time Update Test Cases - Employee & Manager

## Document Information
- **Version:** 1.0
- **Date:** September 24, 2026
- **App:** Store Inventory Management System
- **Test Type:** Manual & Automated Real-Time Sync Testing

---

## Test Environment Setup

### Prerequisites
- ✅ Two or more devices/browsers logged in simultaneously
- ✅ Stable internet connection
- ✅ Firebase Firestore real-time listeners active
- ✅ Test store with sample data

### Test Devices Configuration
- **Device A:** Employee account
- **Device B:** Manager account
- **Device C:** Owner/Another Employee account (optional)

---

## 🔵 EMPLOYEE ROLE - Real-Time Test Cases

### **1. DASHBOARD - Real-Time Updates**

#### TC-EMP-001: Dashboard Metrics Live Sync
**Objective:** Verify dashboard metrics update in real-time when data changes

**Preconditions:**
- Employee logged in on Device A
- Another user logged in on Device C

**Test Steps:**
1. Note current metrics on Employee dashboard (total sales, items sold, etc.)
2. On Device C, complete a new sale transaction
3. Observe Dashboard on Device A

**Expected Results:**
- ✅ Sales metrics update within 2-3 seconds
- ✅ "LIVE SYNC" badge displays with green pulse indicator
- ✅ Last sync timestamp updates automatically
- ✅ No page refresh required
- ✅ Total Sales Today increases
- ✅ Items Sold count increases
- ✅ Revenue chart updates

**Test Data:**
- Sale Amount: ₹500
- Items: 2 products
- Payment: Cash

**Status:** [ ] Pass [ ] Fail [ ] Blocked

**Notes:**
_____________________________________________________

---

#### TC-EMP-002: Recent Sales Feed Update
**Objective:** Verify recent sales list updates in real-time

**Test Steps:**
1. Keep Employee dashboard open
2. From Device C, complete a sale with customer info
3. Watch "Recent Sales" section on Device A

**Expected Results:**
- ✅ New sale appears at top of list within 2 seconds
- ✅ Sale shows correct amount, time, payment mode
- ✅ Customer name displays if applicable
- ✅ Animation/highlight on new entry (if implemented)
- ✅ List automatically scrolls or highlights new item

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

#### TC-EMP-003: Low Stock Alerts Live Update
**Objective:** Verify low stock alerts appear in real-time

**Test Steps:**
1. Check current inventory levels
2. On Device C, create a sale that brings a product below threshold
3. Check alerts on Device A

**Expected Results:**
- ✅ Low stock alert appears immediately
- ✅ Alert badge count increases
- ✅ Product appears in "Low Stock Items" widget
- ✅ Notification banner shows (if enabled)

**Test Data:**
- Product: "Test Product A"
- Current Stock: 12 units
- Threshold: 10 units
- Sale Quantity: 5 units (brings to 7)

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### **2. POS SCREEN - Real-Time Updates**

#### TC-EMP-004: Inventory Quantity Live Sync During POS
**Objective:** Verify product stock updates while on POS screen

**Test Steps:**
1. Open POS screen on Device A
2. Search for "Product X" (current stock: 50)
3. On Device C, complete sale of 10 units of "Product X"
4. Check "Product X" availability on Device A (without refresh)

**Expected Results:**
- ✅ Available quantity updates from 50 to 40
- ✅ Update happens without leaving POS screen
- ✅ No error if product added to cart before sync
- ✅ Warning if trying to add more than available stock

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

#### TC-EMP-005: Product Price Live Update
**Objective:** Verify product prices sync in real-time

**Test Steps:**
1. Add "Product Y" to cart (Price: ₹100)
2. On Device B (Manager), update "Product Y" price to ₹120
3. On Device A, search for "Product Y" again
4. Check displayed price

**Expected Results:**
- ✅ New search shows ₹120
- ✅ Items already in cart show original price (₹100)
- ✅ Warning message if significant price difference
- ✅ Total recalculates for new additions

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

#### TC-EMP-006: Customer Loyalty Points Live Sync
**Objective:** Verify customer loyalty points update during checkout

**Test Steps:**
1. Start checkout for Customer "John" (Points: 500)
2. On Device C, another employee redeems 200 points for "John"
3. On Device A, check available points for redemption

**Expected Results:**
- ✅ Available points update to 300
- ✅ Maximum redemption amount recalculates
- ✅ If already redeemed more than available, warning appears
- ✅ Points display updates without re-searching customer

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### **3. INVENTORY SCREEN - Real-Time Updates**

#### TC-EMP-007: Inventory List Real-Time Sync
**Objective:** Verify inventory list updates when products are modified

**Test Steps:**
1. Open Inventory screen on Device A
2. On Device B, add a new product "Product Z"
3. Check inventory list on Device A
4. On Device B, update quantity of existing product
5. Verify update on Device A

**Expected Results:**
- ✅ New product appears in list within 2 seconds
- ✅ Existing product quantity updates
- ✅ Sort order maintained
- ✅ Search results update if product matches filter
- ✅ "LIVE SYNC" indicator active

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

#### TC-EMP-008: Stock Level Changes During Sale
**Objective:** Verify stock reduces in real-time when sales occur

**Test Steps:**
1. View "Product M" in inventory (Stock: 100)
2. Device C completes sale with 15 units of "Product M"
3. Check "Product M" on Device A

**Expected Results:**
- ✅ Stock updates to 85 automatically
- ✅ Status changes if crosses threshold (Normal → Low Stock)
- ✅ Stock history/log updates
- ✅ Last updated timestamp refreshes

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

#### TC-EMP-009: Category/Filter Updates
**Objective:** Verify filtered views update correctly

**Test Steps:**
1. Filter inventory by "Low Stock" on Device A
2. On Device C, sell items that bring "Product N" to low stock
3. Check filter results on Device A

**Expected Results:**
- ✅ "Product N" appears in Low Stock filter
- ✅ Count badge updates
- ✅ No page refresh needed

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### **4. CUSTOMERS SCREEN - Real-Time Updates**

#### TC-EMP-010: New Customer Registration Sync
**Objective:** Verify new customers appear in real-time

**Test Steps:**
1. Open Customers screen on Device A
2. On Device C, register new customer "Jane Doe" with phone
3. Check customer list on Device A

**Expected Results:**
- ✅ New customer appears in list within 2 seconds
- ✅ Customer appears in search results immediately
- ✅ Total customer count updates
- ✅ Recent customers widget updates

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

#### TC-EMP-011: Customer Purchase History Live Update
**Objective:** Verify customer purchase history syncs in real-time

**Test Steps:**
1. Open customer "John Doe" profile on Device A
2. On Device C, complete sale for "John Doe"
3. Check purchase history on Device A (without closing profile)

**Expected Results:**
- ✅ New purchase appears in history
- ✅ Total purchases count increases
- ✅ Total spent amount updates
- ✅ Loyalty points update
- ✅ Last purchase date updates

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

#### TC-EMP-012: Loyalty Points Transaction Sync
**Objective:** Verify loyalty transactions sync across devices

**Test Steps:**
1. View customer "Sarah" loyalty account (500 points)
2. On Device C, complete sale earning Sarah 50 points
3. Check loyalty account on Device A

**Expected Results:**
- ✅ Points balance updates to 550
- ✅ Transaction appears in history
- ✅ Available points for redemption updates

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### **5. NOTIFICATIONS - Real-Time Updates**

#### TC-EMP-013: Real-Time Notification Delivery
**Objective:** Verify notifications appear instantly

**Test Steps:**
1. Keep app open on Device A
2. Trigger events that generate notifications:
   - Product goes low stock
   - New customer registered
   - Sale completed by another user
3. Check notifications screen

**Expected Results:**
- ✅ Notification badge updates within 1-2 seconds
- ✅ Notification appears in list immediately
- ✅ Sound/vibration alert (if enabled)
- ✅ Banner notification displays
- ✅ "LIVE SYNC" indicator active

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

#### TC-EMP-014: Notification Read Status Sync
**Objective:** Verify read/unread status syncs across sessions

**Test Steps:**
1. View unread notifications on Device A (count: 5)
2. Mark 2 as read
3. Check notification count and list
4. Log out and log back in
5. Verify count is correct (3 unread)

**Expected Results:**
- ✅ Count updates immediately after marking read
- ✅ Status persists across sessions
- ✅ Unread filter works correctly

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

## 🟢 MANAGER ROLE - Real-Time Test Cases

### **6. MANAGER DASHBOARD - Real-Time Updates**

#### TC-MGR-001: Advanced Metrics Live Sync
**Objective:** Verify manager dashboard metrics update in real-time

**Preconditions:**
- Manager logged in on Device B
- Employees active on other devices

**Test Steps:**
1. Note current metrics (revenue, transactions, avg order value)
2. Have employees on Device A & C complete multiple sales
3. Observe metrics on Device B

**Expected Results:**
- ✅ Total Revenue updates within 2-3 seconds
- ✅ Transaction count increases
- ✅ Average Order Value recalculates
- ✅ Payment breakdown updates (Cash, UPI, Card percentages)
- ✅ Store comparison chart updates (if multi-store)
- ✅ "LIVE SYNC" badge active with timestamp

**Test Data:**
- Sale 1: ₹1,000 (Cash)
- Sale 2: ₹2,500 (UPI)
- Sale 3: ₹800 (Card)

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

#### TC-MGR-002: Team Performance Live Update
**Objective:** Verify team metrics update as employees make sales

**Test Steps:**
1. Open team performance widget
2. Note current employee sales counts
3. Have Employee A complete 2 sales
4. Have Employee B complete 1 sale
5. Check performance rankings

**Expected Results:**
- ✅ Individual employee sale counts update
- ✅ Rankings reorder if needed
- ✅ Employee of the day updates
- ✅ Graphs/charts refresh

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

#### TC-MGR-003: Real-Time Revenue Charts
**Objective:** Verify revenue charts update with live data

**Test Steps:**
1. View hourly/daily revenue chart
2. Complete sales during current time period
3. Observe chart updates

**Expected Results:**
- ✅ Current period bar/line increases
- ✅ Chart animates smoothly
- ✅ Tooltips show updated values
- ✅ Y-axis scales if needed

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### **7. REPORTS SCREEN - Real-Time Updates**

#### TC-MGR-004: Sales Report Live Sync
**Objective:** Verify sales reports update in real-time

**Test Steps:**
1. Open Reports screen, select "Today" filter
2. View Sales tab showing current summary
3. Have employees complete sales on other devices
4. Observe report updates

**Expected Results:**
- ✅ Total Sales figure updates
- ✅ Transaction count increases
- ✅ Top products list updates
- ✅ Category breakdown refreshes
- ✅ Hourly breakdown updates
- ✅ "Real-time Analytics • Today" badge visible

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

#### TC-MGR-005: Product Performance Live Ranking
**Objective:** Verify top products update as sales occur

**Test Steps:**
1. View Products tab in Reports
2. Note top 5 products and their quantities
3. Complete multiple sales of lower-ranked product
4. Check if rankings change

**Expected Results:**
- ✅ Quantities update in real-time
- ✅ Rankings reorder based on new data
- ✅ Revenue per product updates
- ✅ Charts/visualizations refresh

**Test Data:**
- Product A: 50 units sold (rank #3)
- Sell 30 more units of Product A
- Should move to rank #1 or #2

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

#### TC-MGR-006: Customer Insights Real-Time Update
**Objective:** Verify customer analytics update live

**Test Steps:**
1. Open Customers tab in Reports
2. View customer segments (VIP, Loyal, Regular, etc.)
3. Complete sales that change customer segments
4. Check segment counts and customer classifications

**Expected Results:**
- ✅ Segment counts update
- ✅ Customer moves to correct segment
- ✅ Top customers list reorders
- ✅ Average order value recalculates
- ✅ Loyalty points summary updates

**Test Scenario:**
- Customer "John" has 9 purchases (Loyal segment)
- Complete 1 more purchase for John
- John should move to different segment (if threshold is 10)

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### **8. CUSTOMER ANALYTICS - Real-Time Updates**

#### TC-MGR-007: Customer Growth Chart Live Update
**Objective:** Verify customer growth data updates in real-time

**Test Steps:**
1. Open Customer Analytics screen
2. View customer growth chart
3. Register new customers on other devices
4. Check chart updates

**Expected Results:**
- ✅ Customer count increases
- ✅ Chart data points update
- ✅ New customers appear in "Recent Customers" list
- ✅ Growth percentage recalculates

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

#### TC-MGR-008: Segmentation Live Analysis
**Objective:** Verify customer segmentation updates dynamically

**Test Steps:**
1. View Segments tab showing customer distribution
2. Complete sales that affect customer behavior:
   - Move Occasional → Regular (5+ purchases)
   - Move Regular → Loyal (10+ purchases)
   - Move Loyal → VIP (20+ purchases)
3. Check segment distribution

**Expected Results:**
- ✅ Segment counts update in real-time
- ✅ Pie chart/bar chart refreshes
- ✅ Customer cards show updated segments
- ✅ Percentage calculations update

**Segmentation Rules:**
- VIP: 20+ purchases OR ₹10,000+ spend
- Loyal: 10-19 purchases
- Regular: 5-9 purchases
- Occasional: 1-4 purchases
- At-Risk: No purchase in 60+ days

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

#### TC-MGR-009: Purchase Frequency Analysis Live
**Objective:** Verify purchase frequency updates in real-time

**Test Steps:**
1. View purchase frequency distribution
2. Complete various customer transactions
3. Check frequency chart updates

**Expected Results:**
- ✅ Frequency buckets update (1-2 orders, 3-5 orders, etc.)
- ✅ Customer count per bucket changes
- ✅ Percentages recalculate
- ✅ Progress bars animate to new values

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

#### TC-MGR-010: Top Customers Live Ranking
**Objective:** Verify top customers list updates as spending changes

**Test Steps:**
1. View Top Customers list (by spend)
2. Complete high-value sale for lower-ranked customer
3. Check if list reorders

**Expected Results:**
- ✅ Customer spend amounts update
- ✅ Rankings reorder correctly
- ✅ New customers appear if they qualify for top list
- ✅ Smooth animation during reorder

**Test Data:**
- Customer "Alice": ₹5,000 total (rank #5)
- Complete ₹3,000 sale for Alice
- Alice should move up in rankings

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### **9. INVENTORY MANAGEMENT - Real-Time Updates**

#### TC-MGR-011: Inventory Adjustments Sync
**Objective:** Verify inventory adjustments sync across all users

**Test Steps:**
1. Manager adjusts stock on Device B (Product K: +50 units)
2. Check Product K on Employee Device A
3. Another manager updates price on Device C
4. Check Product K on all devices

**Expected Results:**
- ✅ Stock adjustment reflects on all devices within 2 seconds
- ✅ Price update syncs to all users
- ✅ Adjustment history logs properly
- ✅ Last updated timestamp shows correctly

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

#### TC-MGR-012: Bulk Operations Sync
**Objective:** Verify bulk inventory operations sync correctly

**Test Steps:**
1. Manager performs bulk category update on 10 products
2. Check inventory list on employee device
3. Manager bulk updates prices by 10%
4. Verify on all devices

**Expected Results:**
- ✅ All 10 products update on all devices
- ✅ Updates complete within 5 seconds
- ✅ No partial updates (all or nothing)
- ✅ Notifications sent for bulk changes

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### **10. NOTIFICATIONS - Manager Specific**

#### TC-MGR-013: Manager-Level Notifications Sync
**Objective:** Verify manager receives appropriate real-time alerts

**Test Steps:**
1. Keep manager app open
2. Trigger manager-specific events:
   - Critical low stock (below critical threshold)
   - Large sale completed (above threshold)
   - Employee clocks in/out
   - End of day summary generated
3. Check notifications

**Expected Results:**
- ✅ Manager-level notifications arrive instantly
- ✅ Priority notifications highlighted
- ✅ Actionable notifications show action buttons
- ✅ Notification categories work (filter by type)

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

#### TC-MGR-014: Multi-Store Notifications
**Objective:** Verify multi-store managers receive updates from all stores

**Preconditions:**
- Manager has access to multiple stores

**Test Steps:**
1. Select "All Stores" in store filter
2. Have activity in Store A and Store B
3. Check notifications

**Expected Results:**
- ✅ Notifications from all stores appear
- ✅ Store name/badge visible on each notification
- ✅ Filter by store works correctly
- ✅ Counts show per-store breakdown

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

## 🔴 CROSS-ROLE TEST CASES

### **11. CONCURRENT OPERATIONS**

#### TC-CROSS-001: Concurrent Sale & Inventory View
**Objective:** Test real-time sync when multiple users access same data

**Test Steps:**
1. Employee A views inventory list
2. Manager B views same inventory list
3. Employee C completes sale reducing stock
4. Check both Device A and B

**Expected Results:**
- ✅ Both see stock reduction simultaneously
- ✅ No stale data displayed
- ✅ Updates within 2-3 seconds

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

#### TC-CROSS-002: Simultaneous Customer Updates
**Objective:** Test concurrent customer data updates

**Test Steps:**
1. Employee A has Customer X profile open
2. Manager B has same Customer X profile open
3. Employee C completes sale for Customer X
4. Check both profiles

**Expected Results:**
- ✅ Both see updated purchase history
- ✅ Both see updated loyalty points
- ✅ Both see updated total spend
- ✅ No conflicts or errors

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

#### TC-CROSS-003: Race Condition - Low Stock Warning
**Objective:** Test low stock alert when multiple users sell simultaneously

**Test Steps:**
1. Product has 5 units remaining (threshold: 10)
2. Employee A adds 3 units to cart
3. Employee B adds 3 units to cart (simultaneously)
4. Both complete sales

**Expected Results:**
- ✅ Both sales complete successfully
- ✅ Final stock is correct (-6 total)
- ✅ Low stock alert triggers for both
- ✅ No negative stock
- ✅ Both receive real-time sync updates

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

### **12. NETWORK & EDGE CASES**

#### TC-EDGE-001: Offline to Online Sync
**Objective:** Test sync when connection is restored

**Test Steps:**
1. Disable internet on Device A (Employee)
2. Complete sale offline (if supported)
3. Re-enable internet
4. Check data syncs to Device B (Manager)

**Expected Results:**
- ✅ Data syncs when online
- ✅ Manager sees offline transaction
- ✅ No data loss
- ✅ Sync indicator shows status

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

#### TC-EDGE-002: Slow Network Performance
**Objective:** Test real-time updates on slow connections

**Test Steps:**
1. Simulate 3G network on Device A
2. Complete actions (sale, update inventory)
3. Observe sync speed and behavior

**Expected Results:**
- ✅ Updates still sync (may be slower)
- ✅ Loading indicators appear
- ✅ No crashes or timeouts
- ✅ Data eventually consistent

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

#### TC-EDGE-003: High-Frequency Updates
**Objective:** Test system under high update frequency

**Test Steps:**
1. Simulate 10+ employees making sales simultaneously
2. Manager monitors dashboard in real-time
3. Check for lag or missed updates

**Expected Results:**
- ✅ All updates eventually appear
- ✅ UI remains responsive
- ✅ No duplicate data
- ✅ Counters accurate

**Status:** [ ] Pass [ ] Fail [ ] Blocked

---

## 🔧 PERFORMANCE BENCHMARKS

### Real-Time Sync Performance Targets

| Metric | Target | Acceptable | Poor |
|--------|--------|------------|------|
| **Dashboard Metrics Update** | < 2s | 2-5s | > 5s |
| **Inventory Stock Update** | < 2s | 2-4s | > 4s |
| **New Sale Appears in Feed** | < 2s | 2-3s | > 3s |
| **Notification Delivery** | < 1s | 1-2s | > 2s |
| **Customer Data Sync** | < 2s | 2-4s | > 4s |
| **Report Chart Update** | < 3s | 3-5s | > 5s |
| **Multi-device Consistency** | < 3s | 3-5s | > 5s |

---

## 📊 TEST EXECUTION SUMMARY

### Test Session Information
- **Tester Name:** _________________
- **Date:** _________________
- **App Version:** _________________
- **Devices Used:** _________________

### Results Summary

| Role | Total Tests | Passed | Failed | Blocked | Pass Rate |
|------|-------------|--------|--------|---------|-----------|
| **Employee** | 14 | | | | |
| **Manager** | 14 | | | | |
| **Cross-Role** | 6 | | | | |
| **TOTAL** | 34 | | | | |

---

## 🐛 DEFECTS LOG

| ID | Test Case | Severity | Description | Status |
|----|-----------|----------|-------------|--------|
| BUG-001 | | | | |
| BUG-002 | | | | |
| BUG-003 | | | | |

**Severity Levels:**
- **Critical:** App crashes, data loss, security issues
- **High:** Feature doesn't work, major functional impact
- **Medium:** Feature works but with issues, workaround available
- **Low:** Cosmetic issues, minor inconvenience

---

## ✅ SIGN-OFF

### Testing Team
- **Tested By:** _________________ Date: _________
- **Reviewed By:** _________________ Date: _________
- **Approved By:** _________________ Date: _________

### Notes & Recommendations
_____________________________________________________________
_____________________________________________________________
_____________________________________________________________
_____________________________________________________________

---

## 📝 AUTOMATED TEST SCRIPTS

### Flutter Widget Test Example

```dart
testWidgets('Employee Dashboard - Real-time sale update', (WidgetTester tester) async {
  // Build dashboard
  await tester.pumpWidget(MyApp());
  await tester.pumpAndSettle();

  // Get initial sale count
  final initialCount = find.text('Total Sales: 10');
  expect(initialCount, findsOneWidget);

  // Simulate Firestore update
  await mockSalesStream.add(newSaleEvent);
  await tester.pump(Duration(seconds: 2));

  // Verify update
  expect(find.text('Total Sales: 11'), findsOneWidget);
  expect(find.byIcon(Icons.sync), findsOneWidget); // Live sync badge
});
```

---

**End of Test Cases Document**
