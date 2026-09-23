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

function fromFirestoreDoc(doc) {
  if (!doc || !doc.fields) return {};
  const res = {};
  for (const [k, v] of Object.entries(doc.fields)) {
    if (v.stringValue !== undefined) res[k] = v.stringValue;
    else if (v.integerValue !== undefined) res[k] = parseInt(v.integerValue, 10);
    else if (v.doubleValue !== undefined) res[k] = v.doubleValue;
    else if (v.booleanValue !== undefined) res[k] = v.booleanValue;
    else if (v.timestampValue !== undefined) res[k] = v.timestampValue;
    else if (v.nullValue !== undefined) res[k] = null;
    else res[k] = v;
  }
  return res;
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

async function listDocuments(token, collection) {
  let docs = [];
  let pageToken = '';
  do {
    const query = pageToken ? `?pageSize=100&pageToken=${pageToken}` : '?pageSize=100';
    const res = await firestoreRequest(token, 'GET', `/${collection}${query}`);
    if (res.documents) {
      docs.push(...res.documents);
    }
    pageToken = res.nextPageToken;
  } while (pageToken);
  return docs;
}

async function upsertDoc(token, collection, docId, data) {
  const doc = toFirestoreDoc(data);
  const fieldPaths = Object.keys(data).map(k => `updateMask.fieldPaths=${encodeURIComponent(k)}`).join('&');
  return firestoreRequest(token, 'PATCH', `/${collection}/${docId}?${fieldPaths}`, doc);
}

async function main() {
  console.log('Authenticating with Google OAuth2 REST...');
  const token = await getAccessToken();
  console.log('✓ Token acquired.');

  // Fetch stores
  console.log('Fetching stores...');
  const rawStores = await listDocuments(token, 'stores');
  const stores = rawStores.map(d => ({
    id: d.name.split('/').pop(),
    ...fromFirestoreDoc(d),
  }));
  console.log(`Found ${stores.length} stores: ${stores.map(s => s.name || s.id).join(', ')}`);

  // Fetch products
  console.log('Fetching products...');
  const rawProducts = await listDocuments(token, 'products');
  const products = rawProducts.map(d => ({
    id: d.name.split('/').pop(),
    ...fromFirestoreDoc(d),
  }));
  console.log(`Found ${products.length} products.`);

  // Fetch inventory
  console.log('Fetching inventory...');
  const rawInventory = await listDocuments(token, 'inventory');
  console.log(`Found ${rawInventory.length} existing inventory records.`);
  
  const existingInventory = {};
  for (const doc of rawInventory) {
    const id = doc.name.split('/').pop();
    const data = fromFirestoreDoc(doc);
    existingInventory[id] = { id, data };
  }

  // Stock quantities per category
  const CATEGORY_STOCK = {
    'Grocery':             { min: 15, stock: 85 },
    'Beverages':           { min: 12, stock: 70 },
    'Dairy':               { min: 10, stock: 50 },
    'Bakery':              { min: 8,  stock: 40 },
    'Snacks':              { min: 12, stock: 65 },
    'Personal Care':       { min: 10, stock: 45 },
    'Household':           { min: 8,  stock: 40 },
    'Stationery':          { min: 10, stock: 50 },
    'Electronics':         { min: 5,  stock: 25 },
    'Clothing':            { min: 8,  stock: 35 },
    'Fruits & Vegetables': { min: 15, stock: 60 },
    'Frozen Foods':        { min: 10, stock: 35 },
    'Health & Medicine':   { min: 10, stock: 40 },
  };

  let updatedCount = 0;
  let createdCount = 0;
  let skippedCount = 0;

  for (const store of stores) {
    console.log(`\nProcessing Store: ${store.name || store.id} (${store.id})`);
    for (const prod of products) {
      const docId = `${store.id}_${prod.id}`;
      const catConfig = CATEGORY_STOCK[prod.category] || { min: 10, stock: 50 };
      const existing = existingInventory[docId];

      if (existing) {
        const curStock = existing.data.currentStock ?? 0;
        if (curStock > 0) {
          // Has stock already
          skippedCount++;
        } else {
          // Out of stock -> restock it!
          console.log(` Restocking (0 -> ${catConfig.stock}): ${prod.name || prod.id}`);
          await upsertDoc(token, 'inventory', docId, {
            currentStock: catConfig.stock,
            minimumStockLevel: catConfig.min,
            maximumStockLevel: catConfig.stock * 2,
            lastUpdated: new Date(),
          });
          updatedCount++;
        }
      } else {
        // Create new inventory doc
        console.log(` Creating record with ${catConfig.stock} stock: ${prod.name || prod.id}`);
        await upsertDoc(token, 'inventory', docId, {
          storeId: store.id,
          productId: prod.id,
          productName: prod.name || 'Unknown Product',
          category: prod.category || 'General',
          currentStock: catConfig.stock,
          minimumStockLevel: catConfig.min,
          maximumStockLevel: catConfig.stock * 2,
          imageUrl: prod.imageUrl || null,
          lastUpdated: new Date(),
        });
        createdCount++;
      }
    }
  }

  console.log('\n=== Restock Summary ===');
  console.log(`Restocked (was 0): ${updatedCount}`);
  console.log(`Created new:       ${createdCount}`);
  console.log(`Already stocked:   ${skippedCount}`);
  console.log('Inventory restock complete!');
}

main().catch(err => {
  console.error('Error running restock:', err);
  process.exit(1);
});
