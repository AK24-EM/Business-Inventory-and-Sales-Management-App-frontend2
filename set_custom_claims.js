#!/usr/bin/env node

/**
 * Set Firebase Auth Custom Claims for All Users
 * 
 * This script reads user data from Firestore and sets custom claims
 * (role, storeId) on their Firebase Auth tokens so that Firestore
 * security rules can properly authorize their requests.
 * 
 * Usage:
 *   npm install firebase-admin
 *   node set_custom_claims.js
 */

const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin SDK
const serviceAccountPath = path.join(__dirname, 'seed', 'store-inventory-sale-manage-firebase-adminsdk-fbsvc-2d3176b5ac.json');

try {
  // Check if file exists
  if (!fs.existsSync(serviceAccountPath)) {
    throw new Error(`Service account file not found at: ${serviceAccountPath}`);
  }
  
  // Read and parse JSON manually to get better error messages
  const serviceAccountContent = fs.readFileSync(serviceAccountPath, 'utf8');
  const serviceAccount = JSON.parse(serviceAccountContent);
  
  initializeApp({
    credential: cert(serviceAccount)
  });
  
  console.log('✅ Firebase Admin SDK initialized\n');
} catch (error) {
  console.error('❌ Error loading service account:', error.message);
  if (error.stack) {
    console.error('\nStack trace:');
    console.error(error.stack);
  }
  console.error('\nService account file path:');
  console.error(serviceAccountPath);
  console.error('\nPlease verify:');
  console.error('1. The file exists');
  console.error('2. The JSON is valid');
  console.error('3. You have read permissions');
  console.error('4. firebase-admin is properly installed\n');
  process.exit(1);
}

const db = getFirestore();
const auth = getAuth();

async function setCustomClaims() {
  try {
    console.log('📋 Fetching users from Firestore...\n');
    
    // Get all users from Firestore
    const usersSnapshot = await db.collection('users').get();
    
    if (usersSnapshot.empty) {
      console.log('⚠️  No users found in Firestore users collection.');
      console.log('Run the seed script first: node create_demo_firebase_users.js');
      return;
    }
    
    console.log(`Found ${usersSnapshot.size} users\n`);
    console.log('─'.repeat(80));
    
    let successCount = 0;
    let errorCount = 0;
    
    for (const doc of usersSnapshot.docs) {
      const userData = doc.data();
      const uid = doc.id;
      
      try {
        // Verify user exists in Firebase Auth
        const userRecord = await auth.getUser(uid);
        
        const storeId = userData.assignedStoreId || userData.storeId || null;
        const customClaims = {
          role: userData.role || 'employee',
          assignedStoreId: storeId,
          storeId: storeId,
          storeAccess: (userData.role === 'owner' || userData.role === 'admin') ? 'all' : (storeId || ''),
        };
        
        // Set custom claims
        await auth.setCustomUserClaims(uid, customClaims);
        
        console.log(`✅ ${userData.name} (${userData.email})`);
        console.log(`   Role: ${customClaims.role}`);
        console.log(`   Store: ${customClaims.storeId || 'None (owner/admin)'}`);
        console.log();
        
        successCount++;
      } catch (userError) {
        console.error(`❌ ${userData.email}: ${userError.message}`);
        console.log();
        errorCount++;
      }
    }
    
    console.log('─'.repeat(80));
    console.log(`\n✅ Successfully updated: ${successCount} users`);
    if (errorCount > 0) {
      console.log(`❌ Failed: ${errorCount} users`);
    }
    
    console.log('\n⚠️  IMPORTANT: Users must sign out and sign in again for claims to take effect!\n');
    console.log('Next steps:');
    console.log('1. In your app, sign out all users');
    console.log('2. Sign in again with any role');
    console.log('3. Check browser console: firebase.auth().currentUser.getIdTokenResult().then(t => console.log(t.claims))');
    console.log('4. Verify "role" and "storeId" are present in the claims');
    console.log('5. Try creating a sale - it should now save to Firestore\n');
    
  } catch (error) {
    console.error('\n❌ Fatal error:', error);
    process.exit(1);
  }
}

// Run the script
console.log('🔧 Firebase Auth Custom Claims Updater');
console.log('─'.repeat(80));
console.log();

setCustomClaims()
  .then(() => {
    console.log('Done!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Script failed:', error);
    process.exit(1);
  });
