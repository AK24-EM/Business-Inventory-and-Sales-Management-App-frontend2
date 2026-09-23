# Festival Debug Guide

## 🔍 Step-by-Step Debugging

### Step 1: Check Console Logs
When you add a festival, watch the console (F12 → Console) for these messages:

```
✓ "Saving festival: [name] with ID: [id]"
✓ "Festival data: {map of data}"
✓ "Festival saved successfully"
✓ "Festivals StreamBuilder state: ConnectionState.active"
✓ "Loaded X festivals"
✓ "Festival: [name], isActive: true, startDate: [date]"
```

**If you see errors instead**, note the exact error message.

---

### Step 2: Verify Firestore Security Rules

**Check Current Rules:**
```bash
firebase firestore:rules:get
```

**Expected Rule for Festivals:**
```javascript
match /festivals/{festivalId} {
  allow read: if request.auth != null;
  allow write: if request.auth != null && 
                  request.auth.token.role in ['owner', 'admin'];
}
```

**Deploy Rules:**
```bash
cd /Users/aayushkamble/Desktop/store_invemtory_mamanagement
firebase deploy --only firestore:rules
```

---

### Step 3: Check Firestore Index

The query requires a composite index: `isActive` + `startDate`

**Check if index exists:**
1. Go to Firebase Console
2. Click Firestore Database
3. Go to "Indexes" tab
4. Look for: `festivals` collection with fields `isActive (Ascending)` and `startDate (Ascending)`

**If missing, deploy:**
```bash
firebase deploy --only firestore:indexes
```

**Wait 5-10 minutes** for index to build (status shows "Building..." → "Enabled")

---

### Step 4: Manual Test in Firebase Console

**Add Festival Manually:**
1. Go to Firebase Console → Firestore Database
2. Click "Start collection" or open `festivals` collection
3. Click "Add document"
4. Document ID: (auto-generate)
5. Add fields:
```javascript
name (string): "Test Festival"
startDate (timestamp): Tomorrow's date
endDate (timestamp): Tomorrow + 3 days
isActive (boolean): true
advanceOrderDays (number): 14
createdAt (timestamp): Current timestamp
```
6. Click "Save"
7. **Go back to app** and check if it appears

---

### Step 5: Test Direct Firestore Query

Open browser console and run:

```javascript
// Get Firebase instance
const db = firebase.firestore();

// Test query (same as app uses)
db.collection('festivals')
  .where('isActive', '==', true)
  .orderBy('startDate')
  .get()
  .then(snapshot => {
    console.log(`Found ${snapshot.docs.length} festivals:`);
    snapshot.docs.forEach(doc => {
      console.log('ID:', doc.id);
      console.log('Data:', doc.data());
    });
  })
  .catch(error => {
    console.error('Query error:', error.code, error.message);
  });
```

**Expected Output:**
```
Found 1 festivals:
ID: abc123...
Data: {name: "Test Festival", startDate: Timestamp(...), ...}
```

**If error:**
- `permission-denied` → Deploy rules
- `failed-precondition` → Deploy indexes and wait

---

### Step 6: Check User Authentication

```javascript
// Check if user is authenticated
firebase.auth().onAuthStateChanged(user => {
  if (user) {
    user.getIdTokenResult().then(token => {
      console.log('User role:', token.claims.role);
      console.log('Is owner:', token.claims.role === 'owner');
    });
  } else {
    console.log('Not logged in');
  }
});
```

**Must show:**
- User logged in
- Role is "owner"

---

### Step 7: Test Festival Creation Step-by-Step

**1. Open festival screen**
- Console should show: "Festivals StreamBuilder state: ConnectionState.active"

**2. Click "Add Event"**
- Modal opens

**3. Fill in form:**
- Name: "Debug Test"
- Start Date: Select tomorrow
- End Date: Select day after tomorrow
- Advance Days: 14

**4. Click "Add Festival"**
- Console should show:
  ```
  Saving festival: Debug Test with ID: [some-id]
  Festival data: {name: Debug Test, ...}
  Festival saved successfully
  ```
- Success toast appears: "✓ Festival 'Debug Test' added successfully"

**5. Check list immediately:**
- Console should show:
  ```
  Festivals StreamBuilder state: ConnectionState.active
  Loaded 1 festivals
  Festival: Debug Test, isActive: true, startDate: [date]
  ```
