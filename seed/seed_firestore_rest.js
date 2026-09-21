/**
 * seed_firestore_rest.js
 *
 * Seeds Firestore using the REST API + a manually signed JWT from the
 * service account key. Does NOT use firebase-admin SDK — works on any
 * machine without special network access to GCP metadata endpoints.
 *
 * Run:  node seed_firestore_rest.js
 */

'use strict';

const https = require('https');
const crypto = require('crypto');
const fs = require('fs');

const SA = JSON.parse(
  fs.readFileSync('./store-inventory-sale-manage-firebase-adminsdk-fbsvc-2d3176b5ac.json', 'utf8')
);
const PROJECT_ID = SA.project_id;
const BASE = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

// ─────────────────────────────────────────────────────────────────────────────
// Sign a JWT for the service account and exchange for an access token
// ─────────────────────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
// Firestore REST helpers
// ─────────────────────────────────────────────────────────────────────────────
function toFirestoreValue(val) {
  if (val === null || val === undefined) return { nullValue: null };
  if (typeof val === 'boolean') return { booleanValue: val };
  if (typeof val === 'number') return Number.isInteger(val) ? { integerValue: val } : { doubleValue: val };
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
        if (res.statusCode >= 200 && res.statusCode < 300) resolve(data ? JSON.parse(data) : {});
        else reject(new Error(`HTTP ${res.statusCode}: ${data.slice(0, 200)}`));
      });
    });
    req.on('error', reject);
    if (bodyStr) req.write(bodyStr);
    req.end();
  });
}

async function upsertDoc(token, collection, docId, data) {
  // PATCH with updateMask creates-or-replaces
  const doc = toFirestoreDoc(data);
  const fieldPaths = Object.keys(data).map(k => `updateMask.fieldPaths=${encodeURIComponent(k)}`).join('&');
  await firestoreRequest(token, 'PATCH', `/${collection}/${docId}?${fieldPaths}`, doc);
}

// ─────────────────────────────────────────────────────────────────────────────
// Data
// ─────────────────────────────────────────────────────────────────────────────
const daysAgo  = (n) => new Date(Date.now() - n * 86400000);
const daysLater = (n) => new Date(Date.now() + n * 86400000);

const notifications = [
  ['notif_001', {
    title: 'Low Stock Alert — Aashirvaad Atta 5kg',
    body: 'Only 8 units remaining at Andheri Branch. Minimum stock level is 20.',
    type: 'lowStock', isRead: false,
    targetStoreId: 'store_01', targetUserId: null,
    createdAt: daysAgo(0), productId: 'p03', productName: 'Aashirvaad Atta 5kg',
  }],
  ['notif_002', {
    title: 'Low Stock Alert — Lays Classic 75g',
    body: 'Only 5 units remaining at Andheri Branch. Minimum stock level is 25.',
    type: 'lowStock', isRead: false,
    targetStoreId: 'store_01', targetUserId: null,
    createdAt: daysAgo(0), productId: 'p05', productName: 'Lays Classic 75g',
  }],
  ['notif_003', {
    title: 'Critical: Mother Dairy Milk 1L — 3 units left',
    body: 'Stock critically low at Andheri Branch. Restock urgently to avoid stockout.',
    type: 'lowStock', isRead: false,
    targetStoreId: 'store_01', targetUserId: 'uid_manager',
    createdAt: daysAgo(1), productId: 'p08', productName: 'Mother Dairy Milk 1L',
  }],
  ['notif_004', {
    title: 'Stock Transfer Pending',
    body: 'Incoming transfer of 20 units Coca-Cola 2L from Bandra Branch awaiting confirmation.',
    type: 'transferPending', isRead: false,
    targetStoreId: 'store_01', targetUserId: 'uid_manager',
    createdAt: daysAgo(1),
  }],
  ['notif_005', {
    title: 'Restocking Recommendation',
    body: 'Based on 30-day velocity: order 60 units Aashirvaad Atta 5kg and 80 units Lays Classic.',
    type: 'restockingRequired', isRead: true,
    targetStoreId: 'store_01', targetUserId: null,
    createdAt: daysAgo(2),
  }],
  ['notif_006', {
    title: 'Diwali Demand Alert — Act Now',
    body: 'Diwali is in 18 days. Historical data shows 3× surge in Dairy and Snacks.',
    type: 'festivalAlert', isRead: false,
    targetStoreId: null, targetUserId: null,
    createdAt: daysAgo(0),
  }],
  ['notif_007', {
    title: 'Transfer Confirmed — Dove Soap 100g',
    body: '15 units Dove Soap 100g transferred to Bandra Branch successfully.',
    type: 'transferConfirmed', isRead: true,
    targetStoreId: 'store_01', targetUserId: 'uid_manager',
    createdAt: daysAgo(3),
  }],
];

