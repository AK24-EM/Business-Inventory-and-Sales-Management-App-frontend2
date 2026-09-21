/**
 * Clean up test/broken user accounts from Firebase
 * Run: node cleanup_test_users.js <email>
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

async function cleanupUser(email) {
  console.log(`\n🔍 Looking for user: ${email}\n`);

  try {
    // Try to get user by email
    const userRecord = await auth.getUserByEmail(email);
    const uid = userRecord.uid;

    console.log(`Found Firebase Auth user:`);
    console.log(`  UID: ${uid}`);
    console.log(`  Email: ${userRecord.email}`);
    console.log(`  Disabled: ${userRecord.disabled}`);
    console.log();

    // Check Firestore document
    const firestoreDoc = await db.collection('users').doc(uid).get();
    if (firestoreDoc.exists) {
      const data = firestoreDoc.data();
      console.log(`Found Firestore document:`);
      console.log(`  isActive: ${data.isActive}`);
      console.log(`  role: ${data.role}`);
      console.log();
    } else {
      console.log(`⚠️  No Firestore document found\n`);
    }

    // Ask for confirmation
    console.log(`❌ DELETE this user? (y/n)`);
    process.stdin.once('data', async (data) => {
      const answer = data.toString().trim().toLowerCase();
      if (answer === 'y' || answer === 'yes') {
        // Delete Firestore doc
        if (firestoreDoc.exists) {
          await db.collection('users').doc(uid).delete();
          console.log(`✓ Deleted Firestore document`);
        }

        // Delete Firebase Auth account
        await auth.deleteUser(uid);
        console.log(`✓ Deleted Firebase Auth account`);
        console.log(`\n✅ User ${email} has been completely removed\n`);
      } else {
        console.log(`\n❌ Cancelled\n`);
      }
      process.exit(0);
    });

  } catch (err) {
    if (err.code === 'auth/user-not-found') {
      console.log(`❌ User not found in Firebase Auth\n`);
    } else {
      console.error(`Error: ${err.message}`);
    }
    process.exit(1);
  }
}

const email = process.argv[2];
if (!email) {
  console.log(`Usage: node cleanup_test_users.js <email>`);
  console.log(`Example: node cleanup_test_users.js test@demo.com`);
  process.exit(1);
}

cleanupUser(email);
