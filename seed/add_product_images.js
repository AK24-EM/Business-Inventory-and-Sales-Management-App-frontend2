/**
 * add_product_images.js
 *
 * Adds image URLs to existing products in Firestore
 * Uses placeholder images and real product images where available
 *
 * Run from the seed/ directory:
 *   node add_product_images.js
 */

const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('./store-inventory-sale-manage-firebase-adminsdk-fbsvc-2d3176b5ac.json');

initializeApp({
  credential: cert(serviceAccount),
  projectId: 'store-inventory-sale-manage',
});

const db = getFirestore();

// ═════════════════════════════════════════════════════════════════════════════
// Product Image Mappings
// ═════════════════════════════════════════════════════════════════════════════

const productImages = {
  // Groceries & Staples
  'Tata Salt': 'https://images.unsplash.com/photo-1576678927484-cc907957ef4a?w=400',
  'Aashirvaad Atta': 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=400',
  'Fortune Rice': 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=400',
  'Sugar': 'https://images.unsplash.com/photo-1582169296194-e4d644c48063?w=400',
  'Toor Dal': 'https://images.unsplash.com/photo-1596797882870-8c33deeaadf1?w=400',
  'Moong Dal': 'https://images.unsplash.com/photo-1596797882870-8c33deeaadf1?w=400',
  'Chana Dal': 'https://images.unsplash.com/photo-1596797882870-8c33deeaadf1?w=400',
  'Masoor Dal': 'https://images.unsplash.com/photo-1596797882870-8c33deeaadf1?w=400',
  
  // Cooking Oils
  'Fortune Sunflower Oil': 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=400',
  'Saffola Oil': 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=400',
  'Mustard Oil': 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=400',
  
  // Spices
  'Red Chilli Powder': 'https://images.unsplash.com/photo-1599909533730-f80d515305f1?w=400',
  'Turmeric Powder': 'https://images.unsplash.com/photo-1615485500704-8e990f9900f7?w=400',
  'Coriander Powder': 'https://images.unsplash.com/photo-1599909533730-f80d515305f1?w=400',
  'Garam Masala': 'https://images.unsplash.com/photo-1599909533730-f80d515305f1?w=400',
  'Cumin Seeds': 'https://images.unsplash.com/photo-1599909533730-f80d515305f1?w=400',
  
  // Beverages
  'Coca Cola': 'https://images.unsplash.com/photo-1554866585-cd94860890b7?w=400',
  'Pepsi': 'https://images.unsplash.com/photo-1629203851122-3726ecdf080e?w=400',
  'Sprite': 'https://images.unsplash.com/photo-1625772299848-391b6a87d7b3?w=400',
  'Thums Up': 'https://images.unsplash.com/photo-1629203851122-3726ecdf080e?w=400',
  'Limca': 'https://images.unsplash.com/photo-1625772299848-391b6a87d7b3?w=400',
  'Mountain Dew': 'https://images.unsplash.com/photo-1629203851122-3726ecdf080e?w=400',
  'Fanta': 'https://images.unsplash.com/photo-1625772299848-391b6a87d7b3?w=400',
  
  // Dairy Products
  'Mother Dairy Milk': 'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=400',
  'Amul Milk': 'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=400',
  'Amul Butter': 'https://images.unsplash.com/photo-1589985270826-4b7bb135bc9d?w=400',
  'Amul Cheese': 'https://images.unsplash.com/photo-1618164436241-4473940d1f5c?w=400',
  'Nestle Dahi': 'https://images.unsplash.com/photo-1571212515416-fca704a71954?w=400',
  'Britannia Paneer': 'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=400',
  
  // Snacks
  'Lays Classic': 'https://images.unsplash.com/photo-1621447504864-d8686e12698c?w=400',
  'Kurkure': 'https://images.unsplash.com/photo-1621447504864-d8686e12698c?w=400',
  'Haldiram Bhujia': 'https://images.unsplash.com/photo-1621447504864-d8686e12698c?w=400',
  'Bingo Chips': 'https://images.unsplash.com/photo-1621447504864-d8686e12698c?w=400',
  'Uncle Chips': 'https://images.unsplash.com/photo-1621447504864-d8686e12698c?w=400',
  
  // Biscuits & Cookies
  'Parle G': 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=400',
  'Britannia Marie': 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=400',
  'Good Day': 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=400',
  'Oreo': 'https://images.unsplash.com/photo-1606890737304-57a1ca8a5b62?w=400',
  'Hide & Seek': 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=400',
  'Monaco': 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=400',
  
  // Chocolates
  'Dairy Milk': 'https://images.unsplash.com/photo-1511381939415-e44015466834?w=400',
  'KitKat': 'https://images.unsplash.com/photo-1606312619070-d48b4cda81f5?w=400',
  'Munch': 'https://images.unsplash.com/photo-1511381939415-e44015466834?w=400',
  'Perk': 'https://images.unsplash.com/photo-1511381939415-e44015466834?w=400',
  '5 Star': 'https://images.unsplash.com/photo-1511381939415-e44015466834?w=400',
  
  // Tea & Coffee
  'Tata Tea Gold': 'https://images.unsplash.com/photo-1594631661960-6ab6c3dc988e?w=400',
  'Red Label Tea': 'https://images.unsplash.com/photo-1594631661960-6ab6c3dc988e?w=400',
  'Nescafe Coffee': 'https://images.unsplash.com/photo-1511920170033-f8396924c348?w=400',
  'Bru Coffee': 'https://images.unsplash.com/photo-1511920170033-f8396924c348?w=400',
  
  // Personal Care
  'Colgate': 'https://images.unsplash.com/photo-1622372738946-62e02505feb3?w=400',
  'Lux Soap': 'https://images.unsplash.com/photo-1582735689369-4fe89db7114c?w=400',
  'Dove Soap': 'https://images.unsplash.com/photo-1582735689369-4fe89db7114c?w=400',
  'Clinic Plus': 'https://images.unsplash.com/photo-1571875257727-256c39da42af?w=400',
  'Head & Shoulders': 'https://images.unsplash.com/photo-1571875257727-256c39da42af?w=400',
  'Pantene': 'https://images.unsplash.com/photo-1571875257727-256c39da42af?w=400',
  
  // Cleaning Products
  'Vim': 'https://images.unsplash.com/photo-1563453392212-326f5e854473?w=400',
  'Surf Excel': 'https://images.unsplash.com/photo-1610557892470-55d9e80c0bce?w=400',
  'Harpic': 'https://images.unsplash.com/photo-1563453392212-326f5e854473?w=400',
  'Lizol': 'https://images.unsplash.com/photo-1563453392212-326f5e854473?w=400',
  
  // Noodles & Pasta
  'Maggi': 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=400',
  'Top Ramen': 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=400',
  'Yippee Noodles': 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=400',
  
  // Sauces & Condiments
  'Maggi Ketchup': 'https://images.unsplash.com/photo-1598160788593-f5d35e1c56ca?w=400',
  'Kissan Jam': 'https://images.unsplash.com/photo-1484723091739-30a097e8f929?w=400',
  'Veeba Mayonnaise': 'https://images.unsplash.com/photo-1598160788593-f5d35e1c56ca?w=400',
  
  // Fruits (Fresh)
  'Apple': 'https://images.unsplash.com/photo-1568702846914-96b305d2aaeb?w=400',
  'Banana': 'https://images.unsplash.com/photo-1603833665858-e61d17a86224?w=400',
  'Orange': 'https://images.unsplash.com/photo-1582979512210-99b6a53386f9?w=400',
  'Mango': 'https://images.unsplash.com/photo-1553279769-865429fe7e4f?w=400',
  'Grapes': 'https://images.unsplash.com/photo-1599819177818-6427921e0dfa?w=400',
  'Watermelon': 'https://images.unsplash.com/photo-1587049352846-4a222e784053?w=400',
  
  // Vegetables
  'Tomato': 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=400',
  'Onion': 'https://images.unsplash.com/photo-1618512496248-a07fe83aa8cb?w=400',
  'Potato': 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=400',
  'Carrot': 'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?w=400',
  'Cabbage': 'https://images.unsplash.com/photo-1594282486552-05b4d80fbb9f?w=400',
  'Cauliflower': 'https://images.unsplash.com/photo-1568584711075-3d021a7c3ca3?w=400',
};

