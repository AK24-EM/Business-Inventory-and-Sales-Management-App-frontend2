# ⚡ QUICK FIX: Inventory Showing Zero

## Problem
Inventory screen shows "0" stock for all products

## Root Cause
**No data in Firestore `inventory` collection**

---

## ⚡ FASTEST FIX (2 minutes)

### Step 1: Open Firebase Console
https://console.firebase.google.com/project/store-inventory-sale-manage/firestore

### Step 2: Create Inventory Document

Click **Start Collection** → Enter: `inventory`

**Add First Document:**
- Document ID: `inv_store_01_p01`

**Fields:**
```
storeId: store_01
productId: p01
productName: Tata Salt 1kg
category: Groceries
currentStock: 150
minimumStockLevel: 20
maximumStockLevel: 200
lastUpdated: [Click "Set to current time"]
```

### Step 3: Refresh App
- Close and reopen app
- Stock should appear!

---

## 📋 Quick Copy-Paste (10 Products)

### Product 1: Tata Salt (Normal Stock)
```
inv_store_01_p01
storeId: store_01 | productId: p01
productName: Tata Salt 1kg | category: Groceries
currentStock: 150 | minimumStockLevel: 20
```

### Product 2: Amul Butter (Normal Stock)
```
inv_store_01_p02
storeId: store_01 | productId: p02
productName: Amul Butter 100g | category: Dairy
currentStock: 80 | minimumStockLevel: 20
```

### Product 3: Aashirvaad Atta (LOW STOCK)
```
inv_store_01_p03
storeId: store_01 | productId: p03
productName: Aashirvaad Atta 5kg | category: Groceries
currentStock: 8 | minimumStockLevel: 20
```

### Product 4: Britannia (Normal Stock)
```
inv_store_01_p04
storeId: store_01 | productId: p04
productName: Britannia Good Day 100g | category: Snacks
currentStock: 65 | minimumStockLevel: 25
```

### Product 5: Lays (LOW STOCK)
```
inv_store_01_p05
storeId: store_01 | productId: p05
productName: Lays Classic 75g | category: Snacks
currentStock: 5 | minimumStockLevel: 25
```

### Product 6: Coca-Cola (Normal Stock)
```
inv_store_01_p06
storeId: store_01 | productId: p06
productName: Coca-Cola 2L | category: Beverages
currentStock: 120 | minimumStockLevel: 30
```

### Product 7: Maggi (Normal Stock)
```
inv_store_01_p07
storeId: store_01 | productId: p07
productName: Maggi Noodles 70g | category: Instant Food
currentStock: 200 | minimumStockLevel: 50
```

### Product 8: Mother Dairy (LOW STOCK)
```
inv_store_01_p08
storeId: store_01 | productId: p08
productName: Mother Dairy Milk 1L | category: Dairy
currentStock: 3 | minimumStockLevel: 20
```

### Product 9: Parle-G (OUT OF STOCK)
```
inv_store_01_p09
storeId: store_01 | productId: p09
productName: Parle-G Biscuits 200g | category: Snacks
currentStock: 0 | minimumStockLevel: 30
```

### Product 10: Surf Excel (Normal Stock)
```
inv_store_01_p10
storeId: store_01 | productId: p10
productName: Surf Excel 1kg | category: Household
currentStock: 45 | minimumStockLevel: 15
```

---

## ✅ Expected Result

After adding these 10 items:
- ✅ **Store Sales: 10**
- ✅ **Low Stock: 3** (Aashirvaad, Lays, Mother Dairy)
- ✅ **Out of Stock: 1** (Parle-G)
- ✅ Real-time sync working

---

## 🔗 More Options

**Complete Guide:** `INVENTORY_ZERO_STOCK_FIX.md`

**Automated Seed:** `python3 seed/seed_inventory_rest.py`

**Node Script:** `node seed/seed_inventory.js` (may timeout)

---

**Time:** 2-10 minutes | **Priority:** HIGH | **Impact:** Unblocks all inventory features
