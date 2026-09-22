# Firebase Setup Guide

## 🔐 Firebase Authentication & Project Setup

Follow these steps to authenticate with Firebase and deploy the backend configuration.

---

## Step 1: Firebase Login

```bash
# Open a browser and authenticate
firebase login --reauth
```

**What to do:**
1. The command will open a browser window
2. Sign in with your Google account: `2024.aayushk@isu.ac.in`
3. Grant Firebase CLI permissions
4. Return to terminal - you should see "✔ Success! Logged in as ..."

**Alternative (if browser doesn't open):**
```bash
# Get the authentication URL
firebase login --no-localhost

# Copy the URL displayed and paste it in your browser
# After authentication, copy the code and paste it back in terminal
```

---

## Step 2: List Your Firebase Projects

```bash
firebase projects:list
```

This will show all your Firebase projects. Look for your project ID (e.g., `store-inventory-management` or similar).

---

## Step 3: Select Your Firebase Project

```bash
cd /Users/aayushkamble/Desktop/store_invemtory_mamanagement

# Use your project ID from step 2
firebase use <your-project-id>

# Example:
# firebase use store-inventory-sale-manage
```

**If you don't have a Firebase project yet:**
```bash
# Create a new Firebase project
firebase projects:create store-inventory-management

# Select it
firebase use store-inventory-management
```

---

## Step 4: Initialize Firebase in Your Project

```bash
firebase init

# Select these features (use spacebar to select):
# ◉ Firestore: Configure security rules and indexes files
# ◉ Functions: Configure a Cloud Functions directory
# ◉ Hosting: Configure files for Firebase Hosting
```

**Configuration choices:**
- Firestore rules file: `firestore.rules` (already exists)
- Firestore indexes file: `firestore.indexes.json` (already exists)
- Functions language: TypeScript
- Functions source directory: `functions` (already exists)
- Hosting public directory: `store_app/build/web`

---

## Step 5: Deploy Firestore Indexes

```bash
# Deploy the indexes (this takes 5-15 minutes to build)
firebase deploy --only firestore:indexes

# Check deployment status
firebase firestore:indexes
```

**Expected Output:**
```
✔ Deploy complete!
```

---

## Step 6: Deploy Firestore Security Rules

```bash
# Deploy the security rules
firebase deploy --only firestore:rules
```

---

## Step 7: Verify Deployment

1. **Open Firebase Console:**
   ```
   https://console.firebase.google.com/project/<your-project-id>/firestore
   ```

2. **Check Indexes:**
   - Go to "Indexes" tab
   - You should see 20+ indexes
   - Status should change from "Building" to "Enabled" (takes time)

3. **Check Rules:**
   - Go to "Rules" tab
   - You should see your deployed security rules

---

## Step 8: Configure Flutter App

1. **Install FlutterFire CLI:**
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. **Configure Flutter App with Firebase:**
   ```bash
   cd store_app
   flutterfire configure --project=<your-project-id>
   ```

3. **This will generate:**
   - `lib/firebase_options.dart` (overwrites the placeholder)
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`

---

## Step 9: Enable Firebase Services

In Firebase Console, enable these services:

### 1. Authentication
- Go to Authentication → Get Started
- Enable "Email/Password" sign-in method

### 2. Firestore Database
- Go to Firestore Database → Create Database
- Start in **Production Mode**
- Select location: `asia-south1` (Mumbai)

### 3. Cloud Storage (optional, for product images)
- Go to Storage → Get Started
- Use default security rules
- Select location: `asia-south1`

---

## Step 10: Create Initial Admin User

### Using Firebase Console:

1. Go to **Authentication** → **Users** tab
2. Click "Add User"
3. Email: `owner@storeiq.com`
4. Password: `Owner@123` (change this immediately!)
5. Click "Add User"

### Set Custom Claims (for owner role):

You need to run this via Cloud Functions or Firebase CLI:

```bash
# Install Firebase Admin SDK for one-time setup
npm install -g firebase-admin

# Or use Firebase Console:
# Go to Functions → Create a new function to set custom claims
```

**Sample Cloud Function to set owner role:**
```javascript
const admin = require('firebase-admin');
admin.initializeApp();

// Set owner claims
exports.setOwnerRole = functions.https.onRequest(async (req, res) => {
  const email = 'owner@storeiq.com';
  const user = await admin.auth().getUserByEmail(email);
  
  await admin.auth().setCustomUserClaims(user.uid, {
    role: 'owner',
    storeId: null
  });
  
  res.send('Owner role set successfully');
});
```

---

## Step 11: Test the Application

```bash
cd store_app
flutter run
```

**Login with:**
- Email: `owner@storeiq.com`
- Password: `Owner@123`

You should be directed to the Owner Dashboard.

---

## Troubleshooting

### Error: "No currently active project"
```bash
firebase use --add
# Select your project from the list
```

### Error: "Authentication Error: Your credentials are no longer valid"
```bash
firebase login --reauth
# Follow the browser authentication flow
```

### Error: "Index not found" in app
- Wait for indexes to finish building (check Firebase Console)
- Indexes take 5-15 minutes after deployment

### Error: "Permission denied" in app
- Check that Firestore rules are deployed
- Verify user has correct custom claims (role)
- Check Firebase Console → Firestore → Rules tab

---

## Quick Reference Commands

```bash
# Login
firebase login

# List projects
firebase projects:list

# Select project
firebase use <project-id>

# Deploy everything
firebase deploy

# Deploy only indexes
firebase deploy --only firestore:indexes

# Deploy only rules
firebase deploy --only firestore:rules

# Check deployment status
firebase firestore:indexes

# View logs
firebase functions:log
```

---

## Next Steps

After Firebase is configured:

1. ✅ Deploy indexes: `firebase deploy --only firestore:indexes`
2. ✅ Deploy rules: `firebase deploy --only firestore:rules`
3. ✅ Configure Flutter app: `flutterfire configure`
4. ✅ Create admin user in Firebase Console
5. ✅ Set custom claims for owner role
6. ✅ Run the app: `flutter run`

---

## Support

- **Firebase Documentation**: https://firebase.google.com/docs
- **FlutterFire Documentation**: https://firebase.flutter.dev
- **Firebase Console**: https://console.firebase.google.com

---

**Last Updated**: September 22, 2026
