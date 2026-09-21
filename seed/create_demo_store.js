/**
 * Create a demo store in Firestore for testing
 * Run: node create_demo_store.js
 */

const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('./store-inventory-sale-manage-firebase-adminsdk-fbsvc-2d3176b5ac.json');

initializeApp({
  credential: cert(serviceAccount),
  projectId: 'store-inventory-sale-manage',
});

const db = getFirestore();

async function createDemoStore() {
  console.log('\n🏪 Creating demo store...\n');

  const storeId = 'store_demo_01';
  const storeData = {
    id: storeId,
    name: 'Demo Store - Mumbai',
    address: '123 MG Road, Mumbai, Maharashtra 400001',
    phone: '+919876543210',
    managerId: null, // Can be assigned later
    isActive: true,
    createdAt: new Date(),
    openingTime: '09:00',
    closingTime: '21:00',
  };

  try {
    await db.collection('stores').doc(storeId).set(storeData);
    console.log(`✅ Store created successfully!`);
    console.log(`   ID: ${storeId}`);
    console.log(`   Name: ${storeData.name}`);
    console.log(`\nNow you can assign this store to your user account.\n`);
    process.exit(0);
  } catch (err) {
    console.error(`❌ Error: ${err.message}`);
    process.exit(1);
  }
}

createDemoStore();
