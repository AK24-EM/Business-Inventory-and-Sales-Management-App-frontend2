/**
 * test_single_image.js
 *
 * Quickly test adding an image to a single product
 * This helps debug if images are loading correctly
 *
 * Run: node test_single_image.js
 */

const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('./store-inventory-sale-manage-firebase-adminsdk-fbsvc-2d3176b5ac.json');

initializeApp({
  credential: cert(serviceAccount),
  projectId: 'store-inventory-sale-manage',
});

const db = getFirestore();

// Test with a simple, reliable image URL
const TEST_IMAGE_URL = 'https://picsum.photos/400/400';

async function testSingleImage() {
  console.log('\n🧪 Testing image on a single product...\n');

  try {
    // Get the first product
    const productsSnapshot = await db.collection('products').limit(1).get();
    
    if (productsSnapshot.empty) {
      console.log('❌ No products found');
      return;
    }

    const firstProduct = productsSnapshot.docs[0];
    const productData = firstProduct.data();
    
    console.log(`📦 Product: ${productData.name}`);
    console.log(`🆔 ID: ${firstProduct.id}`);
    console.log(`📸 Current imageUrl: ${productData.imageUrl || 'none'}\n`);

    // Update with test image
    await firstProduct.ref.update({
      imageUrl: TEST_IMAGE_URL,
      updatedAt: new Date(),
    });

    console.log('✅ Updated product with test image:');
    console.log(`   ${TEST_IMAGE_URL}\n`);
    console.log('🎯 Next steps:');
    console.log('   1. Restart your Flutter app');
    console.log('   2. Go to POS screen');
    console.log(`   3. Look for "${productData.name}"`);
    console.log('   4. Should see a random placeholder image\n');
    console.log('💡 If image shows, your setup works!');
    console.log('   Then run: node add_product_images.js\n');

  } catch (error) {
    console.error('❌ Error:', error.message);
  }

  process.exit(0);
}

testSingleImage();
