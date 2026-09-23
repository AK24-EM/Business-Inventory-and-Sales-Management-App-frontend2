# Firebase Deployment Checklist

## Pre-Deployment Verification

### 1. Check Firebase CLI Installation
```bash
firebase --version
# Expected: Firebase CLI v13.x.x or higher
```

If not installed:
```bash
npm install -g firebase-tools
firebase login
```

### 2. Verify Project Configuration
```bash
cd /Users/aayushkamble/Desktop/store_invemtory_mamanagement
cat .firebaserc
# Should show your project ID
```

If file doesn't exist or is empty, you'll need to initialize:
```bash
firebase use --add
# Select your project from the list
```

## Deployment Steps

### Step 1: Set Active Project
```bash
firebase use --add
```

**Expected Output:**
```
? Which project do you want to add? (Use arrow keys)
❯ your-project-name (your-project-id)
  other-project-name (other-project-id)
  
? What alias do you want to use for this project? (default)

✔ Added alias 'default' for project 'your-project-id'
```

**Verification:**
```bash
firebase use
# Should show: Active Project: your-project-id (your-project-name)
```

### Step 2: Deploy Firestore Rules
```bash
firebase deploy --only firestore:rules
```

**Expected Output:**
```
=== Deploying to 'your-project-id'...

i  deploying firestore
i  firestore: reading indexes from firestore.indexes.json...
i  cloud.firestore: checking firestore.rules for compilation errors...
✔  cloud.firestore: rules file firestore.rules compiled successfully
i  firestore: uploading rules firestore.rules...
✔  firestore: released rules firestore.rules to cloud.firestore

✔  Deploy complete!
```

**Verification:**
- Go to Firebase Console → Firestore Database → Rules tab
- Should see updated timestamp

### Step 3: Deploy Firestore Indexes
```bash
firebase deploy --only firestore:indexes
```

**Expected Output:**
```
=== Deploying to 'your-project-id'...

i  deploying firestore
i  firestore: reading indexes from firestore.indexes.json...
i  firestore: uploading indexes to cloud.firestore...
✔  firestore: deployed indexes in firestore.indexes.json successfully

✔  Deploy complete!

Note: Index creation may take several minutes to complete.
```

**Index Building Status:**
```
Building...  (0-5 minutes)
Enabling...  (5-10 minutes)
Enabled ✓    (Ready to use)
```

**Verification:**
1. Go to Firebase Console → Firestore Database → Indexes tab
2. Look for:
   - Collection: `festivals`
   - Fields indexed: `isActive Ascending`, `startDate Ascending`
   - Status: Should change from "Building" → "Enabled"

### Step 4: Monitor Index Build Progress

**Method 1: Firebase Console**
```
https://console.firebase.google.com/project/YOUR_PROJECT_ID/firestore/indexes
```

**Method 2: CLI**
```bash
firebase firestore:indexes
```

Expected output while building:
```
┌─────────────┬────────────────────────────────────────┬──────────┐
│ Collection  │ Fields                                  │ Status   │
├─────────────┼────────────────────────────────────────┼──────────┤
│ festivals   │ isActive, startDate                     │ Building │
└─────────────┴────────────────────────────────────────┴──────────┘
```

Expected output when complete:
```
┌─────────────┬────────────────────────────────────────┬──────────┐
│ Collection  │ Fields                                  │ Status   │
├─────────────┼────────────────────────────────────────┼──────────┤
│ festivals   │ isActive, startDate                     │ Enabled  │
└─────────────┴────────────────────────────────────────┴──────────┘
```

## Post-Deployment Testing

### Test 1: Festival Creation
1. Run the app: `flutter run`
2. Login as owner/manager
3. Go to Festival Management
4. Add test festival:
   - Name: Diwali 2026
   - Start Date: 2026-10-20
   - End Date: 2026-10-24
   - Description: Festival of Lights
5. Click Save

**Expected Console Output:**
```
Saving festival: {name: Diwali 2026, startDate: 2026-10-20, isActive: true}
Festival ID generated: abc123xyz
Festival saved successfully with ID: abc123xyz
Stream: Query executed successfully
Stream: Loaded 1 festivals
```

**Expected UI:**
- Success snackbar: "Festival added successfully"
- Festival appears in list with countdown
- Form clears automatically

### Test 2: Festival Display
1. Navigate away from Festival screen
2. Navigate back to Festival Management
3. Check festival list populates

