// ============================================================
// PLATFORM: Google Cloud Platform (GCP)
// Firebase is hosted on GCP — all backend services run on GCP.
// ============================================================
//
// This file is a placeholder. Replace with the output of:
//   flutterfire configure
//
// ── GCP / Firebase Setup Instructions ────────────────────────
//
// STEP 1: Create a GCP Project
//   - Go to https://console.cloud.google.com
//   - Create a new project: "storeiq-prod"
//   - Note your GCP Project ID
//
// STEP 2: Enable Firebase on the GCP Project
//   - Go to https://console.firebase.google.com
//   - Click "Add project" → select your existing GCP project
//   - This links Firebase to your GCP project (same billing)
//
// STEP 3: Enable Required GCP / Firebase Services
//   In Firebase Console:
//     ✅ Authentication       (Email/Password sign-in)
//     ✅ Cloud Firestore      (Database — GCP: Firestore in Native mode)
//     ✅ Firebase Cloud Messaging (Push notifications)
//     ✅ Firebase Analytics
//
//   In GCP Console:
//     ✅ Cloud Firestore API
//     ✅ Identity Platform API (backs Firebase Auth)
//     ✅ Firebase Cloud Messaging API
//     ✅ Cloud Storage (for product images if needed)
//
// STEP 4: Register Flutter Apps
//   Android:
//     - Package name: com.example.store_app
//     - Download google-services.json → place in android/app/
//   iOS:
//     - Bundle ID: com.example.storeApp
//     - Download GoogleService-Info.plist → place in ios/Runner/
//   Web (Owner Dashboard):
//     - Register a Web app in Firebase Console
//     - Copy the Firebase config object
//
// STEP 5: Generate firebase_options.dart
//   dart pub global activate flutterfire_cli
//   flutterfire configure --project=storeiq-prod
//   → This auto-generates lib/firebase_options.dart
//   → Delete THIS placeholder file after that
//
// STEP 6: Update main.dart import
//   Replace:
//     await Firebase.initializeApp();
//   With:
//     import 'firebase_options.dart';
//     await Firebase.initializeApp(
//       options: DefaultFirebaseOptions.currentPlatform,
//     );
//
// ── GCP Firestore Configuration ───────────────────────────────
//
// Location: asia-south1 (Mumbai) — closest to India
// Mode:     Native mode (required for real-time listeners)
// Rules:    Deploy firestore.rules using Firebase CLI:
//             firebase deploy --only firestore:rules
//
// ── GCP Security Notes ────────────────────────────────────────
//
// • All Firestore reads/writes are secured by firestore.rules
// • Role-based access enforced at both app level and Firestore level
// • Firebase Auth tokens are verified server-side by Firestore rules
// • No direct GCP service account keys are stored in the app
// • Use Firebase App Check (GCP) for additional abuse prevention
//
// ── GCP Services Used in This Project ────────────────────────
//
//  Service                    | Purpose
//  ---------------------------+--------------------------------
//  Cloud Firestore (GCP)      | Primary database (all data)
//  Firebase Auth (GCP IAM)    | User authentication & sessions
//  Firebase Cloud Messaging   | Push notifications (mobile)
//  Firebase Analytics (GCP)   | App usage analytics
//  Cloud Storage (GCP)        | Product images (optional)
//  Firebase Hosting (GCP)     | Owner web dashboard hosting
//
// ── Firebase CLI Deployment Commands ─────────────────────────
//
//   # Install Firebase CLI
//   npm install -g firebase-tools
//   firebase login
//   firebase use storeiq-prod
//
//   # Deploy Firestore rules
//   firebase deploy --only firestore:rules
//
//   # Deploy Firestore indexes
//   firebase deploy --only firestore:indexes
//
//   # Deploy web app (owner dashboard)
//   flutter build web --release
//   firebase deploy --only hosting
//
// ── Firestore Indexes Required ────────────────────────────────
//
// Create these composite indexes in firestore.indexes.json:
//
//   sales:        storeId ASC, timestamp DESC
//   sales:        customerId ASC, timestamp DESC
//   inventory:    storeId ASC, currentStock ASC
//   stockMoves:   storeId ASC, productId ASC, timestamp DESC
//   transfers:    destinationStoreId ASC, status ASC
//   loyaltyTxns:  phone ASC, timestamp DESC
//   damagedProds: supplierId ASC, reportedAt DESC
//   notifications: targetStoreId ASC, createdAt DESC
//
// ─────────────────────────────────────────────────────────────
