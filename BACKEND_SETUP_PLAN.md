# 🚀 Complete Backend Setup Plan for Store Inventory Management

**Project:** Store Inventory Management System  
**Firebase Project ID:** `store-inventory-sale-manage`  
**Platform:** Google Cloud Platform (GCP) / Firebase  
**Architecture:** Serverless (Firebase + Cloud Functions)

---

## 📋 Table of Contents

1. [Phase 1: Firebase Project Configuration](#phase-1-firebase-project-configuration)
2. [Phase 2: Authentication Setup](#phase-2-authentication-setup)
3. [Phase 3: Firestore Database Setup](#phase-3-firestore-database-setup)
4. [Phase 4: Security Rules Deployment](#phase-4-security-rules-deployment)
5. [Phase 5: Cloud Functions (Backend Logic)](#phase-5-cloud-functions-backend-logic)
6. [Phase 6: Flutter App Configuration](#phase-6-flutter-app-configuration)
7. [Phase 7: Data Migration](#phase-7-data-migration)
8. [Phase 8: Monitoring & Logging](#phase-8-monitoring--logging)
9. [Phase 9: Production Deployment](#phase-9-production-deployment)
10. [Phase 10: Backup & Disaster Recovery](#phase-10-backup--disaster-recovery)

---

## Phase 1: Firebase Project Configuration

### ✅ Step 1.1: Verify GCP Project

**Current Status:** ✅ Project exists (`store-inventory-sale-manage`)

**Action:**
```bash
# Login to Google Cloud
gcloud auth login

# Set project
gcloud config set project store-inventory-sale-manage

# Verify project
gcloud projects describe store-inventory-sale-manage
```

**Expected Output:**
```
projectId: store-inventory-sale-manage
name: Store Inventory Sale Manage
projectNumber: XXXXXXXXXXXX
```

---

### ✅ Step 1.2: Enable Required APIs

**Action:**
```bash
# Enable Firebase APIs
gcloud services enable firebase.googleapis.com
gcloud services enable firestore.googleapis.com
gcloud services enable identitytoolkit.googleapis.com
gcloud services enable firebasehosting.googleapis.com
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable cloudscheduler.googleapis.com
gcloud services enable cloudmessaging.googleapis.com
gcloud services enable firebaseanalytics.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable secretmanager.googleapis.com
```

**Verification:**
```bash
# List enabled APIs
gcloud services list --enabled
```

---

### ✅ Step 1.3: Set Up Billing

**Action:**
1. Go to: https://console.cloud.google.com/billing
2. Link project to billing account
3. Set up budget alerts:
   - Alert at 50% of budget
   - Alert at 90% of budget
   - Alert at 100% of budget

**Recommended Budget:** ₹5,000/month (~$60 USD) for development/testing

---

### ✅ Step 1.4: Configure Project Regions

**Recommended Regions for India:**
- **Primary:** `asia-south1` (Mumbai)
- **Secondary:** `asia-southeast1` (Singapore)

**Action:**
```bash
# This will be set during Firestore initialization
```

---

## Phase 2: Authentication Setup

### ✅ Step 2.1: Firebase Authentication Console

**Action:**
1. Go to: https://console.firebase.google.com
2. Select project: `store-inventory-sale-manage`
3. Navigate to: **Authentication** → **Sign-in method**
4. Enable **Email/Password** authentication
5. Configure settings:
   - ✅ Email/Password
   - ✅ Email link (passwordless sign-in) - Optional
   - ❌ Anonymous (not needed)
   - ❌ Google Sign-in (not needed for now)

---

### ✅ Step 2.2: Set Up Custom Claims (Roles)

**Current Status:** ✅ Script exists (`set_custom_claims.js`)

**Verify script:**
```bash
cat set_custom_claims.js
```

**Test Custom Claims:**
```bash
# Install dependencies
npm install firebase-admin

# Run script to set custom claims
node set_custom_claims.js
```

**Expected Output:**
```
✅ Custom claim 'owner' set for user: owner@example.com
✅ Custom claim 'manager' set for user: manager@example.com
✅ Custom claim 'employee' set for user: employee@example.com
```

---

### ✅ Step 2.3: Configure Password Policies

**Action in Firebase Console:**
1. Authentication → Settings → Password policy
2. Set minimum requirements:
   - Minimum length: 8 characters
   - Require uppercase: Yes
   - Require lowercase: Yes
   - Require numbers: Yes
   - Require special characters: No (for simplicity)

---

## Phase 3: Firestore Database Setup

### ✅ Step 3.1: Initialize Firestore

**Action:**
1. Go to Firebase Console → Firestore Database
2. Click **Create database**
3. Choose mode: **Production mode** (we'll deploy rules later)
4. Select location: **asia-south1 (Mumbai)**
5. Click **Enable**

**CLI Method:**
```bash
# Initialize Firebase in project directory
cd /Users/aayushkamble/Desktop/store_invemtory_mamanagement
firebase init firestore

# Select:
# - Use existing project: store-inventory-sale-manage
# - Firestore rules file: firestore.rules
# - Firestore indexes file: firestore.indexes.json
```

---

### ✅ Step 3.2: Create Firestore Indexes

**Current Status:** ✅ File exists (`firestore.indexes.json`)

**Verify indexes file:**
```bash
cat firestore.indexes.json
```

**Deploy indexes:**
```bash
firebase deploy --only firestore:indexes
```

**Manual Index Creation (if needed):**
1. Go to: Firestore → Indexes → Composite indexes
2. Create indexes for:
   - `sales`: `storeId` (ASC), `timestamp` (DESC)
   - `inventory`: `storeId` (ASC), `currentStock` (ASC)
   - `stockMovements`: `storeId` (ASC), `timestamp` (DESC)
   - `customers`: `phone` (ASC), `registeredAt` (DESC)
   - `loyaltyTransactions`: `phone` (ASC), `timestamp` (DESC)

---

### ✅ Step 3.3: Seed Initial Data

**Current Status:** ✅ Seed scripts exist in `seed/` directory

**Action:**
```bash
# Navigate to seed directory
cd seed

# Install dependencies
npm install firebase-admin

# Run seed scripts
node seed_master_data.js    # Stores, products
node seed_users.js          # Users with roles
node seed_inventory.js      # Initial inventory
node seed_customers.js      # Sample customers

# Verify data
node verify_seed.js
```

---

## Phase 4: Security Rules Deployment

### ✅ Step 4.1: Review Security Rules

**Check if rules exist:**
```bash
ls -la firestore.rules
```

**If not exists, create comprehensive rules:**

---

### ✅ Step 4.2: Create Firestore Security Rules

**Action:** Create `firestore.rules` file

---

### ✅ Step 4.3: Deploy Security Rules

**Action:**
```bash
# Test rules locally (optional)
firebase emulators:start --only firestore

# Deploy rules to production
firebase deploy --only firestore:rules
```

**Verification:**
```bash
# Check rules in Firebase Console
# Firestore → Rules tab
```

---

## Phase 5: Cloud Functions (Backend Logic)

### ✅ Step 5.1: Initialize Cloud Functions

**Action:**
```bash
# Initialize functions
firebase init functions

# Select:
# - Language: JavaScript or TypeScript
# - ESLint: Yes
# - Install dependencies: Yes
```

**Directory Structure:**
```
functions/
├── index.js                    # Main functions file
├── package.json
├── .eslintrc.js
├── src/
│   ├── triggers/
│   │   ├── onSaleCreated.js   # Auto-update inventory
│   │   ├── onLowStock.js      # Send low stock alerts
│   │   └── onUserCreated.js   # Welcome email/notification
│   ├── scheduled/
│   │   ├── dailyReport.js     # Generate daily reports
│   │   └── autoRestock.js     # Auto purchase orders
│   ├── http/
│   │   ├── sendInvoice.js     # Email invoice to customer
│   │   └── generateReport.js  # On-demand report generation
│   └── utils/
│       ├── email.js           # Email utilities
│       └── sms.js             # SMS utilities
```

---

### ✅ Step 5.2: Implement Critical Cloud Functions

**Function 1: Auto-update Inventory on Sale**

**File:** `functions/src/triggers/onSaleCreated.js`

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.onSaleCreated = functions.firestore
  .document('sales/{saleId}')
  .onCreate(async (snap, context) => {
    const sale = snap.data();
    const batch = admin.firestore().batch();
    
    // Update inventory for each item
    for (const item of sale.items) {
      const inventoryRef = admin.firestore()
        .collection('inventory')
        .doc(item.inventoryId);
      
      batch.update(inventoryRef, {
        currentStock: admin.firestore.FieldValue.increment(-item.quantity),
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
      });
      
      // Create stock movement record
      const movementRef = admin.firestore().collection('stockMovements').doc();
      batch.set(movementRef, {
        storeId: sale.storeId,
        productId: item.productId,
        type: 'sale',
        quantity: -item.quantity,
        referenceId: snap.id,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      });
    }
    
    await batch.commit();
    console.log(`✅ Inventory updated for sale: ${snap.id}`);
  });
```

---

**Function 2: Low Stock Alerts**

**File:** `functions/src/triggers/onLowStock.js`

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.checkLowStock = functions.firestore
  .document('inventory/{inventoryId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    
    // Only trigger if stock went below reorder point
    if (after.currentStock <= after.reorderPoint && 
        before.currentStock > before.reorderPoint) {
      
      // Create notification
      await admin.firestore().collection('notifications').add({
        type: 'low_stock',
        severity: 'warning',
        title: 'Low Stock Alert',
        message: `${after.productName} is running low (${after.currentStock} units)`,
        targetRole: 'manager',
        targetStoreId: after.storeId,
        data: {
          inventoryId: context.params.inventoryId,
          productId: after.productId,
          currentStock: after.currentStock,
          reorderPoint: after.reorderPoint
        },
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      console.log(`⚠️ Low stock alert created for: ${after.productName}`);
    }
  });
```

---

**Function 3: Daily Analytics Report**

**File:** `functions/src/scheduled/dailyReport.js`

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.generateDailyReport = functions.pubsub
  .schedule('0 9 * * *') // Every day at 9 AM IST
  .timeZone('Asia/Kolkata')
  .onRun(async (context) => {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    yesterday.setHours(0, 0, 0, 0);
    
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    // Get yesterday's sales
    const salesSnapshot = await admin.firestore()
      .collection('sales')
      .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(yesterday))
      .where('timestamp', '<', admin.firestore.Timestamp.fromDate(today))
      .get();
    
    // Calculate metrics
    let totalRevenue = 0;
    let totalTransactions = salesSnapshot.size;
    
    salesSnapshot.forEach(doc => {
      totalRevenue += doc.data().finalAmount;
    });
    
    // Store report
    await admin.firestore().collection('dailyReports').add({
      date: admin.firestore.Timestamp.fromDate(yesterday),
      totalRevenue,
      totalTransactions,
      averageTransaction: totalRevenue / totalTransactions,
      generatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log(`📊 Daily report generated: ₹${totalRevenue} revenue`);
  });
```

---

**Function 4: Send Invoice Email**

**File:** `functions/src/http/sendInvoice.js`

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

// Configure email transport (use SendGrid, Mailgun, or Gmail)
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: functions.config().email.user,
    pass: functions.config().email.pass
  }
});

exports.sendInvoice = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }
  
  const { saleId, customerEmail } = data;
  
  // Get sale data
  const saleDoc = await admin.firestore()
    .collection('sales')
    .doc(saleId)
    .get();
  
  if (!saleDoc.exists) {
    throw new functions.https.HttpsError('not-found', 'Sale not found');
  }
  
  const sale = saleDoc.data();
  
  // Generate invoice HTML
  const invoiceHtml = generateInvoiceHTML(sale);
  
  // Send email
  await transporter.sendMail({
    from: 'noreply@yourstore.com',
    to: customerEmail,
    subject: `Invoice #${saleId}`,
    html: invoiceHtml
  });
  
  return { success: true, message: 'Invoice sent successfully' };
});

function generateInvoiceHTML(sale) {
  // Generate invoice template
  return `
    <html>
      <body>
        <h1>Invoice</h1>
        <p>Date: ${sale.timestamp.toDate().toLocaleDateString()}</p>
        <p>Total Amount: ₹${sale.finalAmount}</p>
        <!-- Add more invoice details -->
      </body>
    </html>
  `;
}
```

---

### ✅ Step 5.3: Configure Environment Variables

**Action:**
```bash
# Set email credentials
firebase functions:config:set email.user="your-email@gmail.com"
firebase functions:config:set email.pass="your-app-password"

# Set SMS credentials (if using Twilio)
firebase functions:config:set twilio.sid="your-twilio-sid"
firebase functions:config:set twilio.token="your-twilio-token"

# View config
firebase functions:config:get
```

---

### ✅ Step 5.4: Deploy Cloud Functions

**Action:**
```bash
# Deploy all functions
firebase deploy --only functions

# Or deploy specific function
firebase deploy --only functions:onSaleCreated
firebase deploy --only functions:generateDailyReport
```

**Verification:**
```bash
# List deployed functions
firebase functions:list

# View logs
firebase functions:log
```

---

## Phase 6: Flutter App Configuration

### ✅ Step 6.1: Generate firebase_options.dart

**Action:**
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
cd store_app
flutterfire configure --project=store-inventory-sale-manage

# Select platforms:
# ✅ Android
# ✅ iOS
# ✅ Web
```

**Expected Output:**
```
✔ Firebase configuration file generated successfully
  lib/firebase_options.dart
```

---

### ✅ Step 6.2: Update main.dart

**Current Status:** Check if already configured

**Expected code in `main.dart`:**
```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(MyApp());
}
```

---

### ✅ Step 6.3: Configure Android App

**Files to configure:**
- `android/app/google-services.json` (auto-generated by flutterfire)
- `android/app/build.gradle`

**Verify:**
```bash
cat android/app/google-services.json
```

---

### ✅ Step 6.4: Configure iOS App

**Files to configure:**
- `ios/Runner/GoogleService-Info.plist` (auto-generated by flutterfire)
- `ios/Runner.xcodeproj`

**Verify:**
```bash
cat ios/Runner/GoogleService-Info.plist
```

---

### ✅ Step 6.5: Configure Web App

**Files to configure:**
- `web/index.html` (Firebase SDK scripts)

**Verify Firebase SDK loaded:**
```html
<!-- Check web/index.html for Firebase scripts -->
<script src="https://www.gstatic.com/firebasejs/9.x.x/firebase-app.js"></script>
<script src="https://www.gstatic.com/firebasejs/9.x.x/firebase-firestore.js"></script>
```

---

## Phase 7: Data Migration

### ✅ Step 7.1: Backup Existing Data (if any)

**Action:**
```bash
# Export existing Firestore data
gcloud firestore export gs://store-inventory-backup/$(date +%Y%m%d)

# Verify backup
gsutil ls gs://store-inventory-backup/
```

---

### ✅ Step 7.2: Run Data Migration Scripts

**Current Status:** ✅ Migration script exists (`migrate_sales_dates.js`)

**Action:**
```bash
# Run migration
node migrate_sales_dates.js

# Verify migration
node verify_migration.js
```

---

### ✅ Step 7.3: Seed Test Data

**Action:**
```bash
# Seed development data
cd seed
node seed_all.js

# Create sample users
node create_test_users.js
```

---

## Phase 8: Monitoring & Logging

### ✅ Step 8.1: Enable Firebase Crashlytics

**Action in pubspec.yaml:**
```yaml
dependencies:
  firebase_crashlytics: ^4.1.3
```

**Configure in main.dart:**
```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
```

---

### ✅ Step 8.2: Configure Cloud Logging

**Action:**
```bash
# Enable logging
gcloud logging write app-logs "Backend setup completed" --severity=INFO

# Create log-based metrics
gcloud logging metrics create error_count \
  --description="Count of errors" \
  --log-filter='severity>=ERROR'
```

---

### ✅ Step 8.3: Set Up Alerts

**Action in GCP Console:**
1. Monitoring → Alerting → Create Policy
2. Create alerts for:
   - High error rate (>10 errors/minute)
   - Firestore read/write quota near limit
   - Function execution failures
   - Authentication failures

---

## Phase 9: Production Deployment

### ✅ Step 9.1: Deploy Security Rules

**Action:**
```bash
# Deploy rules to production
firebase deploy --only firestore:rules

# Verify rules
firebase firestore:rules:get
```

---

### ✅ Step 9.2: Deploy Cloud Functions

**Action:**
```bash
# Deploy all functions
firebase deploy --only functions

# Verify deployment
firebase functions:list
```

---

### ✅ Step 9.3: Build & Deploy Flutter Apps

**Android:**
```bash
cd store_app
flutter build apk --release
flutter build appbundle --release

# Upload to Google Play Console
```

**iOS:**
```bash
flutter build ios --release
# Open in Xcode and upload to App Store Connect
```

**Web (Owner Dashboard):**
```bash
flutter build web --release
firebase deploy --only hosting
```

---

### ✅ Step 9.4: Configure Custom Domain (Optional)

**Action:**
```bash
# Add custom domain
firebase hosting:sites:create store-dashboard

# Connect domain
firebase hosting:channel:deploy live --site=store-dashboard
```

---

## Phase 10: Backup & Disaster Recovery

### ✅ Step 10.1: Automated Firestore Backups

**Action:**
```bash
# Schedule daily backups
gcloud firestore operations list

# Create backup schedule
gcloud alpha firestore backups schedules create \
  --database='(default)' \
  --recurrence=daily \
  --retention=7d
```

---

### ✅ Step 10.2: Export to BigQuery (for analytics)

**Action:**
```bash
# Enable BigQuery export
gcloud firestore operations list

# Create export job
gcloud firestore export gs://store-inventory-backup/bigquery-export/
```

---

### ✅ Step 10.3: Disaster Recovery Plan

**Document:**
1. Daily automated backups to Cloud Storage
2. 7-day retention policy
3. Cross-region replication
4. Recovery time objective (RTO): 4 hours
5. Recovery point objective (RPO): 24 hours

---

## 📊 Deployment Checklist

### Pre-Deployment
- [ ] Firebase project created and configured
- [ ] Billing enabled with budget alerts
- [ ] All APIs enabled
- [ ] Firestore database initialized in asia-south1
- [ ] Security rules reviewed and tested
- [ ] Indexes created and deployed
- [ ] Cloud Functions developed and tested locally
- [ ] Environment variables configured

### Development Testing
- [ ] `firebase_options.dart` generated
- [ ] Android app configured with google-services.json
- [ ] iOS app configured with GoogleService-Info.plist
- [ ] Web app configured with Firebase SDK
- [ ] Authentication working (login/logout)
- [ ] Firestore read/write working
- [ ] Security rules enforced correctly
- [ ] Cloud Functions triggered successfully

### Production Deployment
- [ ] Security rules deployed
- [ ] Indexes deployed
- [ ] Cloud Functions deployed
- [ ] Flutter apps built and tested
- [ ] Crashlytics configured
- [ ] Monitoring and alerts set up
- [ ] Backup schedule configured
- [ ] Documentation updated

### Post-Deployment
- [ ] Monitor error rates for 24 hours
- [ ] Verify all functions executing
- [ ] Check Firestore quota usage
- [ ] Confirm backups running
- [ ] Test disaster recovery procedure
- [ ] User acceptance testing (UAT)

---

## 🚨 Estimated Timeline

| Phase | Duration | Priority |
|-------|----------|----------|
| Phase 1: Firebase Configuration | 2 hours | HIGH |
| Phase 2: Authentication Setup | 3 hours | HIGH |
| Phase 3: Firestore Setup | 2 hours | HIGH |
| Phase 4: Security Rules | 4 hours | HIGH |
| Phase 5: Cloud Functions | 16 hours | MEDIUM |
| Phase 6: Flutter App Config | 3 hours | HIGH |
| Phase 7: Data Migration | 4 hours | MEDIUM |
| Phase 8: Monitoring Setup | 4 hours | MEDIUM |
| Phase 9: Production Deployment | 6 hours | HIGH |
| Phase 10: Backup & DR | 3 hours | MEDIUM |
| **TOTAL** | **47 hours** (~6 days) | |

---

## 💰 Estimated Monthly Costs (India Region)

| Service | Free Tier | Expected Usage | Est. Cost |
|---------|-----------|----------------|-----------|
| Firestore (Reads) | 50K/day | ~200K/day | ₹800 |
| Firestore (Writes) | 20K/day | ~50K/day | ₹500 |
| Firestore (Storage) | 1 GB | 5 GB | ₹400 |
| Cloud Functions | 2M invocations | 500K/month | ₹300 |
| Authentication | Unlimited | N/A | Free |
| Hosting | 10 GB | 2 GB | Free |
| Cloud Logging | 50 GB | 10 GB | Free |
| **TOTAL** | | | **~₹2,000/month** |

---

## 📞 Support & Resources

- Firebase Console: https://console.firebase.google.com
- GCP Console: https://console.cloud.google.com
- Firebase Documentation: https://firebase.google.com/docs
- FlutterFire: https://firebase.flutter.dev
- Status Page: https://status.firebase.google.com

---

## 🎯 Next Steps

1. **IMMEDIATE:** Complete Phase 1-4 (Core Infrastructure)
2. **WEEK 1:** Complete Phase 5 (Cloud Functions)
3. **WEEK 2:** Complete Phase 6-7 (App Config & Migration)
4. **WEEK 3:** Complete Phase 8-10 (Monitoring & Production)

**Priority Order:**
1. ✅ Firebase Project Setup
2. ✅ Security Rules Deployment
3. ✅ Flutter App Configuration
4. ⚠️ Cloud Functions (as needed)
5. ⚠️ Monitoring & Backups

---

**Last Updated:** 2024  
**Version:** 1.0  
**Owner:** Development Team