// Fallback image for products without specific images
const fallbackImage = 'https://images.unsplash.com/photo-1506617564039-2f3b650b7010?w=400';

// ═════════════════════════════════════════════════════════════════════════════
// Update Products with Images
// ═════════════════════════════════════════════════════════════════════════════

async function addProductImages() {
  console.log('\n🖼️  Adding product images...\n');

  try {
    // Get all products
    const productsSnapshot = await db.collection('products').get();
    
    if (productsSnapshot.empty) {
      console.log('❌ No products found in Firestore');
      return;
    }

    console.log(`📦 Found ${productsSnapshot.size} products\n`);

    let updatedCount = 0;
    let skippedCount = 0;
    let notFoundCount = 0;

    const batch = db.batch();

    productsSnapshot.forEach((doc) => {
      const product = doc.data();
      const productName = product.name;

      // Skip if already has an image
      if (product.imageUrl && product.imageUrl.trim() !== '') {
        console.log(`⏭️  Skipped: ${productName} (already has image)`);
        skippedCount++;
        return;
      }

      // Find matching image
      let imageUrl = null;
      
      // Try exact match first
      if (productImages[productName]) {
        imageUrl = productImages[productName];
      } else {
        // Try partial match
        const matchedKey = Object.keys(productImages).find(key =>
          productName.toLowerCase().includes(key.toLowerCase()) ||
          key.toLowerCase().includes(productName.toLowerCase())
        );
        
        if (matchedKey) {
          imageUrl = productImages[matchedKey];
        } else {
          imageUrl = fallbackImage;
          notFoundCount++;
        }
      }

      // Update the product
      batch.update(doc.ref, {
        imageUrl: imageUrl,
        updatedAt: new Date(),
      });

      console.log(`✅ Updated: ${productName}`);
      updatedCount++;
    });

    // Commit all updates
    await batch.commit();

    console.log('\n' + '='.repeat(50));
    console.log('✨ Product images update complete!\n');
    console.log(`📊 Summary:`);
    console.log(`   ✅ Updated: ${updatedCount} products`);
    console.log(`   ⏭️  Skipped: ${skippedCount} products (already had images)`);
    console.log(`   🔍 Fallback: ${notFoundCount} products (used default image)`);
    console.log('='.repeat(50) + '\n');

  } catch (error) {
    console.error('❌ Error adding product images:', error);
    throw error;
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Main Execution
// ═════════════════════════════════════════════════════════════════════════════

async function main() {
  try {
    await addProductImages();
    console.log('🎉 All done!\n');
    process.exit(0);
  } catch (error) {
    console.error('❌ Script failed:', error);
    process.exit(1);
  }
}

main();
