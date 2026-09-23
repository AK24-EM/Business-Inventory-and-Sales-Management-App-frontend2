'use strict';

const https = require('https');
const crypto = require('crypto');
const fs = require('fs');

const SA = JSON.parse(
  fs.readFileSync('./store-inventory-sale-manage-firebase-adminsdk-fbsvc-2d3176b5ac.json', 'utf8')
);
const PROJECT_ID = SA.project_id;
const BASE = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

function b64url(str) {
  return Buffer.from(str).toString('base64url');
}

function makeJwt() {
  const now = Math.floor(Date.now() / 1000);
  const header = b64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const claim = b64url(JSON.stringify({
    iss: SA.client_email,
    scope: 'https://www.googleapis.com/auth/cloud-platform https://www.googleapis.com/auth/datastore',
    aud: 'https://oauth2.googleapis.com/token',
    exp: now + 3600,
    iat: now,
  }));
  const sign = crypto.createSign('RSA-SHA256');
  sign.update(`${header}.${claim}`);
  const sig = sign.sign(SA.private_key, 'base64url');
  return `${header}.${claim}.${sig}`;
}

function getAccessToken() {
  return new Promise((resolve, reject) => {
    const jwt = makeJwt();
    const body = `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`;
    const req = https.request({
      hostname: 'oauth2.googleapis.com',
      path: '/token',
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Content-Length': Buffer.byteLength(body),
      },
    }, (res) => {
      let data = '';
      res.on('data', c => data += c);
      res.on('end', () => {
        const parsed = JSON.parse(data);
        if (parsed.access_token) resolve(parsed.access_token);
        else reject(new Error(`Token error: ${JSON.stringify(parsed)}`));
      });
    });
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

function toFirestoreValue(val) {
  if (val === null || val === undefined) return { nullValue: null };
  if (typeof val === 'boolean') return { booleanValue: val };
  if (typeof val === 'number') return Number.isInteger(val) ? { integerValue: val.toString() } : { doubleValue: val };
  if (typeof val === 'string') return { stringValue: val };
  if (val instanceof Date) return { timestampValue: val.toISOString() };
  if (Array.isArray(val)) return { arrayValue: { values: val.map(toFirestoreValue) } };
  if (typeof val === 'object') {
    const fields = {};
    for (const k of Object.keys(val)) fields[k] = toFirestoreValue(val[k]);
    return { mapValue: { fields } };
  }
  return { stringValue: String(val) };
}

function toFirestoreDoc(obj) {
  const fields = {};
  for (const k of Object.keys(obj)) fields[k] = toFirestoreValue(obj[k]);
  return { fields };
}

function firestoreRequest(token, method, path, body) {
  return new Promise((resolve, reject) => {
    const bodyStr = body ? JSON.stringify(body) : undefined;
    const url = new URL(BASE + path);
    const opts = {
      hostname: url.hostname,
      path: url.pathname + (url.search || ''),
      method,
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
        ...(bodyStr ? { 'Content-Length': Buffer.byteLength(bodyStr) } : {}),
      },
    };
    const req = https.request(opts, (res) => {
      let data = '';
      res.on('data', c => data += c);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(data ? JSON.parse(data) : {});
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${data}`));
        }
      });
    });
    req.on('error', reject);
    if (bodyStr) req.write(bodyStr);
    req.end();
  });
}

async function listAllDocuments(token, collection) {
  let docs = [];
  let pageToken = '';
  do {
    const query = pageToken ? `?pageSize=100&pageToken=${pageToken}` : '?pageSize=100';
    const res = await firestoreRequest(token, 'GET', `/${collection}${query}`);
    if (res.documents) docs.push(...res.documents);
    pageToken = res.nextPageToken;
  } while (pageToken);
  return docs;
}

async function deleteDoc(token, collection, docId) {
  return firestoreRequest(token, 'DELETE', `/${collection}/${docId}`);
}

async function upsertDoc(token, collection, docId, data) {
  const doc = toFirestoreDoc(data);
  const fieldPaths = Object.keys(data).map(k => `updateMask.fieldPaths=${encodeURIComponent(k)}`).join('&');
  return firestoreRequest(token, 'PATCH', `/${collection}/${docId}?${fieldPaths}`, doc);
}

// ── Category to Supplier Mapping ─────────────────────────────────────────────
const SUPPLIERS = {
  'sup_001': { id: 'sup_001', name: 'Maharashtra FMCG Distributors' },
  'sup_002': { id: 'sup_002', name: 'Amul Dairy Distributors' },
  'sup_003': { id: 'sup_003', name: 'Fresh Produce Hub' },
  'sup_004': { id: 'sup_004', name: 'HUL Direct Distributor' },
  'sup_005': { id: 'sup_005', name: 'Nestle Premium Foods' },
};

function getSupplierForCategory(category) {
  switch (category) {
    case 'Dairy':
      return SUPPLIERS['sup_002'];
    case 'Fruits & Vegetables':
      return SUPPLIERS['sup_003'];
    case 'Personal Care':
    case 'Household':
      return SUPPLIERS['sup_004'];
    case 'Bakery':
    case 'Frozen Foods':
    case 'Health & Medicine':
    case 'Stationery':
    case 'Electronics':
      return SUPPLIERS['sup_005'];
    case 'Grocery':
    case 'Beverages':
    case 'Snacks':
    default:
      return SUPPLIERS['sup_001'];
  }
}

// Realistic stock configurations per product for Store 01
// Some OUT OF STOCK (0), some LOW STOCK (danger zone), some HEALTHY
const REALISTIC_STOCK_STORE_01 = {
  // ── OUT OF STOCK (Critical urgency - Red) ───────────────────────────────────
  'prod_009': { currentStock: 0, minStock: 50 },  // Amul Full Cream Milk
  'prod_015': { currentStock: 0, minStock: 25 },  // Britannia Whole Wheat Bread
  'prod_023': { currentStock: 0, minStock: 25 },  // Fresh Tomatoes
  'prod_025': { currentStock: 0, minStock: 20 },  // Bananas
  'prod_018': { currentStock: 0, minStock: 20 },  // Colgate MaxFresh
  'prod_006': { currentStock: 0, minStock: 15 },  // Nescafe Classic

  // ── LOW STOCK (Urgent Reorder - Amber) ──────────────────────────────────────
  'prod_002': { currentStock: 4, minStock: 30 },  // Aashirvaad Atta (deficit 26)
  'prod_003': { currentStock: 5, minStock: 25 },  // Fortune Soyabean Oil (deficit 20)
  'prod_004': { currentStock: 6, minStock: 20 },  // Tata Sampann Chana Dal (deficit 14)
  'prod_005': { currentStock: 8, minStock: 25 },  // India Gate Basmati Rice
  'prod_007': { currentStock: 6, minStock: 20 },  // Tata Tea Gold
  'prod_011': { currentStock: 10, minStock: 40 }, // Lay's Classic Salted
  'prod_024': { currentStock: 7, minStock: 30 },  // Fresh Onions
  'prod_017': { currentStock: 6, minStock: 25 },  // Dove Moisturising Bar
  'prod_010': { currentStock: 8, minStock: 25 },  // Amul Butter

  // ── HEALTHY STOCK (Normal operations - Green) ──────────────────────────────
  'prod_001': { currentStock: 65, minStock: 20 }, // Tata Salt
  'prod_008': { currentStock: 45, minStock: 20 }, // Tropicana Orange Juice
  'prod_012': { currentStock: 55, minStock: 25 }, // Haldiram's Bhujia
  'prod_013': { currentStock: 80, minStock: 35 }, // Parle-G Biscuits
  'prod_014': { currentStock: 90, minStock: 30 }, // Maggi Masala Noodles
  'prod_016': { currentStock: 35, minStock: 15 }, // English Oven Croissant
  'prod_019': { currentStock: 40, minStock: 15 }, // Head & Shoulders
  'prod_020': { currentStock: 50, minStock: 20 }, // Surf Excel Easy Wash
  'prod_021': { currentStock: 45, minStock: 15 }, // Vim Dishwash Gel
  'prod_022': { currentStock: 40, minStock: 15 }, // Colin Glass Cleaner
  'prod_026': { currentStock: 30, minStock: 10 }, // Dabur Honey
  'prod_027': { currentStock: 28, minStock: 10 }, // Dabur Chyawanprash
  'prod_028': { currentStock: 35, minStock: 15 }, // Electral ORS Powder
  'prod_029': { currentStock: 42, minStock: 15 }, // Nestle Yogurt
  'prod_030': { currentStock: 38, minStock: 15 }, // Britannia Cheese Slices
};

async function main() {
  console.log('1. Authenticating...');
  const token = await getAccessToken();
  console.log('✓ Token acquired.');

  // 1. Fetch all products and assign suppliers to products if missing
  console.log('\n2. Updating products with supplier links...');
  const rawProducts = await listAllDocuments(token, 'products');
  const products = rawProducts.map(d => {
    const id = d.name.split('/').pop();
    const fields = d.fields || {};
    return {
      id,
      name: fields.name?.stringValue || id,
      category: fields.category?.stringValue || 'Grocery',
      purchasePrice: fields.costPrice?.integerValue ? parseInt(fields.costPrice.integerValue, 10) : 50,
      supplierId: fields.supplierId?.stringValue || null,
    };
  });
  console.log(`Found ${products.length} products.`);

  for (const prod of products) {
    const sup = getSupplierForCategory(prod.category);
    await upsertDoc(token, 'products', prod.id, {
      supplierId: sup.id,
      supplierName: sup.name,
    });
  }
  console.log('✓ All products updated with valid supplierId & supplierName.');

  // 2. Fetch all inventory docs and remove duplicates (docs without 'inv_' prefix)
  console.log('\n3. Cleaning up duplicate inventory records...');
  const rawInventory = await listAllDocuments(token, 'inventory');
  console.log(`Total inventory records: ${rawInventory.length}`);

  let deletedDups = 0;
  for (const doc of rawInventory) {
    const id = doc.name.split('/').pop();
    if (!id.startsWith('inv_')) {
      await deleteDoc(token, 'inventory', id);
      deletedDups++;
    }
  }
  console.log(`✓ Deleted ${deletedDups} non-canonical duplicate documents.`);

  // 3. Set realistic stock on canonical 'inv_store_01_prod_...' docs
  console.log('\n4. Applying realistic, logically structured stock levels for Store 01...');
  const stores = ['store_01', 'store_02', 'store_03'];

  for (const storeId of stores) {
    console.log(`\nSetting stock for ${storeId}:`);
    for (const prod of products) {
      const docId = `inv_${storeId}_${prod.id}`;
      const sup = getSupplierForCategory(prod.category);
      const conf = REALISTIC_STOCK_STORE_01[prod.id] || { currentStock: 45, minStock: 20 };

      // Vary slightly for store_02 and store_03 so each branch feels authentic
      let currentStock = conf.currentStock;
      if (storeId === 'store_02' && currentStock > 0) {
        currentStock = Math.max(2, currentStock - 3);
      } else if (storeId === 'store_03' && currentStock > 0) {
        currentStock = currentStock + 5;
      }

      await upsertDoc(token, 'inventory', docId, {
        storeId,
        productId: prod.id,
        productName: prod.name,
        category: prod.category,
        currentStock,
        minimumStockLevel: conf.minStock,
        minStockLevel: conf.minStock,
        maximumStockLevel: conf.minStock * 4,
        supplierId: sup.id,
        supplierName: sup.name,
        lastUpdated: new Date(),
      });

      const statusTag = currentStock === 0 ? '🔴 OUT OF STOCK' : currentStock <= conf.minStock ? '🟠 LOW STOCK' : '🟢 HEALTHY';
      if (storeId === 'store_01') {
        console.log(`  ${prod.name.padEnd(28)} | Stock: ${String(currentStock).padStart(3)} / Min: ${String(conf.minStock).padStart(2)} | ${statusTag}`);
      }
    }
  }

  console.log('\n✓ Realistic inventory and supplier structure successfully applied!');
  console.log('Now refresh the app to see logically ordered Out of Stock and Low Stock products!');
}

main().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
