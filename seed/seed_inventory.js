/**
 * seed_inventory.js
 *
 * Seeds Firestore with complete inventory, products, and stock data
 * for testing the Store Inventory Management System.
 *
 * Run from the seed/ directory:
 *   node seed_inventory.js
 */

const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const serviceAccount = require('./store-inventory-sale-manage-firebase-adminsdk-fbsvc-2d3176b5ac.json');

initializeApp({
  credential: cert(serviceAccount),
  projectId: 'store-inventory-sale-manage',
});

const db = getFirestore();

const now = () => Timestamp.now();
const daysAgo = (n) => Timestamp.fromDate(new Date(Date.now() - n * 86400000));

// ─────────────────────────────────────────────────────────────────────────────
// Helper Functions
// ─────────────────────────────────────────────────────────────────────────────

async function clearCollection(collectionName) {
  console.log(`\nClearing ${collectionName}...`);
  const batch = db.batch();
  const existing = await db.collection(collectionName).limit(500).get();
  existing.docs.forEach(d => batch.delete(d.ref));
  await batch.commit();
  console.log(`  ✓ Cleared ${existing.size} documents`);
}

async function seedCollection(collectionName, docs) {
  console.log(`\nSeeding ${collectionName}...`);
  const batch = db.batch();
  docs.forEach(({ id, data }) => {
    const ref = id ? db.collection(collectionName).doc(id) : db.collection(collectionName).doc();
    batch.set(ref, data);
  });
  await batch.commit();
  console.log(`  ✓ ${docs.length} documents written`);
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. Products Data
// ─────────────────────────────────────────────────────────────────────────────

const products = [
  {
    id: 'p01',
    data: {
      name: 'Tata Salt 1kg',
      brand: 'Tata',
      category: 'Groceries',
      description: 'Premium iodized salt',
      sellingPrice: 25.0,
      mrp: 28.0,
      barcode: '890123456781',
      sku: 'SALT-TATA-1KG',
      imageUrl: 'https://via.placeholder.com/200x200.png?text=Tata+Salt',
      isActive: true,
      createdAt: daysAgo(30),
      updatedAt: now(),
    },
  },
  {
    id: 'p02',
    data: {
      name: 'Amul Butter 100g',
      brand: 'Amul',
      category: 'Dairy',
      description: 'Fresh salted butter',
      sellingPrice: 60.0,
      mrp: 65.0,
      barcode: '890123456782',
      sku: 'BTR-AMUL-100G',
      imageUrl: 'https://via.placeholder.com/200x200.png?text=Amul+Butter',
      isActive: true,
      createdAt: daysAgo(30),
      updatedAt: now(),
    },
  },
  {
    id: 'p03',
    data: {
      name: 'Aashirvaad Atta 5kg',
      brand: 'Aashirvaad',
      category: 'Groceries',
      description: 'Whole wheat flour',
      sellingPrice: 285.0,
      mrp: 300.0,
      barcode: '890123456783',
      sku: 'ATTA-AASH-5KG',
      imageUrl: 'https://via.placeholder.com/200x200.png?text=Aashirvaad',
      isActive: true,
      createdAt: daysAgo(30),
      updatedAt: now(),
    },
  },
  {
    id: 'p04',
    data: {
      name: 'Britannia Good Day 100g',
      brand: 'Britannia',
      category: 'Snacks',
      description: 'Butter cookies',
      sellingPrice: 30.0,
      mrp: 35.0,
      barcode: '890123456784',
      sku: 'CKI-BRIT-100G',
      imageUrl: 'https://via.placeholder.com/200x200.png?text=Good+Day',
      isActive: true,
      createdAt: daysAgo(30),
      updatedAt: now(),
    },
  },
  {
    id: 'p05',
    data: {
      name: 'Lays Classic 75g',
      brand: 'Lays',
      category: 'Snacks',
      description: 'Potato chips',
      sellingPrice: 20.0,
      mrp: 20.0,
      barcode: '890123456785',
      sku: 'CHIPS-LAYS-75G',
      imageUrl: 'https://via.placeholder.com/200x200.png?text=Lays',
      isActive: true,
      createdAt: daysAgo(30),
      updatedAt: now(),
    },
  },
  {
    id: 'p06',
    data: {
      name: 'Coca-Cola 2L',
      brand: 'Coca-Cola',
      category: 'Beverages',
      description: 'Soft drink',
      sellingPrice: 85.0,
      mrp: 90.0,
      barcode: '890123456786',
      sku: 'BEV-COKE-2L',
      imageUrl: 'https://via.placeholder.com/200x200.png?text=Coca-Cola',
      isActive: true,
      createdAt: daysAgo(30),
      updatedAt: now(),
    },
  },
  {
    id: 'p07',
    data: {
      name: 'Maggi Noodles 70g',
      brand: 'Maggi',
      category: 'Instant Food',
      description: 'Masala noodles',
      sellingPrice: 12.0,
      mrp: 14.0,
      barcode: '890123456787',
      sku: 'NOOD-MAGG-70G',
      imageUrl: 'https://via.placeholder.com/200x200.png?text=Maggi',
      isActive: true,
      createdAt: daysAgo(30),
      updatedAt: now(),
    },
  },
  {
    id: 'p08',
    data: {
      name: 'Mother Dairy Milk 1L',
      brand: 'Mother Dairy',
      category: 'Dairy',
      description: 'Full cream milk',
      sellingPrice: 62.0,
      mrp: 65.0,
      barcode: '890123456788',
      sku: 'MILK-MD-1L',
      imageUrl: 'https://via.placeholder.com/200x200.png?text=MD+Milk',
      isActive: true,
      createdAt: daysAgo(30),
      updatedAt: now(),
    },
  },
  {
    id: 'p09',
    data: {
      name: 'Parle-G Biscuits 200g',
      brand: 'Parle',
      category: 'Snacks',
      description: 'Glucose biscuits',
      sellingPrice: 20.0,
      mrp: 22.0,
      barcode: '890123456789',
      sku: 'BISC-PARL-200G',
      imageUrl: 'https://via.placeholder.com/200x200.png?text=Parle-G',
      isActive: true,
      createdAt: daysAgo(30),
      updatedAt: now(),
    },
  },
  {
    id: 'p10',
    data: {
      name: 'Surf Excel 1kg',
      brand: 'Surf Excel',
      category: 'Household',
      description: 'Detergent powder',
      sellingPrice: 180.0,
      mrp: 200.0,
      barcode: '890123456790',
      sku: 'DET-SURF-1KG',
      imageUrl: 'https://via.placeholder.com/200x200.png?text=Surf+Excel',
      isActive: true,
      createdAt: daysAgo(30),
      updatedAt: now(),
    },
  },
  {
    id: 'p11',
    data: {
      name: 'Colgate Toothpaste 150g',
      brand: 'Colgate',
      category: 'Personal Care',
      description: 'Total advanced health',
      sellingPrice: 95.0,
      mrp: 105.0,
      barcode: '890123456791',
      sku: 'TP-COLG-150G',
      imageUrl: 'https://via.placeholder.com/200x200.png?text=Colgate',
      isActive: true,
      createdAt: daysAgo(30),
      updatedAt: now(),
    },
  },
  {
    id: 'p12',
    data: {
      name: 'Red Label Tea 500g',
      brand: 'Red Label',
      category: 'Beverages',
      description: 'Premium tea leaves',
      sellingPrice: 210.0,
      mrp: 230.0,
      barcode: '890123456792',
      sku: 'TEA-RL-500G',
      imageUrl: 'https://via.placeholder.com/200x200.png?text=Red+Label',
      isActive: true,
      createdAt: daysAgo(30),
      updatedAt: now(),
    },
  },
];

// ─────────────────────────────────────────────────────────────────────────────
// 2. Stores Data
// ─────────────────────────────────────────────────────────────────────────────

const stores = [
  {
    id: 'store_01',
    data: {
      name: 'Store 1: Downtown Central',
      address: '123 Main Street, Downtown',
      city: 'Mumbai',
      state: 'Maharashtra',
      pincode: '400001',
      phone: '+91 22 1234 5678',
      email: 'downtown@store.com',
      isActive: true,
      createdAt: daysAgo(90),
      updatedAt: now(),
    },
  },
  {
    id: 'store_02',
    data: {
      name: 'Store 2: Suburban Hub',
      address: '456 Park Avenue, Andheri',
      city: 'Mumbai',
      state: 'Maharashtra',
      pincode: '400058',
      phone: '+91 22 8765 4321',
      email: 'suburban@store.com',
      isActive: true,
      createdAt: daysAgo(90),
      updatedAt: now(),
    },
  },
];

// ─────────────────────────────────────────────────────────────────────────────
// 3. Inventory Data (Stock levels for each store)
// ─────────────────────────────────────────────────────────────────────────────

function generateInventory() {
  const inventory = [];
  
  stores.forEach(store => {
    products.forEach((product, index) => {
      // Generate varied stock levels - some normal, some low, some out
      let currentStock;
      let minStockLevel;
      
      if (index % 5 === 0) {
        // Out of stock (20%)
        currentStock = 0;
        minStockLevel = 20;
      } else if (index % 3 === 0) {
        // Low stock (33%)
        currentStock = 5 + Math.floor(Math.random() * 5); // 5-10 units
        minStockLevel = 20;
      } else {
        // Normal stock (47%)
        currentStock = 50 + Math.floor(Math.random() * 100); // 50-150 units
        minStockLevel = 20;
      }
      
      inventory.push({
        id: `inv_${store.id}_${product.id}`,
        data: {
          storeId: store.id,
          productId: product.id,
          productName: product.data.name,
          category: product.data.category,
          currentStock: currentStock,
          minimumStockLevel: minStockLevel,
          maximumStockLevel: 200,
          imageUrl: product.data.imageUrl,
          lastUpdated: now(),
        },
      });
    });
  });
  
  return inventory;
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. Stock Movements (Recent history)
// ─────────────────────────────────────────────────────────────────────────────

function generateStockMovements() {
  const movements = [];
  let movementId = 1;
  
  // Generate some recent stock movements for context
  stores.forEach(store => {
    products.slice(0, 5).forEach(product => {
      // Receipt
      movements.push({
        data: {
          storeId: store.id,
          productId: product.id,
          productName: product.data.name,
          type: 'receipt',
          quantity: 50,
          stockBefore: 20,
          stockAfter: 70,
          reason: 'Restock from supplier',
          userId: 'uid_manager',
          userName: 'Store Manager',
          timestamp: daysAgo(5),
        },
      });
      
      // Sale
      movements.push({
        data: {
          storeId: store.id,
          productId: product.id,
          productName: product.data.name,
          type: 'sale',
          quantity: 3,
          stockBefore: 70,
          stockAfter: 67,
          reason: null,
          referenceId: `sale_${movementId}`,
          userId: 'uid_employee',
          userName: 'Employee',
          timestamp: daysAgo(2),
        },
      });
      
      movementId++;
    });
  });
  
  return movements;
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Execution
// ─────────────────────────────────────────────────────────────────────────────

async function main() {
  console.log('\n🌱 Starting inventory seeding process...\n');
  console.log('═══════════════════════════════════════════════════════════════');
  
  try {
    // 1. Seed Products
    await seedCollection('products', products);
    
    // 2. Seed Stores
    await seedCollection('stores', stores);
    
    // 3. Seed Inventory
    const inventory = generateInventory();
    await seedCollection('inventory', inventory);
    
    // 4. Seed Stock Movements
    const movements = generateStockMovements();
    await seedCollection('stockMovements', movements);
    
    console.log('\n═══════════════════════════════════════════════════════════════');
    console.log('\n✅ SEEDING COMPLETE!\n');
    console.log('Summary:');
    console.log(`  • ${products.length} products`);
    console.log(`  • ${stores.length} stores`);
    console.log(`  • ${inventory.length} inventory records`);
    console.log(`  • ${movements.length} stock movements`);
    console.log('\n📊 Stock Status:');
    
    const totalItems = inventory.length;
    const outOfStock = inventory.filter(i => i.data.currentStock === 0).length;
    const lowStock = inventory.filter(i => i.data.currentStock > 0 && i.data.currentStock <= i.data.minimumStockLevel).length;
    const normalStock = totalItems - outOfStock - lowStock;
    
    console.log(`  • Normal Stock: ${normalStock} items (${Math.round(normalStock/totalItems*100)}%)`);
    console.log(`  • Low Stock: ${lowStock} items (${Math.round(lowStock/totalItems*100)}%)`);
    console.log(`  • Out of Stock: ${outOfStock} items (${Math.round(outOfStock/totalItems*100)}%)`);
    
    console.log('\n🚀 You can now test the inventory features in your app!');
    console.log('\n');
    
  } catch (error) {
    console.error('\n❌ ERROR during seeding:', error);
    process.exit(1);
  }
  
  process.exit(0);
}

main();
