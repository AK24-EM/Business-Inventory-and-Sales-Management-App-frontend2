/**
 * Fix a user account by enabling it in Firebase Auth and Firestore
 * Run: node fix_user_account.js <email>
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

async function fixUser(email) {
  console.log(`\n🔧 Fixing user: ${email}\n`);

  try {
    // Get user by email
    const userRecord = await auth.getUserByEmail(email);
    const uid = userRecord.uid;

    console.log(`Found user: ${uid}`);

    // Enable in Firebase Auth if disabled
    if (userRecord.disabled) {
      await auth.updateUser(uid, { disabled: false });
      console.log(`✓ Enabled Firebase Auth account`);
    } else {
      console.log(`✓ Firebase Auth already enabled`);
    }

    // Check/fix Firestore document
    const firestoreDoc = await db.collection('users').doc(uid).get();
    if (firestoreDoc.exists) {
      const data = firestoreDoc.data();
      if (!data.isActive) {
        await db.collection('users').doc(uid).update({ isActive: true });
        console.log(`✓ Set isActive = true in Firestore`);
      } else {
        console.log(`✓ Firestore isActive already true`);
      }
    } else {
      // Create Firestore document
      await db.collection('users').doc(uid).set({
        name: userRecord.displayName || 'User',
        email: userRecord.email,
        phone: userRecord.phoneNumber || '',
        role: 'owner',
        assignedStoreId: null,
        isActive: true,
        createdAt: new Date(),
        lastLogin: null,
        fcmToken: null,
      });
      console.log(`✓ Created Firestore document`);
    }

    // Set custom claims
    await auth.setCustomUserClaims(uid, { role: 'owner' });
    console.log(`✓ Set role claim to 'owner'`);

    console.log(`\n✅ Account ${email} is now ready to use!\n`);
    process.exit(0);

  } catch (err) {
    if (err.code === 'auth/user-not-found') {
      console.log(`❌ User not found. Please register first.\n`);
    } else {
      console.error(`Error: ${err.message}`);
    }
    process.exit(1);
  }
}

const email = process.argv[2];
if (!email) {
  console.log(`Usage: node fix_user_account.js <email>`);
  console.log(`Example: node fix_user_account.js test@demo.com`);
  process.exit(1);
}

fixUser(email);
