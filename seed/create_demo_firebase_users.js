/**
 * Create Firebase Auth accounts for the backend demo users.
 * Run: node create_demo_firebase_users.js
 */

const { initializeApp, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('./store-inventory-sale-manage-firebase-adminsdk-fbsvc-2d3176b5ac.json');

initializeApp({
  credential: cert(serviceAccount),
  projectId: 'store-inventory-sale-manage',
});

const auth = getAuth();
const db = getFirestore();

const DEMO_USERS = [
  {
    uid: 'uid_owner',
    email: 'owner@demo.com',
    password: 'demo123',
    name: 'Rahul Sharma',
    phone: '+919876543210',
    role: 'owner',
    assignedStoreId: null,
  },
  {
    uid: 'uid_manager',
    email: 'manager@demo.com',
    password: 'demo123',
    name: 'Priya Patel',
    phone: '+919876543211',
    role: 'manager',
    assignedStoreId: 'store_01',
  },
  {
    uid: 'uid_employee',
    email: 'employee@demo.com',
    password: 'demo123',
    name: 'Amit Kumar',
    phone: '+919876543212',
    role: 'employee',
    assignedStoreId: 'store_01',
  },
];

async function createDemoUsers() {
  console.log('Creating Firebase Auth + Firestore records for demo users...\n');

  for (const user of DEMO_USERS) {
    try {
      // Check if user already exists
      try {
        await auth.getUser(user.uid);
        console.log(`✓ ${user.email} already exists`);
      } catch (err) {
        if (err.code === 'auth/user-not-found') {
          // Create Firebase Auth user
          await auth.createUser({
            uid: user.uid,
            email: user.email,
            password: user.password,
            displayName: user.name,
            phoneNumber: user.phone,
          });
          console.log(`✓ Created Firebase Auth: ${user.email}`);
        } else {
          throw err;
        }
      }

      // Set custom claims
      await auth.setCustomUserClaims(user.uid, { role: user.role });
      console.log(`  → Set role claim: ${user.role}`);

      // Create/update Firestore document
      await db.collection('users').doc(user.uid).set({
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        assignedStoreId: user.assignedStoreId,
        isActive: true,
        createdAt: new Date(),
        lastLogin: null,
        fcmToken: null,
      });
      console.log(`  → Created Firestore doc\n`);
    } catch (err) {
      console.error(`✗ Failed to create ${user.email}:`, err.message);
    }
  }

  console.log('Done!');
  process.exit(0);
}

createDemoUsers();
