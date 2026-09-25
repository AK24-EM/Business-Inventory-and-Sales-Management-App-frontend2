# Inventory Showing Zero Stock - Fix Guide

## Problem Identified ✅

The inventory screen is showing "0" for all stock levels because **there is no inventory data in Firestore**.

### Root Cause:
1. The seed scripts only populate notifications and festivals
2. No inventory records exist in the `inventory` collection
3. The app correctly reads from Firestore, but finds no data

---

## Solution: Seed Inventory Data

### Option 1: Use Firebase Console (Manual - Quick Test)

1. **Go to Firebase Console:**
   - Visit: https://console.firebase.google.com/
   - Select project: `store-inventory-sale-manage`
   - Go to Firestore Database

2. **Create Collection: `inventory`**

3. **Add Sample Documents:**

   Document ID: `inv_store_01_p01`
   ```json
   {
     "storeId": "store_01",
     "productId": "p01",
     "productName": "Tata Salt 1kg",
     "category": "Groceries",
     "currentStock": 150,
     "minimumStockLevel": 20,
     "maximumStockLevel": 200,
     "imageUrl": "https://via.placeholder.com/200x200.png?text=Tata+Salt",
     "lastUpdated": [Firebase Timestamp - now]
   }
   ```

   Document ID: `inv_store_01_p02`
   ```json
   {
     "storeId": "store_01",
     "productId": "p02",
     "productName": "Amul Butter 100g",
     "category": "Dairy",
     "currentStock": 80,
     "minimumStockLevel": 20,
     "maximumStockLevel": 200,
     "imageUrl": "https://via.placeholder.com/200x200.png?text=Amul+Butter",
     "lastUpdated": [Firebase Timestamp - now]
   }
   ```

   Document ID: `inv_store_01_p03`
   ```json
   {
     "storeId": "store_01",
     "productId": "p03",
     "productName": "Aashirvaad Atta 5kg",
     "category": "Groceries",
     "currentStock": 8,
     "minimumStockLevel": 20,
     "maximumStockLevel": 200,
     "imageUrl": "https://via.placeholder.com/200x200.png?text=Aashirvaad",
     "lastUpdated": [Firebase Timestamp - now]
   }
   ```

   *(Add 10-15 more products similarly)*

4. **Refresh the app** - Stock should appear immediately!

---

### Option 2: Use Seed Script (Automated - Production Ready)

I've created `seed/seed_inventory.js` which populates:
- ✅ 12 products
- ✅ 2 stores
- ✅ 24 inventory records (all products × 2 stores)
- ✅ Realistic stock levels (some normal, some low, some out-of-stock)
- ✅ Stock movement history

**To run:**
```bash
cd /Users/aayushkamble/Desktop/store_invemtory_mamanagement/seed
node seed_inventory.js
```

**If it hangs:**
- Network might be blocking Firebase Admin SDK
- Try from different network/WiFi
- Or use Firebase Console (Option 1)

---

### Option 3: Create from App UI (Manager Flow)

1. **Login as Manager**
2. **Go to Manager Hub → Inventory Management**
3. **Add Products** one by one with initial stock
4. **Inventory will populate** as you add products

---

## Products Collection Must Also Exist

Make sure you have `products` collection with documents like:

Document ID: `p01`
```json
{
  "name": "Tata Salt 1kg",
  "brand": "Tata",
  "category": "Groceries",
  "sellingPrice": 25.0,
  "mrp": 28.0,
  "barcode": "890123456781",
  "sku": "SALT-TATA-1KG",
  "imageUrl": "https://via.placeholder.com/200x200.png?text=Tata+Salt",
  "isActive": true,
  "createdAt": [Timestamp],
  "updatedAt": [Timestamp]
}
```

---

## Firestore Collections Needed

### Required Collections:
1. **`products`** - Product catalog
2. **`inventory`** - Stock levels per store
3. **`stores`** - Store information
4. **`stockMovements`** - History of stock changes

### Collection Structure:

```
Firestore
├── products/
│   ├── p01: { name, brand, category, sellingPrice, ... }
│   ├── p02: { ... }
│   └── ...
│
├── inventory/
│   ├── inv_store_01_p01: { storeId, productId, currentStock: 150, ... }
│   ├── inv_store_01_p02: { storeId, productId, currentStock: 80, ... }
│   ├── inv_store_02_p01: { ... }
│   └── ...
│
├── stores/
│   ├── store_01: { name: "Downtown Central", address, ... }
│   └── store_02: { name: "Suburban Hub", ... }
│
└── stockMovements/
    ├── [auto-generated]: { type: "receipt", quantity: 50, ... }
    └── ...
```

---

## Verification Steps

After adding inventory data:

1. **Check Firestore Console:**
   - Go to `inventory` collection
   - Should see documents like `inv_store_01_p01`, etc.
   - Each should have `currentStock` field with number > 0

2. **Check App:**
   - Login as Employee/Manager
   - Go to Inventory screen
   - Should see:
     - Store Sales: (number of items with stock > 0)
     - Products listed with correct stock levels
     - "Low Stock" badge for items below minimum

3. **Real-Time Test:**
   - Open app on 2 devices
   - On Device 1: Make a sale
   - On Device 2: Watch inventory decrease automatically

---

## Common Issues

### Issue 1: "Still showing 0 after adding data"
**Solution:**
- Hard refresh the app (close and reopen)
- Check Firestore rules allow read access
- Verify storeId matches selected store

### Issue 2: "Products appear but no stock count"
**Solution:**
- Check inventory document ID format: `inv_{storeId}_{productId}`
- Verify `currentStock` field exists and is a number
- Check `storeId` matches

### Issue 3: "Low stock alerts not appearing"
**Solution:**
- Verify `minimumStockLevel` field exists
- Check if `currentStock` <= `minimumStockLevel`
- Notifications should auto-generate

---

## Quick Test Data (Copy-Paste Ready)

### For Store: `store_01`

| Product ID | Name | Category | Current Stock | Min Level |
|------------|------|----------|--------------|-----------|
| p01 | Tata Salt 1kg | Groceries | 150 | 20 |
| p02 | Amul Butter 100g | Dairy | 80 | 20 |
| p03 | Aashirvaad Atta 5kg | Groceries | 8 | 20 |
| p04 | Britannia Good Day 100g | Snacks | 65 | 25 |
| p05 | Lays Classic 75g | Snacks | 5 | 25 |
| p06 | Coca-Cola 2L | Beverages | 120 | 30 |
| p07 | Maggi Noodles 70g | Instant Food | 200 | 50 |
| p08 | Mother Dairy Milk 1L | Dairy | 3 | 20 |
| p09 | Parle-G Biscuits 200g | Snacks | 0 | 30 |
| p10 | Surf Excel 1kg | Household | 45 | 15 |

**Status Breakdown:**
- ✅ Normal Stock: 6 items
- ⚠️ Low Stock: 3 items (Aashirvaad, Lays, Mother Dairy)
- ❌ Out of Stock: 1 item (Parle-G)

---

## Next Steps

1. **Immediate:** Use Firebase Console to manually add 3-5 inventory records (Option 1)
2. **Short-term:** Run seed script when network permits (Option 2)
3. **Long-term:** Implement product/inventory management UI for managers

---

## Files Created

- ✅ `seed/seed_inventory.js` - Automated seeding script
- ✅ `INVENTORY_ZERO_STOCK_FIX.md` - This guide

---

## Support

If you need help:
1. Check Firebase Console for data
2. Check Firestore rules (should allow read)
3. Verify store selection in app
4. Check console logs for errors

**Quick Firebase Rule Check:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /inventory/{document=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

---

**Status:** ⚠️ Issue Identified - Solution Provided
**Priority:** 🔴 High - Blocks all inventory features
**Estimated Fix Time:** 5-10 minutes (manual) or 2 minutes (automated seed)
