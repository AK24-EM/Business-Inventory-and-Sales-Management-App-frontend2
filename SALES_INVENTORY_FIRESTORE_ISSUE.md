# Sales & Inventory Firestore Write Issue - Diagnosis & Fix

## Problem
Sales and inventory updates are not being saved to Firestore even though the code executes without errors.

## Root Cause
**Firebase Authentication Custom Claims Not Set**

Your Firestore security rules require custom claims (`role` and `storeId`) on the user's Firebase Auth token:

```javascript
// From firestore.rules
function getUserRole() {
  return request.auth.token.role;  // ❌ This is null/undefined
}

function getUserStoreId() {
  return request.auth.token.storeId;  // ❌ This is null/undefined
}

// Sales write rule
match /sales/{saleId} {
  allow create: if isAuthenticated() && hasStoreAccess(request.resource.data.storeId);
  // This checks if getUserStoreId() == storeId, which fails if token.storeId is not set
}
```

When a user signs in, Firebase Auth creates a JWT token. By default, this token only contains:
- `uid` (user ID)
- `email`
- `email_verified`

It does **NOT** contain `role` or `storeId` unless you explicitly set them using Firebase Admin SDK.

## How to Verify the Issue

### Check User Token in Browser Console

1. Run your Flutter web app
2. Open browser DevTools (F12)
3. In Console, paste:
```javascript
firebase.auth().currentUser.getIdTokenResult().then(token => {
  console.log('Custom Claims:', token.claims);
});
```

**Expected output if claims are missing:**
```javascript
Custom Claims: {
  iss: "...",
  aud: "...",
  sub: "...",
  email: "owner@demo.com",
  // ❌ NO "role" or "storeId" properties
}
```

**Expected output if claims are set correctly:**
```javascript
Custom Claims: {
  // ... other standard claims ...
  role: "employee",          // ✅ Present
  storeId: "store_dt_001"   // ✅ Present
}
```

### Check Firestore Write Errors

Add error logging in `sales_service.dart`:

```dart
Future<SaleModel> completeSale({...}) async {
  try {
    // ... existing code ...
    await ref.set(sale.toFirestore());
    print('✅ Sale saved: ${sale.id}');
  } catch (e) {
    print('❌ Sale save failed: $e');
    rethrow;
  }
}
```

If custom claims are missing, you'll see:
```
❌ Sale save failed: [cloud_firestore/permission-denied] 
   Missing or insufficient permissions.
```

---

## Solution Options

### Option 1: Set Custom Claims via Node.js Script (Quickest)

Create a script to set claims for existing users:

**File:** `set_custom_claims.js`
```javascript
const admin = require('firebase-admin');
const serviceAccount = require('./seed/store-inventory-sale-manage-firebase-adminsdk-fbsvc-2d3176b5ac.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const auth = admin.auth();

async function setCustomClaims() {
  try {
    // Get all users from Firestore
    const usersSnapshot = await db.collection('users').get();
    
    for (const doc of usersSnapshot.docs) {
      const userData = doc.data();
      const uid = doc.id;
      
      const customClaims = {
        role: userData.role || 'employee',
        storeId: userData.assignedStoreId || null
      };
      
      await auth.setCustomUserClaims(uid, customClaims);
      console.log(`✅ Set claims for ${userData.email}:`, customClaims);
    }
    
    console.log('\n✅ All custom claims updated!');
    console.log('⚠️  Users must sign out and sign in again for claims to take effect.');
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

setCustomClaims();
```

**Run:**
```bash
cd /Users/aayushkamble/Desktop/store_invemtory_mamanagement
npm install firebase-admin
node set_custom_claims.js
```

**Important:** After running this, all users must **sign out and sign in again** for the new claims to be applied to their tokens.

---

### Option 2: Create Cloud Function (Production Solution)

Deploy a Cloud Function that automatically sets claims when users are created:

**File:** `functions/index.js`
```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Trigger when a new user document is created
exports.setUserClaims = functions.firestore
  .document('users/{userId}')
  .onCreate(async (snap, context) => {
    const userData = snap.data();
    const userId = context.params.userId;
    
    const customClaims = {
      role: userData.role || 'employee',
      storeId: userData.assignedStoreId || null
    };
    
    try {
      await admin.auth().setCustomUserClaims(userId, customClaims);
      console.log(`Custom claims set for user ${userId}:`, customClaims);
    } catch (error) {
      console.error('Error setting custom claims:', error);
    }
  });

// Trigger when user document is updated
exports.updateUserClaims = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const userId = context.params.userId;
    
    const customClaims = {
      role: newData.role || 'employee',
      storeId: newData.assignedStoreId || null
    };
    
    try {
      await admin.auth().setCustomUserClaims(userId, customClaims);
      console.log(`Custom claims updated for user ${userId}:`, customClaims);
    } catch (error) {
      console.error('Error updating custom claims:', error);
    }
  });
```

**Deploy:**
```bash
cd /Users/aayushkamble/Desktop/store_invemtory_mamanagement
firebase deploy --only functions
```

---

### Option 3: Temporary Fix - Relax Security Rules (Development Only)

**⚠️ WARNING: Only use this for testing. DO NOT use in production!**

Temporarily relax rules to allow writes without custom claims:

