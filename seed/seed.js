/**
 * StoreIQ — Firebase Seed Script
 * ================================
 * Creates real Firebase Auth accounts + populates all Firestore collections
 * with realistic Indian store data.
 *
 * Run:  node seed.js
 */

const { initializeApp, cert } = require('firebase-admin/app');
const { getAuth }      = require('firebase-admin/auth');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const path = require('path');
const serviceAccount = require('./store-inventory-sale-manage-firebase-adminsdk-fbsvc-2d3176b5ac.json');

// ── Initialise Firebase Admin SDK ─────────────────────────────────────────
initializeApp({
  credential: cert(serviceAccount),
  projectId: 'store-inventory-sale-manage',
});

const auth = getAuth();
const db   = getFirestore();
db.settings({ ignoreUndefinedProperties: true });

// ── Helpers ───────────────────────────────────────────────────────────────
const ts      = (d) => Timestamp.fromDate(d);
const now     = new Date();
const daysAgo = (n) => new Date(now.getTime() - n * 86400000);
const rand    = (a, b) => Math.floor(Math.random() * (b - a + 1)) + a;
const pick    = (arr) => arr[rand(0, arr.length - 1)];

// Batched writes — auto-flush every 400 ops (Firestore limit is 500)
let batchRef   = db.batch();
let batchCount = 0;

async function bset(ref, data) {
  batchRef.set(ref, data);
  batchCount++;
  if (batchCount >= 400) {
    await batchRef.commit();
    batchRef   = db.batch();
    batchCount = 0;
  }
}

async function flushBatch() {
  if (batchCount > 0) {
    await batchRef.commit();
    batchRef   = db.batch();
    batchCount = 0;
  }
}

