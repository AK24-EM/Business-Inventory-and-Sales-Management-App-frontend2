const { initializeApp, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const serviceAccount = require('./store-inventory-sale-manage-firebase-adminsdk-fbsvc-2d3176b5ac.json');

initializeApp({
  credential: cert(serviceAccount),
  projectId: 'store-inventory-sale-manage',
});

const auth = getAuth();

async function check() {
  try {
    const list = await auth.listUsers(10);
    console.log(`Total users found: ${list.users.length}`);
    for (const u of list.users) {
      console.log(`- ${u.email} (UID: ${u.uid})`);
    }
  } catch (e) {
    console.error('Error querying Firebase Auth:', e.message || e);
  }
}

check();