**File:** `firestore.rules`
```javascript
// TEMPORARY - for testing only
match /sales/{saleId} {
  allow read: if isAuthenticated();
  allow create: if isAuthenticated();  // ✅ Allows any authenticated user
  allow update, delete: if isOwner() || isManager();
}

match /inventory/{inventoryId} {
  allow read: if isAuthenticated();
  allow write: if isAuthenticated();  // ✅ Allows any authenticated user
}

match /stockMovements/{movementId} {
  allow read: if isAuthenticated();
  allow create: if isAuthenticated();  // ✅ Allows any authenticated user
  allow update, delete: if isOwner() || isManager();
}
```

**Deploy:**
```bash
firebase deploy --only firestore:rules
```

**After testing, revert to proper rules!**

---

## Recommended Fix Steps

### Step 1: Set Claims for Existing Users
```bash
cd /Users/aayushkamble/Desktop/store_invemtory_mamanagement
node set_custom_claims.js
```

### Step 2: Force Token Refresh in App

Update `auth_service.dart` to force token refresh on sign-in:

```dart
Future<UserModel?> signIn(String email, String password) async {
  final credential = await _firebaseAuth.signInWithEmailAndPassword(
    email: email.trim(),
    password: password,
  );
  final user = credential.user;
  if (user == null) throw Exception('sign-in-failed');

  // Fetch user record
  final model = await _fetchUserModel(user);
  if (model == null) throw Exception('user-record-not-found');
  if (!model.isActive) {
    await _firebaseAuth.signOut();
    throw Exception('user-disabled');
  }

  // ✅ Force-refresh token to get latest custom claims
  await user.getIdToken(true);
  
  // ✅ Wait a moment for claims to propagate
  await Future.delayed(const Duration(milliseconds: 500));
  
  // ✅ Verify claims are present (for debugging)
  final token = await user.getIdTokenResult(true);
  print('User claims: ${token.claims}');
  
  _updateLastLogin(user.uid);
  _userController.add(model);
  return model;
}
```

### Step 3: Test

1. **Sign out all users** in the app
2. **Sign in again** (this will get fresh token with claims)
3. Try creating a sale:
   - Add products to cart
   - Complete sale
   - Check Firestore Console → `sales` collection
   - Should see new sale document

4. Check inventory:
   - Firestore Console → `inventory` collection
   - `currentStock` should be reduced
   - Check `stockMovements` collection
   - Should see new movement record

---

## Verification Checklist

After applying the fix:

- [ ] Run `set_custom_claims.js` script
- [ ] All users sign out
- [ ] All users sign in again
- [ ] Check browser console for "User claims: {role: ..., storeId: ...}"
- [ ] Complete a test sale
- [ ] Verify sale appears in Firestore `sales` collection
- [ ] Verify `stockMovements` collection has new entry
- [ ] Verify `inventory` collection shows reduced stock
- [ ] Check for any permission errors in browser console

---

## Additional Debugging

### Enable Firestore Debug Logging

Add to `main.dart`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // ✅ Enable Firestore logging
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  
  if (kDebugMode) {
    FirebaseFirestore.setLoggingEnabled(true);
  }
  
  runApp(const MyApp());
}
```

### Check Firestore Console Directly

1. Go to Firebase Console → Firestore Database
2. Manually add a test sale document:
```json
{
  "storeId": "store_dt_001",
  "storeName": "Downtown Central",
  "totalAmount": 100,
  "timestamp": <current timestamp>,
  "items": []
}
```
3. If this fails with permission error → Custom claims issue confirmed

---

## Why This Happened

Firebase Auth custom claims must be set **server-side** using:
- Firebase Admin SDK (Node.js, Python, etc.)
- Cloud Functions
- Backend server with Admin privileges

They **cannot** be set from the Flutter app directly for security reasons. Your app creates users via `createUserWithEmailAndPassword()`, but this only creates the Auth record, not the custom claims.

---

## Long-Term Solution

**Use Cloud Functions for all user creation:**

Instead of creating users from the app, create a callable Cloud Function:

```javascript
exports.createUser = functions.https.onCall(async (data, context) => {
  // Verify caller is owner/admin
  if (!context.auth || context.auth.token.role !== 'owner') {
    throw new functions.https.HttpsError('permission-denied', 'Only owners can create users');
  }
  
  const { email, password, name, role, storeId } = data;
  
  // Create auth user
  const userRecord = await admin.auth().createUser({
    email,
    password,
    displayName: name
  });
  
  // Set custom claims immediately
  await admin.auth().setCustomUserClaims(userRecord.uid, {
    role,
    storeId
  });
  
  // Create Firestore document
  await admin.firestore().collection('users').doc(userRecord.uid).set({
    name,
    email,
    role,
    assignedStoreId: storeId,
    isActive: true,
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });
  
  return { success: true, userId: userRecord.uid };
});
```

Call from Flutter:
```dart
final result = await FirebaseFunctions.instance
    .httpsCallable('createUser')
    .call({
      'email': email,
      'password': password,
      'name': name,
      'role': role.name,
      'storeId': storeId,
    });
```

---

## Summary

| Issue | Cause | Fix |
|-------|-------|-----|
| Sales not saving | Missing `role` claim | Run `set_custom_claims.js` |
| Inventory not updating | Missing `storeId` claim | Users must re-login |
| Permission denied errors | Token lacks custom claims | Force token refresh on login |

**Quick Fix:** Run the Node.js script, have all users sign out/in, and sales/inventory should work immediately.