// Create or reuse a Firebase Auth account
async function upsertAuthUser({ email, password, displayName }) {
  try {
    const existing = await auth.getUserByEmail(email);
    console.log(`  ↩  Exists : ${email}  (${existing.uid})`);
    return existing.uid;
  } catch {
    const u = await auth.createUser({ email, password, displayName });
    console.log(`  ✅ Created: ${email}  (${u.uid})`);
    return u.uid;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA DEFINITIONS
// ═══════════════════════════════════════════════════════════════════════════

const STORES = [
  { id: 'store_01', name: 'StoreIQ — Andheri Branch',    city: 'Mumbai',  state: 'Maharashtra', address: 'Shop 14, Veera Desai Road, Andheri West, Mumbai 400053', pincode: '400053', phone: '+91 98200 11001', email: 'andheri@storeiq.in', openingTime: '09:00', closingTime: '21:00', monthlyTarget: 850000, isActive: true },
  { id: 'store_02', name: 'StoreIQ — Pune Kothrud',      city: 'Pune',    state: 'Maharashtra', address: 'Plot 7, Karve Road, Kothrud, Pune 411038',               pincode: '411038', phone: '+91 98200 22002', email: 'kothrud@storeiq.in',  openingTime: '09:30', closingTime: '21:30', monthlyTarget: 650000, isActive: true },
  { id: 'store_03', name: 'StoreIQ — Nashik College Rd', city: 'Nashik',  state: 'Maharashtra', address: '22 College Road, Nashik 422005',                         pincode: '422005', phone: '+91 98200 33003', email: 'nashik@storeiq.in',   openingTime: '10:00', closingTime: '21:00', monthlyTarget: 450000, isActive: true },
];

const USER_DEFS = [
  { email: 'owner@storeiq.in',              password: 'StoreIQ@2024', name: 'Rajesh Sharma',    phone: '+91 98100 00001', role: 'owner',    assignedStoreId: null       },
  { email: 'admin@storeiq.in',              password: 'StoreIQ@2024', name: 'Priya Nair',       phone: '+91 98100 00002', role: 'admin',    assignedStoreId: null       },
  { email: 'manager.andheri@storeiq.in',    password: 'StoreIQ@2024', name: 'Amit Kulkarni',   phone: '+91 98100 00003', role: 'manager',  assignedStoreId: 'store_01' },
  { email: 'manager.pune@storeiq.in',       password: 'StoreIQ@2024', name: 'Sneha Patil',      phone: '+91 98100 00004', role: 'manager',  assignedStoreId: 'store_02' },
  { email: 'manager.nashik@storeiq.in',     password: 'StoreIQ@2024', name: 'Vikram Desai',     phone: '+91 98100 00005', role: 'manager',  assignedStoreId: 'store_03' },
  { email: 'emp1.andheri@storeiq.in',       password: 'StoreIQ@2024', name: 'Rohit Joshi',      phone: '+91 98100 00006', role: 'employee', assignedStoreId: 'store_01' },
  { email: 'emp2.andheri@storeiq.in',       password: 'StoreIQ@2024', name: 'Kavya Mehta',      phone: '+91 98100 00007', role: 'employee', assignedStoreId: 'store_01' },
  { email: 'emp1.pune@storeiq.in',          password: 'StoreIQ@2024', name: 'Suresh Rane',      phone: '+91 98100 00008', role: 'employee', assignedStoreId: 'store_02' },
  { email: 'emp2.pune@storeiq.in',          password: 'StoreIQ@2024', name: 'Pooja Sharma',     phone: '+91 98100 00009', role: 'employee', assignedStoreId: 'store_02' },
  { email: 'emp1.nashik@storeiq.in',        password: 'StoreIQ@2024', name: 'Nilesh More',      phone: '+91 98100 00010', role: 'employee', assignedStoreId: 'store_03' },
  { email: 'emp2.nashik@storeiq.in',        password: 'StoreIQ@2024', name: 'Anita Wagh',       phone: '+91 98100 00011', role: 'employee', assignedStoreId: 'store_03' },
];

const PRODUCTS = [
  { id: 'prod_001', name: 'Tata Salt',               category: 'Grocery',            unit: 'kg',     costPrice:  18, sellingPrice:  24, minStock:  50, barcode: '8901234567001', brand: 'Tata',           description: 'Iodised salt 1kg'              },
  { id: 'prod_002', name: 'Aashirvaad Atta',          category: 'Grocery',            unit: 'kg',     costPrice:  52, sellingPrice:  65, minStock:  30, barcode: '8901234567002', brand: 'Aashirvaad',     description: 'Whole wheat flour 5kg'         },
  { id: 'prod_003', name: 'Fortune Soyabean Oil',     category: 'Grocery',            unit: 'litre',  costPrice: 115, sellingPrice: 135, minStock:  25, barcode: '8901234567003', brand: 'Fortune',        description: 'Refined soyabean oil 1L'       },
  { id: 'prod_004', name: 'Tata Sampann Chana Dal',   category: 'Grocery',            unit: 'kg',     costPrice:  68, sellingPrice:  85, minStock:  20, barcode: '8901234567004', brand: 'Tata',           description: 'Bengal gram dal 1kg'           },
  { id: 'prod_005', name: 'India Gate Basmati Rice',  category: 'Grocery',            unit: 'kg',     costPrice:  95, sellingPrice: 120, minStock:  30, barcode: '8901234567005', brand: 'India Gate',     description: 'Premium basmati rice 5kg'      },
  { id: 'prod_006', name: 'Tata Tea Gold',            category: 'Beverages',          unit: 'pack',   costPrice: 175, sellingPrice: 220, minStock:  20, barcode: '8901234567006', brand: 'Tata Tea',       description: 'Premium tea leaves 500g'       },
  { id: 'prod_007', name: 'Nescafe Classic',          category: 'Beverages',          unit: 'bottle', costPrice: 185, sellingPrice: 230, minStock:  15, barcode: '8901234567007', brand: 'Nescafe',        description: 'Instant coffee 200g'           },
  { id: 'prod_008', name: 'Tropicana Orange Juice',   category: 'Beverages',          unit: 'litre',  costPrice:  68, sellingPrice:  90, minStock:  20, barcode: '8901234567008', brand: 'Tropicana',      description: 'Orange juice 1L pack'          },
  { id: 'prod_009', name: 'Amul Full Cream Milk',     category: 'Dairy',              unit: 'litre',  costPrice:  26, sellingPrice:  32, minStock:  80, barcode: '8901234567009', brand: 'Amul',           description: 'Full cream milk 500ml'         },
  { id: 'prod_010', name: 'Amul Butter',              category: 'Dairy',              unit: 'pack',   costPrice:  48, sellingPrice:  60, minStock:  25, barcode: '8901234567010', brand: 'Amul',           description: 'Salted butter 100g'            },
  { id: 'prod_011', name: 'Nestle Yogurt',            category: 'Dairy',              unit: 'pcs',    costPrice:  32, sellingPrice:  42, minStock:  30, barcode: '8901234567011', brand: 'Nestle',         description: 'Fruit yogurt 100g'             },
  { id: 'prod_012', name: 'Britannia Cheese Slices',  category: 'Dairy',              unit: 'pack',   costPrice:  82, sellingPrice: 105, minStock:  15, barcode: '8901234567012', brand: 'Britannia',      description: 'Processed cheese 200g'         },
  { id: 'prod_013', name: "Lay's Classic Salted",     category: 'Snacks',             unit: 'pack',   costPrice:  18, sellingPrice:  25, minStock:  60, barcode: '8901234567013', brand: "Lay's",          description: 'Potato chips 26g'              },
  { id: 'prod_014', name: "Haldiram's Bhujia",        category: 'Snacks',             unit: 'pack',   costPrice:  52, sellingPrice:  70, minStock:  40, barcode: '8901234567014', brand: "Haldiram's",     description: 'Sev bhujia 200g'               },
  { id: 'prod_015', name: 'Parle-G Biscuits',         category: 'Snacks',             unit: 'pack',   costPrice:   8, sellingPrice:  10, minStock: 100, barcode: '8901234567015', brand: 'Parle',          description: 'Glucose biscuits 100g'         },
  { id: 'prod_016', name: 'Maggi Masala Noodles',     category: 'Snacks',             unit: 'pack',   costPrice:  12, sellingPrice:  15, minStock:  80, barcode: '8901234567016', brand: 'Nestle',         description: 'Masala noodles 70g'            },
  { id: 'prod_017', name: 'Britannia Whole Wheat Bread', category: 'Bakery',          unit: 'pack',   costPrice:  32, sellingPrice:  42, minStock:  30, barcode: '8901234567017', brand: 'Britannia',      description: 'Whole wheat bread 400g'        },
  { id: 'prod_018', name: 'English Oven Croissant',   category: 'Bakery',             unit: 'pcs',    costPrice:  18, sellingPrice:  25, minStock:  20, barcode: '8901234567018', brand: 'English Oven',   description: 'Butter croissant'              },
  { id: 'prod_019', name: 'Dove Moisturising Bar',    category: 'Personal Care',      unit: 'pcs',    costPrice:  42, sellingPrice:  58, minStock:  30, barcode: '8901234567019', brand: 'Dove',           description: 'Moisturising beauty bar 100g'  },
  { id: 'prod_020', name: 'Colgate MaxFresh',         category: 'Personal Care',      unit: 'pcs',    costPrice:  75, sellingPrice:  95, minStock:  25, barcode: '8901234567020', brand: 'Colgate',        description: 'Toothpaste 150g'               },
  { id: 'prod_021', name: 'Head & Shoulders Shampoo', category: 'Personal Care',      unit: 'bottle', costPrice: 155, sellingPrice: 195, minStock:  20, barcode: '8901234567021', brand: 'Head&Shoulders', description: 'Anti-dandruff shampoo 340ml'   },
  { id: 'prod_022', name: 'Surf Excel Easy Wash',     category: 'Household',          unit: 'kg',     costPrice:  95, sellingPrice: 122, minStock:  25, barcode: '8901234567022', brand: 'Surf Excel',     description: 'Detergent powder 1kg'          },
  { id: 'prod_023', name: 'Vim Dishwash Gel',         category: 'Household',          unit: 'bottle', costPrice:  62, sellingPrice:  82, minStock:  20, barcode: '8901234567023', brand: 'Vim',            description: 'Dish cleaning gel 500ml'       },
  { id: 'prod_024', name: 'Colin Glass Cleaner',      category: 'Household',          unit: 'bottle', costPrice:  72, sellingPrice:  95, minStock:  15, barcode: '8901234567024', brand: 'Colin',          description: 'Glass and surface cleaner 500ml'},
  { id: 'prod_025', name: 'Fresh Tomatoes',           category: 'Fruits & Vegetables',unit: 'kg',     costPrice:  22, sellingPrice:  35, minStock:  20, barcode: '8901234567025', brand: 'Fresh',          description: 'Fresh tomatoes per kg'         },
  { id: 'prod_026', name: 'Fresh Onions',             category: 'Fruits & Vegetables',unit: 'kg',     costPrice:  18, sellingPrice:  28, minStock:  30, barcode: '8901234567026', brand: 'Fresh',          description: 'Fresh onions per kg'           },
  { id: 'prod_027', name: 'Bananas',                  category: 'Fruits & Vegetables',unit: 'dozen',  costPrice:  28, sellingPrice:  40, minStock:  20, barcode: '8901234567027', brand: 'Fresh',          description: 'Fresh bananas 1 dozen'         },
  { id: 'prod_028', name: 'Dabur Honey',              category: 'Health & Medicine',  unit: 'bottle', costPrice: 128, sellingPrice: 165, minStock:  15, barcode: '8901234567028', brand: 'Dabur',          description: 'Pure honey 500g'               },
  { id: 'prod_029', name: 'Dabur Chyawanprash',       category: 'Health & Medicine',  unit: 'bottle', costPrice: 175, sellingPrice: 225, minStock:  10, barcode: '8901234567029', brand: 'Dabur',          description: 'Ayurvedic health supplement 500g'},
  { id: 'prod_030', name: 'Electral ORS Powder',      category: 'Health & Medicine',  unit: 'pack',   costPrice:  22, sellingPrice:  30, minStock:  20, barcode: '8901234567030', brand: 'Electral',       description: 'Oral rehydration salts 21.8g'  },
];

const SUPPLIERS = [
  { id: 'sup_001', name: 'Maharashtra FMCG Distributors', contactPerson: 'Ganesh Iyer',   phone: '+91 98200 55001', email: 'mfd@distrib.in',       address: 'MIDC, Andheri East, Mumbai',  categories: ['Grocery', 'Snacks', 'Beverages'], paymentTerms: '30 days', rating: 4.5 },
  { id: 'sup_002', name: 'Amul Dairy Distributors',       contactPerson: 'Ramesh Patel',  phone: '+91 98200 55002', email: 'amul.dist@distrib.in', address: 'APMC, Vashi, Navi Mumbai',    categories: ['Dairy'],                          paymentTerms: '7 days',  rating: 4.8 },
  { id: 'sup_003', name: 'Fresh Produce Hub',             contactPerson: 'Laxmi Devi',    phone: '+91 98200 55003', email: 'fresh@produce.in',     address: 'APMC Market, Pune',           categories: ['Fruits & Vegetables'],            paymentTerms: '3 days',  rating: 4.2 },
  { id: 'sup_004', name: 'HUL Direct Distributor',        contactPerson: 'Manish Shah',   phone: '+91 98200 55004', email: 'hul@direct.in',        address: 'BKC, Mumbai',                 categories: ['Personal Care', 'Household'],     paymentTerms: '30 days', rating: 4.7 },
  { id: 'sup_005', name: 'Nestle Premium Foods',          contactPerson: 'Arun Kumar',    phone: '+91 98200 55005', email: 'nestle@premium.in',    address: 'Gurgaon Industrial Area',     categories: ['Snacks', 'Dairy', 'Beverages'],   paymentTerms: '45 days', rating: 4.6 },
];

const CUSTOMER_DEFS = [
  { phone: '9820001001', name: 'Meera Krishnan',    email: 'meera.k@gmail.com',   storeId: 'store_01', totalPurchases: 12450, visitCount: 18 },
  { phone: '9820001002', name: 'Arjun Malhotra',    email: 'arjun.m@gmail.com',   storeId: 'store_01', totalPurchases:  8900, visitCount: 12 },
  { phone: '9820001003', name: 'Sunita Rao',         email: 'sunita.r@gmail.com',  storeId: 'store_01', totalPurchases: 22100, visitCount: 35 },
  { phone: '9820001004', name: 'Deepak Verma',       email: 'deepak.v@gmail.com',  storeId: 'store_01', totalPurchases:  5600, visitCount:  8 },
  { phone: '9820001005', name: 'Ananya Singh',       email: 'ananya.s@gmail.com',  storeId: 'store_01', totalPurchases: 16800, visitCount: 24 },
  { phone: '9820001006', name: 'Ravi Tiwari',        email: 'ravi.t@gmail.com',    storeId: 'store_01', totalPurchases:  3200, visitCount:  5 },
  { phone: '9820001007', name: 'Priya Joshi',        email: 'priya.j@gmail.com',   storeId: 'store_02', totalPurchases: 19500, visitCount: 28 },
  { phone: '9820001008', name: 'Kiran Gupta',        email: 'kiran.g@gmail.com',   storeId: 'store_02', totalPurchases:  7800, visitCount: 11 },
  { phone: '9820001009', name: 'Nisha Bhatt',        email: 'nisha.b@gmail.com',   storeId: 'store_02', totalPurchases: 11200, visitCount: 16 },
  { phone: '9820001010', name: 'Sanjay Dubey',       email: 'sanjay.d@gmail.com',  storeId: 'store_02', totalPurchases:  4500, visitCount:  7 },
  { phone: '9820001011', name: 'Lakshmi Iyer',       email: 'lakshmi.i@gmail.com', storeId: 'store_02', totalPurchases: 28900, visitCount: 42 },
  { phone: '9820001012', name: 'Rahul Saxena',       email: 'rahul.s@gmail.com',   storeId: 'store_02', totalPurchases:  6700, visitCount:  9 },
  { phone: '9820001013', name: 'Geeta Pillai',       email: 'geeta.p@gmail.com',   storeId: 'store_03', totalPurchases: 14300, visitCount: 21 },
  { phone: '9820001014', name: 'Mohan Das',          email: 'mohan.d@gmail.com',   storeId: 'store_03', totalPurchases:  9100, visitCount: 13 },
  { phone: '9820001015', name: 'Vandana Choudhary',  email: 'vandana.c@gmail.com', storeId: 'store_03', totalPurchases: 21600, visitCount: 31 },
  { phone: '9820001016', name: 'Ajit Kaur',          email: 'ajit.k@gmail.com',    storeId: 'store_03', totalPurchases:  5100, visitCount:  7 },
  { phone: '9820001017', name: 'Sneha Reddy',        email: 'sneha.r@gmail.com',   storeId: 'store_03', totalPurchases: 17400, visitCount: 25 },
  { phone: '9820001018', name: 'Tarun Bose',         email: 'tarun.b@gmail.com',   storeId: 'store_01', totalPurchases:  8300, visitCount: 12 },
  { phone: '9820001019', name: 'Radha Nambiar',      email: 'radha.n@gmail.com',   storeId: 'store_02', totalPurchases: 13600, visitCount: 19 },
  { phone: '9820001020', name: 'Prakash Yadav',      email: 'prakash.y@gmail.com', storeId: 'store_03', totalPurchases:  6200, visitCount:  9 },
];

// ═══════════════════════════════════════════════════════════════════════════
// MAIN
// ═══════════════════════════════════════════════════════════════════════════
async function main() {
  console.log('\n🚀  StoreIQ Firebase Seed Script');
  console.log('=================================\n');

  // ── 1. Stores ────────────────────────────────────────────────────────────
  console.log('📦  Seeding stores...');
  for (const { id, ...data } of STORES) {
    await bset(db.collection('stores').doc(id), { ...data, createdAt: ts(daysAgo(180)) });
    console.log(`     ✅ ${data.name}`);
  }
  await flushBatch();

  // ── 2. Auth users + Firestore user docs ─────────────────────────────────
  console.log('\n👤  Creating Firebase Auth accounts...');
  const uidMap = {}; // email → uid
  for (const user of USER_DEFS) {
    const uid = await upsertAuthUser({ email: user.email, password: user.password, displayName: user.name });
    uidMap[user.email] = uid;

    // Set JWT custom claims
    const storeAccess = (user.role === 'owner' || user.role === 'admin') ? 'all' : user.assignedStoreId;
    await auth.setCustomUserClaims(uid, { role: user.role, assignedStoreId: user.assignedStoreId, storeAccess });

    // Firestore user document
    await bset(db.collection('users').doc(uid), {
      name:            user.name,
      email:           user.email,
      phone:           user.phone,
      role:            user.role,
      assignedStoreId: user.assignedStoreId,
      isActive:        true,
      createdAt:       ts(daysAgo(120)),
      lastLogin:       ts(daysAgo(rand(0, 3))),
      fcmToken:        null,
    });
  }
  await flushBatch();

  // ── 3. Products ──────────────────────────────────────────────────────────
  console.log('\n🛍   Seeding 30 products...');
  for (const { id, ...data } of PRODUCTS) {
    await bset(db.collection('products').doc(id), { ...data, isActive: true, createdAt: ts(daysAgo(150)) });
  }
  await flushBatch();
  console.log('     ✅ 30 products created');

  // ── 4. Inventory (30 products × 3 stores = 90 records) ──────────────────
  console.log('\n📊  Seeding inventory...');
  for (const store of STORES) {
    for (const prod of PRODUCTS) {
      const currentStock = rand(prod.minStock + 5, prod.minStock * 4);
      await bset(db.collection('inventory').doc(`inv_${store.id}_${prod.id}`), {
        storeId:       store.id,
        productId:     prod.id,
        productName:   prod.name,
        currentStock,
        minStockLevel: prod.minStock,
        reservedStock: 0,
        lastRestocked: ts(daysAgo(rand(5, 30))),
        lastUpdated:   ts(daysAgo(rand(0, 2))),
        batchNumber:   `BATCH-${rand(1000, 9999)}`,
        expiryDate:    ts(new Date(now.getTime() + rand(30, 365) * 86400000)),
        supplierId:    SUPPLIERS[rand(0, 4)].id,
        costPrice:     prod.costPrice,
        sellingPrice:  prod.sellingPrice,
      });
    }
  }
  await flushBatch();
  console.log('     ✅ 90 inventory records created');

  // ── 5. Stock Movements (40 per store = 120 total) ────────────────────────
  console.log('\n📈  Seeding stock movements...');
  const allUids  = Object.values(uidMap);
  const movTypes = ['received', 'sold', 'adjusted', 'damaged'];
  for (const store of STORES) {
    for (let i = 0; i < 40; i++) {
      const prod   = pick(PRODUCTS);
      const mvType = pick(movTypes);
      await bset(db.collection('stockMovements').doc(`mov_${store.id}_${i}`), {
        storeId:     store.id,
        productId:   prod.id,
        productName: prod.name,
        type:        mvType,
        quantity:    mvType === 'received' ? rand(20, 100) : rand(1, 15),
        reason:      mvType === 'adjusted' ? 'Physical count correction' : null,
        performedBy: allUids[rand(2, allUids.length - 1)],
        timestamp:   ts(daysAgo(rand(0, 60))),
        notes:       null,
      });
    }
  }
  await flushBatch();
  console.log('     ✅ 120 stock movements created');

  // ── 6. Suppliers ─────────────────────────────────────────────────────────
  console.log('\n🏭  Seeding suppliers...');
  for (const { id, ...data } of SUPPLIERS) {
    await bset(db.collection('suppliers').doc(id), { ...data, isActive: true, createdAt: ts(daysAgo(200)) });
  }
  await flushBatch();
  console.log('     ✅ 5 suppliers created');

  // ── 7. Customers + Loyalty ───────────────────────────────────────────────
  console.log('\n👥  Seeding customers & loyalty accounts...');
  for (const cust of CUSTOMER_DEFS) {
    const custId = `cust_${cust.phone}`;

    await bset(db.collection('customers').doc(custId), {
      name:           cust.name,
      phone:          cust.phone,
      email:          cust.email,
      primaryStoreId: cust.storeId,
      totalPurchases: cust.totalPurchases,
      visitCount:     cust.visitCount,
      lastVisit:      ts(daysAgo(rand(1, 15))),
      createdAt:      ts(daysAgo(rand(30, 200))),
    });

    const points   = Math.floor(cust.totalPurchases);
    const redeemed = Math.floor(points * 0.3);
    await bset(db.collection('loyaltyAccounts').doc(custId), {
      customerId:     custId,
      phone:          cust.phone,
      totalEarned:    points,
      totalRedeemed:  redeemed,
      currentBalance: points - redeemed,
      tier:           points > 15000 ? 'gold' : points > 5000 ? 'silver' : 'bronze',
      createdAt:      ts(daysAgo(rand(30, 200))),
      lastUpdated:    ts(daysAgo(rand(0, 10))),
    });

    // 4–7 loyalty transactions per customer
    for (let i = 0; i < rand(4, 7); i++) {
      const earned = rand(50, 500);
      const isRedeem = i % 4 === 0;
      await bset(db.collection('loyaltyTransactions').doc(`ltxn_${custId}_${i}`), {
        customerId:  custId,
        phone:       cust.phone,
        storeId:     cust.storeId,
        type:        isRedeem ? 'redeemed' : 'earned',
        points:      isRedeem ? rand(100, 300) : earned,
        saleId:      `sale_${custId}_${i}`,
        timestamp:   ts(daysAgo(rand(1, 60))),
        description: isRedeem ? 'Points redeemed at checkout' : `Earned on purchase of Rs.${earned * 10}`,
      });
    }
  }
  await flushBatch();
  console.log('     ✅ 20 customers + loyalty accounts + transactions created');

  // ── 8. Sales — 30 days, 5–10 per day per store (~600–900 total) ──────────
  console.log('\n💰  Seeding sales (30 days × 3 stores)...');
  const payMethods = ['cash', 'upi', 'card', 'wallet'];
  let saleCount = 0;
  for (const store of STORES) {
    const storeCusts = CUSTOMER_DEFS.filter(c => c.storeId === store.id);
    for (let day = 0; day < 30; day++) {
      const numSales = rand(5, 10);
      for (let s = 0; s < numSales; s++) {
        // Pick 1–3 unique products
        const seen = new Set();
        const items = [];
        for (let p = 0; p < rand(1, 3); p++) {
          const prod = pick(PRODUCTS);
          if (seen.has(prod.id)) continue;
          seen.add(prod.id);
          const qty = rand(1, 5);
          items.push({ productId: prod.id, productName: prod.name, quantity: qty, unitPrice: prod.sellingPrice, totalPrice: prod.sellingPrice * qty });
        }
        const subtotal    = items.reduce((sum, i) => sum + i.totalPrice, 0);
        const discount    = Math.floor(subtotal * (rand(0, 8) / 100));
        const loyaltyUsed = rand(0, 1) ? rand(0, Math.min(50, Math.floor(subtotal * 0.1))) : 0;
        const total       = subtotal - discount - loyaltyUsed;
        const cust        = storeCusts.length ? pick(storeCusts) : null;
        const saleDate    = new Date(now.getTime() - day * 86400000 - rand(0, 43200000));

        await bset(db.collection('sales').doc(`sale_${store.id}_d${day}_s${s}`), {
          storeId:              store.id,
          customerId:           cust ? `cust_${cust.phone}` : null,
          customerName:         cust ? cust.name : 'Walk-in Customer',
          items,
          subtotal,
          discount,
          loyaltyPointsUsed:    loyaltyUsed,
          totalAmount:          total,
          paymentMethod:        pick(payMethods),
          paymentStatus:        'completed',
          loyaltyPointsEarned:  Math.floor(total),
          processedBy:          allUids[rand(5, allUids.length - 1)],
          timestamp:            ts(saleDate),
          receiptNumber:        `REC-${store.id.slice(-2).toUpperCase()}-${String(day * 100 + s).padStart(5, '0')}`,
        });
        saleCount++;
      }
    }
    await flushBatch(); // flush per store to stay well under limits
  }
  console.log(`     ✅ ${saleCount} sales records created`);

  // ── 9. Damaged Products ──────────────────────────────────────────────────
  console.log('\n🗑   Seeding damaged products...');
  const damageReasons = ['Broken/Cracked packaging', 'Expired product', 'Damaged in transit', 'Manufacturing defect', 'Water damage'];
  let damCount = 0;
  for (const store of STORES) {
    for (let i = 0; i < 5; i++) {
      const prod = pick(PRODUCTS);
      const qty  = rand(1, 5);
      await bset(db.collection('damagedProducts').doc(`dam_${store.id}_${i}`), {
        storeId:       store.id,
        productId:     prod.id,
        productName:   prod.name,
        quantity:      qty,
        reason:        pick(damageReasons),
        supplierId:    SUPPLIERS[rand(0, 4)].id,
        reportedBy:    allUids[rand(2, 4)],
        reportedAt:    ts(daysAgo(rand(1, 30))),
        resolved:      i < 2,
        resolvedAt:    i < 2 ? ts(daysAgo(rand(0, 5))) : null,
        estimatedLoss: prod.costPrice * qty,
        notes:         `Batch ${rand(1000, 9999)} inspection`,
      });
      damCount++;
    }
  }
  await flushBatch();
  console.log(`     ✅ ${damCount} damaged product records created`);

  // ── 10. Notifications ────────────────────────────────────────────────────
  console.log('\n🔔  Seeding notifications...');
  const notifTemplates = [
    { title: 'Low Stock Alert',         body: 'Maggi Noodles is running low — 8 units remaining.',              type: 'low_stock' },
    { title: 'Sale Completed',          body: 'Sale of Rs.1,240 processed successfully.',                       type: 'sale'      },
    { title: 'Transfer Approved',       body: 'Transfer of 50 units of Parle-G approved from Pune to Nashik.', type: 'transfer'  },
    { title: 'Restock Required',        body: 'Amul Milk below minimum threshold. Please reorder.',             type: 'low_stock' },
    { title: 'Monthly Target — 68%',    body: 'Store is at 68% of monthly target with 8 days remaining.',       type: 'target'    },
    { title: 'Damaged Goods Reported',  body: '3 units of Dove Soap flagged. Pending supplier resolution.',     type: 'damaged'   },
  ];
  let notifCount = 0;
  for (const store of STORES) {
    for (let i = 0; i < 4; i++) {
      const tmpl = pick(notifTemplates);
      await bset(db.collection('notifications').doc(`notif_${store.id}_${i}`), {
        title:         tmpl.title,
        body:          tmpl.body,
        type:          tmpl.type,
        targetStoreId: store.id,
        targetUserId:  null,
        isRead:        i < 2,
        createdAt:     ts(daysAgo(rand(0, 7))),
        actionUrl:     null,
      });
      notifCount++;
    }
  }
  await flushBatch();
  console.log(`     ✅ ${notifCount} notifications created`);

  // ── Done ─────────────────────────────────────────────────────────────────
  console.log('\n✅  ══════════════════════════════════════════════');
  console.log('    ALL DATA SEEDED SUCCESSFULLY INTO FIREBASE!');
  console.log('════════════════════════════════════════════════\n');

  console.log('📋  Login credentials (password for all: StoreIQ@2024)\n');
  console.log('   Role      │ Email');
  console.log('   ──────────┼──────────────────────────────────────');
  for (const u of USER_DEFS) {
    console.log(`   ${u.role.padEnd(9)} │ ${u.email}`);
  }

  console.log('\n🔗  Check your data here:');
  console.log('   Auth:      https://console.firebase.google.com/project/store-inventory-sale-manage/authentication/users');
  console.log('   Firestore: https://console.firebase.google.com/project/store-inventory-sale-manage/firestore/data\n');

  process.exit(0);
}

main().catch(err => {
  console.error('\n❌  Seed failed:', err.message || err);
  console.error(err.stack);
  process.exit(1);
});
