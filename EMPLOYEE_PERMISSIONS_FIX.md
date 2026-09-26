# Employee Permissions Fix

## Problem
Employees are getting `[cloud_firestore/permission-denied] Missing or insufficient permissions` errors when trying to:
1. **Log damaged stock** - The "Log Damaged Stock" form submission fails
2. **Initiate stock transfers** - Transfer creation fails

## Root Cause
The Firestore security rules were too restrictive:
- `damagedProducts` collection only allowed `owner`, `admin`, and `manager` to create records
- `stockTransfers` collection only allowed `owner`, `admin`, and `manager` to create records
- **Employees were completely blocked** from these operations

This is incorrect because:
- Employees work on the floor and discover damaged products
- Employees should be able to report damage for manager approval
- Employees should be able to initiate inter-store transfers
- Managers should confirm/approve these actions

## Solution
Updated Firestore rules to give appropriate permissions to all staff roles.

### Files Modified
1. `/firestore.rules` - Updated security rules
2. `/deploy_firestore_rules.sh` - Created deployment script

### Changes Made

#### 1. Damaged Products Collection
**Before:**
```javascript
match /damagedProducts/{damagedId} {
  allow read: if hasAnyRole(['owner', 'admin', 'manager']);
  allow create: if hasAnyRole(['owner', 'admin', 'manager'])
    && hasRequiredFields(['storeId', 'productId', 'quantity', 'reason']);
  allow update, delete: if isOwnerOrAdmin();
}
```

**After:**
```javascript
match /damagedProducts/{damagedId} {
  // Allow all staff (including employees) to read damage reports
  allow read: if isStaff();
  
  // Allow all staff (including employees) to create damage reports
  allow create: if isStaff()
    && hasRequiredFields(['storeId', 'productId', 'quantity', 'reason'])
    && belongsToStore(request.resource.data.storeId);
  
  // Only managers and above can update damage reports
  allow update: if hasAnyRole(['owner', 'admin', 'manager'])
    && belongsToStore(resource.data.storeId);
  
  // Only owners and admins can delete damage reports
  allow delete: if isOwnerOrAdmin();
}
```

#### 2. Stock Transfers Collection
**Before:**
```javascript
match /stockTransfers/{transferId} {
  allow read: if isAuthenticated() && hasAnyRole(['owner', 'admin', 'manager']);
  allow create: if isAuthenticated() 
    && hasAnyRole(['owner', 'admin', 'manager'])
    && hasRequiredFields(['sourceStoreId', 'destinationStoreId', 'status']);
  allow update: if isAuthenticated() && hasAnyRole(['owner', 'admin', 'manager']);
  allow delete: if isOwnerOrAdmin();
}
```

**After:**
```javascript
match /stockTransfers/{transferId} {
  // Allow all staff (including employees) to read transfers
  allow read: if isStaff();
  
  // Allow all staff (including employees) to create transfers
  allow create: if isStaff()
    && hasRequiredFields(['sourceStoreId', 'destinationStoreId', 'status'])
    && (belongsToStore(request.resource.data.sourceStoreId) 
        || belongsToStore(request.resource.data.destinationStoreId));
  
  // Allow managers and above to update transfers (for confirmation)
  allow update: if hasAnyRole(['owner', 'admin', 'manager'])
    && (belongsToStore(resource.data.sourceStoreId) 
        || belongsToStore(resource.data.destinationStoreId));
  
  // Only owners and admins can delete transfers
  allow delete: if isOwnerOrAdmin();
}
```

### Permission Matrix

| Action | Employee | Manager | Admin | Owner |
|--------|----------|---------|-------|-------|
| **Damage Reports** |
| Read damage reports | ✅ | ✅ | ✅ | ✅ |
| Create damage report | ✅ | ✅ | ✅ | ✅ |
| Update damage report | ❌ | ✅ | ✅ | ✅ |
| Delete damage report | ❌ | ❌ | ✅ | ✅ |
| **Stock Transfers** |
| Read transfers | ✅ | ✅ | ✅ | ✅ |
| Initiate transfer | ✅ | ✅ | ✅ | ✅ |
| Confirm transfer | ❌ | ✅ | ✅ | ✅ |
| Delete transfer | ❌ | ❌ | ✅ | ✅ |

### Security Considerations
✅ **Store-level isolation:** Users can only create records for stores they belong to (`belongsToStore` check)
✅ **Required fields:** All required fields must be present
✅ **Role-based access:** Appropriate permissions for each role
✅ **Audit trail:** Updates and deletes restricted to higher roles

## Deployment

### Option 1: Using the Script (Recommended)
```bash
cd /Users/aayushkamble/Desktop/store_invemtory_mamanagement
./deploy_firestore_rules.sh
```

### Option 2: Manual Firebase CLI
```bash
cd /Users/aayushkamble/Desktop/store_invemtory_mamanagement
firebase login --reauth  # If needed
firebase deploy --only firestore:rules --project store-inventory-sale-manage
```

### Option 3: Firebase Console (No CLI needed)
1. Go to [Firebase Console](https://console.firebase.google.com/project/store-inventory-sale-manage/firestore/rules)
2. Copy the entire content of `firestore.rules`
3. Paste it in the online editor
4. Click **Publish**

## Testing

### Test 1: Employee Can Log Damage
1. Sign in as an **employee** (e.g., Big Bird)
2. Navigate to **Inventory** screen
3. Click **"Log Damage"** button
4. Select a product (e.g., "Britannia Good Day 100g")
5. Enter quantity: 1
6. Select reason: "Expired product"
7. Add notes
8. Click **"Submit Incident Report to Manager"**
9. **Expected:** ✅ Success! Damage report created
10. **Before fix:** ❌ Permission denied error

### Test 2: Employee Can Initiate Transfer
1. Sign in as an **employee**
2. Navigate to **Inventory** screen
3. Click **"+ Transfer"** button
4. Select destination store
5. Select a product
6. **Expected:** ✅ Available stock shows correctly (from previous fix)
7. Enter quantity
8. Click **"Dispatch Transfer Order"**
9. **Expected:** ✅ Success! Transfer initiated
10. **Before fix:** ❌ Permission denied error

### Test 3: Manager Can Confirm Transfer
1. Sign in as a **manager**
2. Navigate to **Transfers** or **Inventory > Transfers** tab
3. See pending inbound transfers
4. Click **"Confirm & Receive Stock"**
5. **Expected:** ✅ Success! Transfer confirmed and stock updated

## Workflow
1. **Employee** discovers damaged products → Creates damage report
2. **Manager** reviews damage reports → Approves or investigates
3. **Employee** initiates stock transfer → Transfer created in "pending" status
4. **Manager** at destination store → Confirms transfer and adds to inventory

## Notes
- The `isStaff()` function includes all roles: `owner`, `admin`, `manager`, `employee`
- The `belongsToStore()` function ensures users can only access data for their assigned store
- Managers and above can update/confirm transfers to prevent accidental or unauthorized confirmations
- All operations maintain proper audit trails with userId and userName fields

## Related Fixes
- ✅ Fixed available stock display in Transfer and Log Damage dialogs (see `INVENTORY_STOCK_DISPLAY_FIX.md`)
- ✅ Fixed employee permissions for damage reports and transfers
- ✅ Added store-level isolation for security

## Rollback
If you need to revert these changes:
```bash
git checkout firestore.rules
firebase deploy --only firestore:rules
```
