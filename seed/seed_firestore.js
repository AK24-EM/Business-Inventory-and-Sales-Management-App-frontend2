/**
 * seed_firestore.js
 *
 * Populates Firestore with reference mock data so the app has something
 * to display immediately — notifications, festivals, and festival alerts.
 *
 * Run from the seed/ directory:
 *   node seed_firestore.js
 *
 * If it hangs, your network blocks oauth2.googleapis.com.
 * Try from a different network or use: HTTPS_PROXY=... node seed_firestore.js
 */

const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('./store-inventory-sale-manage-firebase-adminsdk-fbsvc-2d3176b5ac.json');

initializeApp({
  credential: cert(serviceAccount),
  projectId: 'store-inventory-sale-manage',
});

const db = getFirestore();

const now = () => new Date();
const daysAgo  = (n) => new Date(Date.now() - n * 86400000);
const daysLater = (n) => new Date(Date.now() + n * 86400000);

async function clearAndSeed(collectionName, docs) {
  console.log(`\nSeeding ${collectionName}...`);
  const batch = db.batch();
  const existing = await db.collection(collectionName).limit(200).get();
  existing.docs.forEach(d => batch.delete(d.ref));
  docs.forEach(({ id, data }) => {
    const ref = id ? db.collection(collectionName).doc(id) : db.collection(collectionName).doc();
    batch.set(ref, data);
  });
  await batch.commit();
  console.log(`  ✓ ${docs.length} documents written`);
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. Notifications
// ─────────────────────────────────────────────────────────────────────────────
async function seedNotifications() {
  const docs = [
    {
      id: 'notif_001',
      data: {
        title: 'Low Stock Alert — Aashirvaad Atta 5kg',
        body: 'Only 8 units remaining at Andheri Branch. Minimum stock level is 20. Consider restocking soon.',
        type: 'lowStock',
        isRead: false,
        targetStoreId: 'store_01',
        targetUserId: null,
        createdAt: daysAgo(0),
        productId: 'p03',
        productName: 'Aashirvaad Atta 5kg',
      },
    },
    {
      id: 'notif_002',
      data: {
        title: 'Low Stock Alert — Lays Classic 75g',
        body: 'Only 5 units remaining at Andheri Branch. Minimum stock level is 25.',
        type: 'lowStock',
        isRead: false,
        targetStoreId: 'store_01',
        targetUserId: null,
        createdAt: daysAgo(0),
        productId: 'p05',
        productName: 'Lays Classic 75g',
      },
    },
    {
      id: 'notif_003',
      data: {
        title: 'Low Stock Alert — Mother Dairy Milk 1L',
        body: 'Only 3 units remaining at Andheri Branch. This product moves fast — restock urgently.',
        type: 'lowStock',
        isRead: false,
        targetStoreId: 'store_01',
        targetUserId: null,
        createdAt: daysAgo(1),
        productId: 'p08',
        productName: 'Mother Dairy Milk 1L',
      },
    },
    {
      id: 'notif_004',
      data: {
        title: 'Stock Transfer Pending',
        body: 'Incoming transfer of 20 units Coca-Cola 2L from Bandra Branch is awaiting your confirmation.',
        type: 'transferPending',
        isRead: false,
        targetStoreId: 'store_01',
        targetUserId: 'uid_manager',
        createdAt: daysAgo(1),
      },
    },
    {
      id: 'notif_005',
      data: {
        title: 'Restocking Recommendation',
        body: 'Based on your 30-day sales velocity, we recommend ordering 60 units of Aashirvaad Atta 5kg and 80 units of Lays Classic 75g.',
        type: 'restockingRequired',
        isRead: true,
        targetStoreId: 'store_01',
        targetUserId: null,
        createdAt: daysAgo(2),
      },
    },
    {
      id: 'notif_006',
      data: {
        title: 'Diwali Demand Alert',
        body: 'Diwali is in 18 days. Historical data shows 3x surge in Dairy and Snacks. Place purchase orders now.',
        type: 'festivalAlert',
        isRead: false,
        targetStoreId: null,
        targetUserId: null,
        createdAt: daysAgo(0),
      },
    },
    {
      id: 'notif_007',
      data: {
        title: 'Transfer Confirmed',
        body: 'Your transfer of 15 units Dove Soap 100g to Bandra Branch has been confirmed and stock has been updated.',
        type: 'transferConfirmed',
        isRead: true,
        targetStoreId: 'store_01',
        targetUserId: 'uid_manager',
        createdAt: daysAgo(3),
      },
    },
  ];
  await clearAndSeed('notifications', docs);
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Festivals
// ─────────────────────────────────────────────────────────────────────────────
async function seedFestivals() {
  const docs = [
    {
      id: 'festival_001',
      data: {
        name: 'Diwali',
        startDate: daysLater(18),
        endDate: daysLater(23),
        isActive: true,
        advanceOrderDays: 14,
        expectedDemandMultiplier: 3.0,
        relevantCategories: ['Dairy', 'Snacks', 'Beverages', 'Personal Care'],
        notes: 'Highest sales period of the year. Stock up on gifting items and mithai ingredients.',
        createdAt: daysAgo(10),
        createdByUserId: 'uid_owner',
      },
    },
    {
      id: 'festival_002',
      data: {
        name: 'Navratri',
        startDate: daysLater(5),
        endDate: daysLater(14),
        isActive: true,
        advanceOrderDays: 7,
        expectedDemandMultiplier: 2.0,
        relevantCategories: ['Grocery', 'Dairy', 'Fruits & Vegetables'],
        notes: 'High demand for fasting foods — sabudana, rock salt, fruits, dairy.',
        createdAt: daysAgo(15),
        createdByUserId: 'uid_owner',
      },
    },
    {
      id: 'festival_003',
      data: {
        name: 'Ganesh Chaturthi',
        startDate: daysAgo(5),
        endDate: daysLater(2),
        isActive: true,
        advanceOrderDays: 10,
        expectedDemandMultiplier: 2.5,
        relevantCategories: ['Grocery', 'Dairy', 'Snacks'],
        notes: 'Ongoing festival. Demand for modak ingredients and dairy products elevated.',
        createdAt: daysAgo(20),
        createdByUserId: 'uid_owner',
      },
    },
    {
      id: 'festival_004',
      data: {
        name: 'Holi',
        startDate: daysLater(150),
        endDate: daysLater(151),
        isActive: true,
        advanceOrderDays: 14,
        expectedDemandMultiplier: 1.8,
        relevantCategories: ['Beverages', 'Snacks', 'Personal Care'],
        notes: 'Plan ahead for gulal-related personal care and beverage surge.',
        createdAt: daysAgo(5),
        createdByUserId: 'uid_owner',
      },
    },
  ];
  await clearAndSeed('festivals', docs);
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. Festival Demand Alerts
// ─────────────────────────────────────────────────────────────────────────────
async function seedFestivalAlerts() {
  const docs = [
    {
      id: 'alert_001',
      data: {
        festivalId: 'festival_001',
        festivalName: 'Diwali',
        storeId: 'store_01',
        storeName: 'StoreIQ - Andheri Branch',
        productId: 'p01',
        productName: 'Amul Butter 500g',
        currentStock: 45,
        recommendedStock: 150,
        shortfallQuantity: 105,
        estimatedCost: 23625.0,
        isAcknowledged: false,
        createdAt: daysAgo(0),
      },
    },
    {
      id: 'alert_002',
      data: {
        festivalId: 'festival_001',
        festivalName: 'Diwali',
        storeId: 'store_01',
        storeName: 'StoreIQ - Andheri Branch',
        productId: 'p05',
        productName: 'Lays Classic 75g',
        currentStock: 5,
        recommendedStock: 200,
        shortfallQuantity: 195,
        estimatedCost: 3510.0,
        isAcknowledged: false,
        createdAt: daysAgo(0),
      },
    },
    {
      id: 'alert_003',
      data: {
        festivalId: 'festival_002',
        festivalName: 'Navratri',
        storeId: 'store_01',
        storeName: 'StoreIQ - Andheri Branch',
        productId: 'p08',
        productName: 'Mother Dairy Milk 1L',
        currentStock: 3,
        recommendedStock: 80,
        shortfallQuantity: 77,
        estimatedCost: 4466.0,
        isAcknowledged: false,
        createdAt: daysAgo(1),
      },
    },
  ];
  await clearAndSeed('festivalAlerts', docs);
}

// ─────────────────────────────────────────────────────────────────────────────
// Run all seeders
// ─────────────────────────────────────────────────────────────────────────────
async function main() {
  console.log('🌱 Seeding Firestore collections...\n');
  try {
    await seedNotifications();
    await seedFestivals();
    await seedFestivalAlerts();
    console.log('\n✅ Firestore seeded successfully!');
    console.log('\nCollections seeded:');
    console.log('  • notifications    — 7 documents');
    console.log('  • festivals        — 4 documents (Diwali, Navratri, Ganesh Chaturthi, Holi)');
    console.log('  • festivalAlerts   — 3 documents');
  } catch (err) {
    console.error('\n❌ Seeding failed:', err.message);
    process.exit(1);
  } finally {
    process.exit(0);
  }
}

main();
