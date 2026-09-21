/**
 * check_products.js
 *
 * Checks what products exist in Firestore and their imageUrl status
 *
 * Run: node check_products.js
 */

const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('./store-inventory-sale-manage-firebase-adminsdk-fbsvc-2d3176b5ac.json');

initializeApp({
  credential: cert(serviceAccount),
  projectId: 'store-inventory-sale-manage',
});

const db = getFirestore();

async function checkProducts() {
  console.log('\n📦 Checking products in Firestore...\n');

  try {
    const productsSnapshot = await db.collection('products').get();
    
    if (productsSnapshot.empty) {
      console.log('❌ No products found in Firestore!');
      console.log('\n💡 You need to create products first.');
      console.log('   Options:');
      console.log('   1. Use the Product Management screen in your app');
      console.log('   2. Manually add via Firebase Console');
      console.log('   3. Create a seed script for products\n');
      return;
    }

    console.log(`✅ Found ${productsSnapshot.size} products:\n`);
    console.log('─'.repeat(80));

    let withImages = 0;
    let withoutImages = 0;

    productsSnapshot.forEach((doc, index) => {
      const product = doc.data();
      const hasImage = product.imageUrl && product.imageUrl.trim() !== '';
      
      if (hasImage) withImages++;
      else withoutImages++;

      console.log(`${index + 1}. ${product.name}`);
      console.log(`   Category: ${product.category || 'N/A'}`);
      console.log(`   Price: ₹${product.sellingPrice || 0}`);
      console.log(`   Image: ${hasImage ? '✅ ' + product.imageUrl.substring(0, 50) + '...' : '❌ No image'}`);
      console.log('─'.repeat(80));
    });

    console.log(`\n📊 Summary:`);
    console.log(`   ✅ With images: ${withImages}`);
    console.log(`   ❌ Without images: ${withoutImages}`);
    console.log(`   📦 Total: ${productsSnapshot.size}\n`);

    if (withoutImages > 0) {
      console.log('💡 To add images to all products:');
      console.log('   Run: node add_product_images.js\n');
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error('\n🔍 Common issues:');
    console.error('   1. Check internet connection');
    console.error('   2. Verify Firebase credentials');
    console.error('   3. Check Firestore rules allow reads\n');
  }

  process.exit(0);
}

checkProducts();
