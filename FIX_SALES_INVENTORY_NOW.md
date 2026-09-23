# 🚨 FIX: Sales & Inventory Not Saving to Firestore

## The Problem
Sales and inventory updates execute without errors but don't save to Firestore.

## The Cause
Firebase Auth tokens are missing custom claims (`role` and `storeId`) required by your Firestore security rules.

## The Fix (5 Minutes)

### Step 1: Run the Custom Claims Script

```bash
cd /Users/aayushkamble/Desktop/store_invemtory_mamanagement
node set_custom_claims.js
```

**Expected Output:**
```
✅ Alex Johnson (owner@demo.com)
   Role: owner
   Store: None (owner/admin)

✅ Sarah Manager (manager@demo.com)
   Role: manager
   Store: store_dt_001

✅ Mike Employee (employee@demo.com)
   Role: employee
   Store: store_dt_001

✅ Successfully updated: 3 users
```

### Step 2: Sign Out and Sign In

**In your app:**
1. Sign out all current users
2. Sign in again with any account
3. Custom claims will now be in the token

### Step 3: Test Sales

1. Login as Employee
2. Go to POS screen
3. Add products to cart
4. Complete sale
5. ✅ Check Firestore Console → `sales` collection
6. ✅ Check `inventory` collection (stock should be reduced)
7. ✅ Check `stockMovements` collection (new entry)

---

## Verify It's Fixed

### In Browser Console (F12):
```javascript
firebase.auth().currentUser.getIdTokenResult().then(token => {
  console.log('Claims:', token.claims);
});
```

**Should show:**
```javascript
{
  role: "employee",          // ✅ Present
  storeId: "store_dt_001",  // ✅ Present
  // ... other standard claims
}
```

---

## If Script Fails

### Error: "Cannot find module 'firebase-admin'"

```bash
cd /Users/aayushkamble/Desktop/store_invemtory_mamanagement
npm install firebase-admin
node set_custom_claims.js
```

### Error: "No users found in Firestore"

Run the seed script first:
```bash
node create_demo_firebase_users.js
```

### Error: "Cannot find service account file"

Make sure this file exists:
```
/Users/aayushkamble/Desktop/store_invemtory_mamanagement/seed/store-inventory-sale-manage-firebase-adminsdk-fbsvc-2d3176b5ac.json
```

---

## Technical Explanation

Your Firestore rules check:
```javascript
function getUserRole() {
  return request.auth.token.role;  // Needs custom claim
}

function hasStoreAccess(storeId) {
  return isOwner() || getUserStoreId() == storeId;  // Needs storeId claim
}
```

Firebase Auth tokens don't have these by default. They must be set server-side using Admin SDK.

The script does this:
```javascript
await admin.auth().setCustomUserClaims(userId, {
  role: 'employee',
  storeId: 'store_dt_001'
});
```

---

## Permanent Solution

For production, deploy a Cloud Function that automatically sets claims when users are created:

**functions/index.js:**
```javascript
exports.setUserClaims = functions.firestore
  .document('users/{userId}')
  .onCreate(async (snap, context) => {
    const userData = snap.data();
    await admin.auth().setCustomUserClaims(context.params.userId, {
      role: userData.role,
      storeId: userData.assignedStoreId
    });
  });
```

**Deploy:**
```bash
firebase deploy --only functions
```

---

## Quick Checklist

- [ ] Run `node set_custom_claims.js`
- [ ] Script shows "✅ Successfully updated: X users"
- [ ] Sign out all users in app
- [ ] Sign in again
- [ ] Complete a test sale
- [ ] Verify sale in Firestore Console → `sales` collection
- [ ] Verify stock reduced in `inventory` collection
- [ ] Check for movement in `stockMovements` collection

---

## Still Not Working?

### Check Firestore Logs

Add to `sales_service.dart` completeSale():
```dart
try {
  await ref.set(sale.toFirestore());
  print('✅ Sale saved: ${sale.id}');
} catch (e) {
  print('❌ ERROR: $e');
  rethrow;
}
```

### Check Auth State

Add to `auth_service.dart` signIn():
```dart
final token = await user.getIdTokenResult(true);
print('Token claims: ${token.claims}');
```

### Enable Firestore Debug Logging

Add to `main.dart`:
```dart
if (kDebugMode) {
  FirebaseFirestore.setLoggingEnabled(true);
}
```

---

## Contact Info

If the issue persists after following these steps, check:
1. Firebase Console → Authentication → Users (verify users exist)
2. Firestore Console → users collection (verify role and assignedStoreId fields)
3. Browser console for permission-denied errors

See `SALES_INVENTORY_FIRESTORE_ISSUE.md` for detailed diagnosis.
