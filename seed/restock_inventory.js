/**
 * restock_inventory.js
 * ─────────────────────────────────────────────────────────────────────────────
 * Reads all stores + products from Firestore.
 * For every (store × product) pair:
 *   - If an inventory doc already exists and currentStock > 0  → skip (already has stock)
 *   - If an inventory doc exists but currentStock == 0          → restock to a healthy qty
 *   - If no inventory doc exists                               → create one with full stock
 *
 * Stock quantities are based on product category so they look realistic.
 * ─────────────────────────────────────────────────────────────────────────────
 */

const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const serviceAccount = require('./store-inventory-sale-manage-firebase-adminsdk-fbsvc-2d3176b5ac.json');

initializeApp({
  credential: cert(serviceAccount),
  projectId: 'store-inventory-sale-manage',
});

const db = getFirestore();

// ── Stock quantities per category ──────────────────────────────────────────
const CATEGORY_STOCK = {
  'Grocery':            { min: 15, stock: 120 },
  'Beverages':          { min: 12, stock: 96  },
  'Dairy':              { min: 10, stock: 60  },
  'Bakery':             { min: 8,  stock: 40  },
  'Snacks':             { min: 12, stock: 80  },
  'Personal Care':      { min: 10, stock: 50  },
  'Household':          { min: 8,  stock: 45  },
  'Stationery':         { min: 10, stock: 55  },
  'Electronics':        { min: 5,  stock: 25  },
  'Clothing':           { min: 8,  stock: 35  },
  'Fruits & Vegetables':{ min: 15, stock: 70  },
  'Frozen Foods':       { min: 10, stock: 40  },
  'Health & Medicine':  { min: 10, stock: 45  },
  'Other':              { min: 10, stock: 50  },
};

function getStockParams(category) {
  return CATEGORY_STOCK[category] || { min: 10, stock: 50 };
}

// ── Friendly log helper ────────────────────────────────────────────────────
const C = { green: '\x1b[32m', yellow: '\x1b[33m', blue: '\x1b[36m', reset: '\x1b[0m', bold: '\x1b[1m' };
const log = {
  ok:   (msg) => console.log(`${C.green}✓${C.reset} ${msg}`),
  skip: (msg) => console.log(`${C.yellow}→${C.reset} ${msg}`),
  new:  (msg) => console.log(`${C.blue}+${C.reset} ${msg}`),
  info: (msg) => console.log(`  ${msg}`),
  head: (msg) => console.log(`\n${C.bold}${msg}${C.reset}`),
};

async function run() {
  log.head('═══ StoreIQ Inventory Restock Script ═══');

  // 1. Fetch all active stores
  const storesSnap = await db.collection('stores').where('isActive', '==', true).get();
  if (storesSnap.empty) {
    console.error('No active stores found. Exiting.');
    process.exit(1);
  }
  const stores = storesSnap.docs.map(d => ({ id: d.id, ...d.data() }));
  log.info(`Found ${stores.length} active store(s): ${stores.map(s => s.name).join(', ')}`);

  // 2. Fetch all products
  const productsSnap = await db.collection('products').get();
  if (productsSnap.empty) {
    console.error('No products found. Add products first, then rerun this script.');
    process.exit(1);
  }
  const products = productsSnap.docs.map(d => ({ id: d.id, ...d.data() }));
  log.info(`Found ${products.length} product(s)`);

  // 3. Process every store × product combination in batches of 400
  let created = 0, restocked = 0, skipped = 0;

  for (const store of stores) {
    log.head(`Store: ${store.name} (${store.id})`);

    // Load existing inventory for this store to avoid an extra write per doc
    const invSnap = await db.collection('inventory')
      .where('storeId', '==', store.id)
      .get();

    const existingByProductId = {};
    invSnap.docs.forEach(d => {
      existingByProductId[d.data().productId] = { docId: d.id, data: d.data() };
    });

    // Split products into chunks of 400 for Firestore batch limit (500 ops/batch)
    const CHUNK = 400;
    for (let i = 0; i < products.length; i += CHUNK) {
      const chunk = products.slice(i, i + CHUNK);
      const batch = db.batch();

      for (const product of chunk) {
        const params = getStockParams(product.category || 'Other');
        const docId = `${store.id}_${product.id}`;
        const existing = existingByProductId[product.id];

        if (existing) {
          const currentStock = existing.data.currentStock ?? 0;
          if (currentStock > 0) {
            log.skip(`  [SKIP]  ${product.name} — already has ${currentStock} units`);
            skipped++;
            continue;
          }
          // Restock existing out-of-stock doc
          const ref = db.collection('inventory').doc(existing.docId);
          batch.update(ref, {
            currentStock: params.stock,
            minimumStockLevel: params.min,
            lastUpdated: FieldValue.serverTimestamp(),
          });
          log.ok(`  [RESTOCKED] ${product.name} → ${params.stock} units (was 0)`);
          restocked++;
        } else {
          // Create fresh inventory doc
          const ref = db.collection('inventory').doc(docId);
          batch.set(ref, {
            storeId: store.id,
            productId: product.id,
            productName: product.name,
            category: product.category || 'Other',
            currentStock: params.stock,
            minimumStockLevel: params.min,
            maximumStockLevel: params.stock * 2,
            imageUrl: product.imageUrl || null,
            lastUpdated: FieldValue.serverTimestamp(),
          });
          log.new(`  [CREATED]   ${product.name} → ${params.stock} units`);
          created++;
        }
      }

      await batch.commit();
    }
  }

  log.head('═══ Summary ═══');
  log.info(`✓ Created:   ${created} new inventory records`);
  log.info(`✓ Restocked: ${restocked} out-of-stock records`);
  log.info(`→ Skipped:   ${skipped} already-stocked records`);
  log.info('All done! Refresh the app to see updated stock levels.');
  process.exit(0);
}

run().catch(err => {
  console.error('\x1b[31mFatal error:\x1b[0m', err);
  process.exit(1);
});