**Expected Console Output:**
```
Stream: Query executed successfully
Stream: Loaded 1 festivals
Stream: Festival 0: {name: Diwali 2026, startDate: 2026-10-20, ...}
```

### Test 3: Smart Restocking with Festival
1. Go to Manager → Smart Restocking
2. Select a festival from dropdown
3. Check stock recommendations adjust

**Expected:**
- Stock multipliers applied (Sweets 3x, Dairy 2x, etc.)
- Festival demand banner shows
- Recommended quantities increase

### Test 4: Purchase Order Creation
1. Ensure you have:
   - Products with assigned suppliers
   - Low stock items (currentStock < minimumStock)
2. Go to Manager → Smart Restocking
3. Click "Create Purchase Order" for a supplier
4. Fill in details and submit

**Expected:**
- Success message: "Purchase order created for [supplier name]"
- Notification created
- PO appears in Orders list

## Troubleshooting

### Error: "No currently active project"
**Solution:**
```bash
firebase use --add
# Select your project
```

### Error: "Permission denied" during deployment
**Solution:**
```bash
firebase login --reauth
# Re-authenticate with owner/editor permissions
```

### Error: "Index already exists"
**Meaning:** Index is already deployed, just needs time to build
**Action:** Wait 5-10 minutes, check Firebase Console

### Festivals still not appearing after index is "Enabled"
**Debug Steps:**

1. Check Firestore Console directly:
   - Go to Firestore Database → Data tab
   - Open `festivals` collection
   - Verify documents exist
   - Check `isActive: true` field is present

2. Test with simple query first:
   ```dart
   // Temporary: remove orderBy to test basic query
   FirebaseFirestore.instance
     .collection('festivals')
     .where('isActive', isEqualTo: true)
     .get()
     .then((snapshot) => print('Found ${snapshot.docs.length} festivals'));
   ```

3. Check Flutter console for errors:
   ```bash
   flutter logs
   # Look for Firestore query errors
   ```

4. Verify Firebase configuration:
   ```dart
   // In main.dart
   print(Firebase.apps); // Should show initialized app
   ```

### "Index creation failed"
**Possible Causes:**
- Insufficient permissions
- Invalid index configuration
- Firestore API not enabled

**Solution:**
1. Check Firebase Console → Firestore Database
2. Enable Firestore if not already enabled
3. Verify billing is enabled (required for composite indexes)
4. Retry deployment

## Expected Timeline

| Step | Duration | Notes |
|------|----------|-------|
| Set project | < 1 min | Interactive selection |
| Deploy rules | < 1 min | Instant activation |
| Deploy indexes | < 1 min | Submission only |
| Index build | 5-10 min | Cannot be accelerated |
| Total | ~10 min | Most time is index building |

## Verification Commands Summary

```bash
# Check CLI version
firebase --version

# Check active project
firebase use

# Check deployed indexes
firebase firestore:indexes

# Check deployed rules (view timestamp)
firebase firestore:rules:get

# View project info
firebase projects:list

# Test Firestore connection
firebase firestore:databases:list
```

## Success Criteria

✅ **Deployment successful when:**
1. `firebase use` shows your project as active
2. Rules deployment completes without errors
3. Index deployment completes without errors
4. Firebase Console shows index status as "Enabled"
5. App loads festivals without errors
6. Console shows "Loaded X festivals" messages

✅ **Feature working when:**
1. Can create festivals (see success message)
2. Can see festivals in list immediately after creation
3. Can navigate away and back, festivals persist
4. Can create POs with festival-adjusted quantities
5. No errors in console or UI

## Quick Reference

**Firebase Console URLs:**
- Project Overview: `https://console.firebase.google.com/project/YOUR_PROJECT_ID`
- Firestore Indexes: `https://console.firebase.google.com/project/YOUR_PROJECT_ID/firestore/indexes`
- Firestore Rules: `https://console.firebase.google.com/project/YOUR_PROJECT_ID/firestore/rules`
- Firestore Data: `https://console.firebase.google.com/project/YOUR_PROJECT_ID/firestore/data`

**Key Files:**
- Rules: `firestore.rules`
- Indexes: `firestore.indexes.json`
- Firebase config: `firebase.json`
- Project aliases: `.firebaserc`

**Support:**
- Firebase Status: https://status.firebase.google.com/
- Firebase Docs: https://firebase.google.com/docs/firestore
- Index Documentation: https://firebase.google.com/docs/firestore/query-data/indexing