- Festival card appears in list

---

### Step 8: Common Issues & Solutions

#### Issue: "permission-denied"
**Cause**: Firestore rules not allowing read/write
**Solution:**
```bash
firebase deploy --only firestore:rules
# Wait 10 seconds
# Refresh app
```

#### Issue: "failed-precondition: The query requires an index"
**Cause**: Composite index not built
**Solution:**
```bash
firebase deploy --only firestore:indexes
# Wait 5-10 minutes for index to build
# Check Firebase Console → Firestore → Indexes tab
# Refresh app when index status is "Enabled"
```

#### Issue: Festival saves but doesn't appear
**Causes:**
1. Index not ready → Wait for index to build
2. Wrong isActive value → Should be `true` (boolean)
3. Query not matching → Check console logs

**Debug:**
```javascript
// Check what's actually saved
db.collection('festivals').get().then(snap => {
  console.log('Total festivals (no filter):', snap.docs.length);
  snap.docs.forEach(doc => {
    const data = doc.data();
    console.log(`${doc.id}: isActive=${data.isActive}, name=${data.name}`);
  });
});
```

#### Issue: "Festival added" but no document in Firestore
**Cause**: Write permission denied silently
**Solution:**
1. Check user role: Must be "owner"
2. Deploy rules: `firebase deploy --only firestore:rules`
3. Try manual add in Firebase Console to test permissions

---

### Step 9: Force Refresh

If festival is in Firestore but not showing:

**1. Hard refresh app:**
```dart
// Or just press Ctrl+Shift+R in browser
```

**2. Clear Flutter cache:**
```bash
flutter clean
flutter pub get
flutter run
```

**3. Check if StreamBuilder is listening:**
- Look for console log: "Festivals StreamBuilder state: ConnectionState.active"
- Should see "Loaded X festivals" every time data changes

---

### Step 10: Minimal Test

**Quick working test:**

1. Deploy rules and indexes:
```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

2. Wait 10 minutes for indexes

3. Add festival via Firebase Console (not app)

4. Refresh app

5. Should appear immediately

**If this works:** App's save logic needs fixing
**If this doesn't work:** Query/rules/index issue

---

## 🐛 Expected Console Output (Success)

```
Saving festival: Test Festival with ID: xyz789abc
Festival data: {name: Test Festival, startDate: Timestamp(...), endDate: Timestamp(...), isActive: true, advanceOrderDays: 14, createdAt: Timestamp(...)}
Festival saved successfully
---
Festivals StreamBuilder state: ConnectionState.active
Loaded 1 festivals
Festival: Test Festival, isActive: true, startDate: 2024-12-25 00:00:00.000
```

## ❌ Error Patterns

### Pattern 1: Permission Denied
```
Error loading festivals: [firebase_firestore/permission-denied]
```
**Fix**: Deploy rules

### Pattern 2: Index Required
```
Error loading festivals: [firebase_firestore/failed-precondition] The query requires an index
```
**Fix**: Deploy indexes and wait

### Pattern 3: Silent Failure
```
Saving festival: Test with ID: abc123
(no "Festival saved successfully" message)
```
**Fix**: Check browser console for actual error

---

## ✅ Success Checklist

- [ ] Rules deployed successfully
- [ ] Indexes deployed and showing "Enabled" status
- [ ] User authenticated as "owner"
- [ ] Festival form submits without errors
- [ ] Console shows "Festival saved successfully"
- [ ] Console shows "Loaded X festivals" (X > 0)
- [ ] Festival card appears in list
- [ ] Can see festival in Firebase Console
- [ ] Refresh app still shows festival

---

## 🚀 Quick Fix (Most Common Issue)

**90% of the time, the issue is:**
1. Index not built yet

**Solution:**
```bash
# 1. Deploy indexes
firebase deploy --only firestore:indexes

# 2. Check index status in Firebase Console
# Go to: Firestore → Indexes tab
# Look for: festivals (isActive, startDate)
# Wait for status: "Enabled" (green checkmark)

# 3. Refresh app
# Press Ctrl+R or Cmd+R

# 4. Try adding festival again
```

---

**Status**: Enhanced debugging and logging added  
**Next**: Follow steps above to identify exact issue