const festivals = [
  ['festival_001', {
    name: 'Diwali',
    startDate: daysLater(18), endDate: daysLater(23),
    isActive: true, advanceOrderDays: 14, expectedDemandMultiplier: 3.0,
    relevantCategories: ['Dairy', 'Snacks', 'Beverages', 'Personal Care'],
    notes: 'Highest sales period of the year. Stock gifting items and mithai ingredients.',
    createdAt: daysAgo(10), createdByUserId: 'uid_owner',
  }],
  ['festival_002', {
    name: 'Navratri',
    startDate: daysLater(5), endDate: daysLater(14),
    isActive: true, advanceOrderDays: 7, expectedDemandMultiplier: 2.0,
    relevantCategories: ['Grocery', 'Dairy', 'Fruits & Vegetables'],
    notes: 'High demand for fasting foods — sabudana, rock salt, fruits, dairy.',
    createdAt: daysAgo(15), createdByUserId: 'uid_owner',
  }],
  ['festival_003', {
    name: 'Ganesh Chaturthi',
    startDate: daysAgo(5), endDate: daysLater(2),
    isActive: true, advanceOrderDays: 10, expectedDemandMultiplier: 2.5,
    relevantCategories: ['Grocery', 'Dairy', 'Snacks'],
    notes: 'Ongoing. Elevated demand for modak ingredients and dairy products.',
    createdAt: daysAgo(20), createdByUserId: 'uid_owner',
  }],
  ['festival_004', {
    name: 'Holi',
    startDate: daysLater(150), endDate: daysLater(151),
    isActive: true, advanceOrderDays: 14, expectedDemandMultiplier: 1.8,
    relevantCategories: ['Beverages', 'Snacks', 'Personal Care'],
    notes: 'Plan ahead for beverage and personal care surge.',
    createdAt: daysAgo(5), createdByUserId: 'uid_owner',
  }],
];

const festivalAlerts = [
  ['alert_001', {
    festivalId: 'festival_001', festivalName: 'Diwali',
    storeId: 'store_01', storeName: 'StoreIQ - Andheri Branch',
    productId: 'p01', productName: 'Amul Butter 500g',
    currentStock: 45, recommendedStock: 150, shortfallQuantity: 105,
    estimatedCost: 23625.0, isAcknowledged: false, createdAt: daysAgo(0),
  }],
  ['alert_002', {
    festivalId: 'festival_001', festivalName: 'Diwali',
    storeId: 'store_01', storeName: 'StoreIQ - Andheri Branch',
    productId: 'p05', productName: 'Lays Classic 75g',
    currentStock: 5, recommendedStock: 200, shortfallQuantity: 195,
    estimatedCost: 3510.0, isAcknowledged: false, createdAt: daysAgo(0),
  }],
  ['alert_003', {
    festivalId: 'festival_002', festivalName: 'Navratri',
    storeId: 'store_01', storeName: 'StoreIQ - Andheri Branch',
    productId: 'p08', productName: 'Mother Dairy Milk 1L',
    currentStock: 3, recommendedStock: 80, shortfallQuantity: 77,
    estimatedCost: 4466.0, isAcknowledged: false, createdAt: daysAgo(1),
  }],
];

// ─────────────────────────────────────────────────────────────────────────────
// Main
// ─────────────────────────────────────────────────────────────────────────────
async function main() {
  console.log('🔑  Getting access token...');
  const token = await getAccessToken();
  console.log('✓  Token obtained\n');

  console.log('📄  Seeding notifications...');
  for (const [id, data] of notifications) {
    await upsertDoc(token, 'notifications', id, data);
    process.stdout.write('  .');
  }
  console.log(`\n  ✓ ${notifications.length} notifications written`);

  console.log('\n🎉  Seeding festivals...');
  for (const [id, data] of festivals) {
    await upsertDoc(token, 'festivals', id, data);
    process.stdout.write('  .');
  }
  console.log(`\n  ✓ ${festivals.length} festivals written`);

  console.log('\n⚠️   Seeding festival alerts...');
  for (const [id, data] of festivalAlerts) {
    await upsertDoc(token, 'festivalAlerts', id, data);
    process.stdout.write('  .');
  }
  console.log(`\n  ✓ ${festivalAlerts.length} festival alerts written`);

  console.log('\n✅  Firestore seeded successfully!');
  console.log('\n  Collections created:');
  console.log('    notifications  — 7 docs (low stock, transfer, festival alerts, recommendations)');
  console.log('    festivals      — 4 docs (Diwali, Navratri, Ganesh Chaturthi, Holi)');
  console.log('    festivalAlerts — 3 docs (demand shortfalls for Diwali & Navratri)');
}

main().catch(err => {
  console.error('\n❌  Failed:', err.message);
  process.exit(1);
});
