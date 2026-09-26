/**
 * Migration Script: Remove string-based date fields from sales collection
 * 
 * This script removes the denormalized 'date', 'month', and 'year' string fields
 * from all documents in the 'sales' collection, keeping only the 'timestamp' field.
 * 
 * Usage:
 *   node migrate_sales_dates.js
 */

const admin = require('firebase-admin');
const serviceAccount = require('./seed/store-inventory-sale-manage-firebase-adminsdk-fbsvc-2d3176b5ac.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function migrateSalesDates() {
  console.log('🔄 Starting migration: Removing string-based date fields from sales...\n');

  try {
    const salesRef = db.collection('sales');
    const snapshot = await salesRef.get();

    if (snapshot.empty) {
      console.log('ℹ️  No sales documents found.');
      return;
    }

    console.log(`📊 Found ${snapshot.size} sales documents to migrate.\n`);

    let successCount = 0;
    let errorCount = 0;
    const batch = db.batch();
    let batchCount = 0;
    const BATCH_SIZE = 500; // Firestore batch limit

    for (const doc of snapshot.docs) {
      const data = doc.data();
      
      // Check if the document has the old string-based date fields
      if (data.date || data.month || data.year) {
        // Create update object to remove these fields
        const updates = {
          date: admin.firestore.FieldValue.delete(),
          month: admin.firestore.FieldValue.delete(),
          year: admin.firestore.FieldValue.delete()
        };

        batch.update(doc.ref, updates);
        batchCount++;

        console.log(`  - Queued: ${doc.id} (Invoice: ${data.invoiceNumber || 'N/A'})`);

        // Commit batch if we reach the limit
        if (batchCount === BATCH_SIZE) {
          try {
            await batch.commit();
            successCount += batchCount;
            console.log(`\n✅ Committed batch of ${batchCount} documents.\n`);
            batchCount = 0;
          } catch (error) {
            console.error(`❌ Error committing batch: ${error.message}`);
            errorCount += batchCount;
            batchCount = 0;
          }
        }
      }
    }

    // Commit remaining documents
    if (batchCount > 0) {
      try {
        await batch.commit();
        successCount += batchCount;
        console.log(`\n✅ Committed final batch of ${batchCount} documents.\n`);
      } catch (error) {
        console.error(`❌ Error committing final batch: ${error.message}`);
        errorCount += batchCount;
      }
    }

    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('📈 Migration Summary:');
    console.log(`   ✅ Successfully migrated: ${successCount} documents`);
    console.log(`   ❌ Errors: ${errorCount} documents`);
    console.log(`   📊 Total processed: ${snapshot.size} documents`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    if (successCount > 0) {
      console.log('✨ Migration completed successfully!');
      console.log('💡 The "date", "month", and "year" fields have been removed.');
      console.log('💡 Your sales now use only the "timestamp" field for date queries.\n');
    }

  } catch (error) {
    console.error('❌ Migration failed:', error);
    throw error;
  } finally {
    // Close the connection
    await admin.app().delete();
  }
}

// Run the migration
migrateSalesDates()
  .then(() => {
    console.log('🎉 Script completed.');
    process.exit(0);
  })
  .catch((error) => {
    console.error('💥 Script failed:', error);
    process.exit(1);
  });
