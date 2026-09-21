import '../models/product_model.dart';
import '../models/inventory_model.dart';
import '../config/product_images.dart';

/// Production-ready sample data with real images
class SampleDataService {
  SampleDataService._();

  /// Get sample products with real images
  static List<ProductModel> getSampleProducts() {
    final now = DateTime.now();
    
    return [
      // Electronics
      ProductModel(
        id: 'prod_001',
        name: 'Premium Wireless Headphones',
        category: 'Electronics',
        description: 'High-quality wireless headphones with active noise cancellation, 30-hour battery life, and premium sound quality.',
        purchasePrice: 1500,
        sellingPrice: 2499,
        unit: 'pcs',
        barcode: '8901234567890',
        imageUrl: ProductImages.headphones,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      ProductModel(
        id: 'prod_002',
        name: 'MacBook Pro 2024',
        category: 'Electronics',
        description: 'Latest MacBook Pro with M3 chip, 16GB RAM, 512GB SSD. Perfect for professionals.',
        purchasePrice: 150000,
        sellingPrice: 189999,
        unit: 'pcs',
        barcode: '8901234567891',
        imageUrl: ProductImages.laptop,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      ProductModel(
        id: 'prod_003',
        name: 'iPhone 15 Pro',
        category: 'Electronics',
        description: 'Latest iPhone with A17 Pro chip, titanium design, and advanced camera system.',
        purchasePrice: 120000,
        sellingPrice: 134900,
        unit: 'pcs',
        barcode: '8901234567892',
        imageUrl: ProductImages.smartphone,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      ProductModel(
        id: 'prod_004',
        name: 'Apple Watch Series 9',
        category: 'Electronics',
        description: 'Advanced health monitoring, fitness tracking, and smart features.',
        purchasePrice: 35000,
        sellingPrice: 41900,
        unit: 'pcs',
        barcode: '8901234567893',
        imageUrl: ProductImages.smartwatch,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),

      // Food & Grocery
      ProductModel(
        id: 'prod_005',
        name: 'Basmati Rice 5kg',
        category: 'Grocery',
        description: 'Premium aged basmati rice. Long grain, aromatic, and perfect for biryani.',
        purchasePrice: 180,
        sellingPrice: 299,
        unit: 'kg',
        barcode: '8901234567894',
        imageUrl: ProductImages.rice,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      ProductModel(
        id: 'prod_006',
        name: 'Organic Green Tea',
        category: 'Grocery',
        description: 'Premium organic green tea leaves. Rich in antioxidants and great taste.',
        purchasePrice: 120,
        sellingPrice: 199,
        unit: 'box',
        barcode: '8901234567895',
        imageUrl: ProductImages.tea,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      ProductModel(
        id: 'prod_007',
        name: 'Premium Coffee Beans',
        category: 'Grocery',
        description: 'Arabica coffee beans from South India. Rich aroma and perfect brewing.',
        purchasePrice: 280,
        sellingPrice: 449,
        unit: 'kg',
        barcode: '8901234567896',
        imageUrl: ProductImages.coffee,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      ProductModel(
        id: 'prod_008',
        name: 'Whole Wheat Bread',
        category: 'Grocery',
        description: 'Fresh whole wheat bread. Healthy and delicious for daily consumption.',
        purchasePrice: 25,
        sellingPrice: 45,
        unit: 'loaf',
        barcode: '8901234567897',
        imageUrl: ProductImages.bread,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),

      // Clothing
      ProductModel(
        id: 'prod_009',
        name: 'Cotton T-Shirt',
        category: 'Clothing',
        description: '100% cotton comfortable t-shirt. Available in multiple colors and sizes.',
        purchasePrice: 150,
        sellingPrice: 299,
        unit: 'pcs',
        barcode: '8901234567898',
        imageUrl: ProductImages.tshirt,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      ProductModel(
        id: 'prod_010',
        name: 'Slim Fit Jeans',
        category: 'Clothing',
        description: 'Premium denim jeans with slim fit. Durable and stylish.',
        purchasePrice: 600,
        sellingPrice: 1299,
        unit: 'pcs',
        barcode: '8901234567899',
        imageUrl: ProductImages.jeans,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      ProductModel(
        id: 'prod_011',
        name: 'Running Shoes',
        category: 'Footwear',
        description: 'Comfortable running shoes with excellent grip and cushioning.',
        purchasePrice: 1200,
        sellingPrice: 2499,
        unit: 'pair',
        barcode: '8901234567900',
        imageUrl: ProductImages.shoes,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),

      // Home & Living
      ProductModel(
        id: 'prod_012',
        name: 'Designer Table Lamp',
        category: 'Home',
        description: 'Modern designer table lamp. Perfect for bedroom or study.',
        purchasePrice: 400,
        sellingPrice: 799,
        unit: 'pcs',
        barcode: '8901234567901',
        imageUrl: ProductImages.lamp,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      ProductModel(
        id: 'prod_013',
        name: 'Decorative Cushion',
        category: 'Home',
        description: 'Soft decorative cushion with premium fabric. Multiple designs available.',
        purchasePrice: 150,
        sellingPrice: 349,
        unit: 'pcs',
        barcode: '8901234567902',
        imageUrl: ProductImages.cushion,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),

      // Beauty
      ProductModel(
        id: 'prod_014',
        name: 'Designer Perfume',
        category: 'Beauty',
        description: 'Long-lasting designer perfume. Elegant fragrance for special occasions.',
        purchasePrice: 1800,
        sellingPrice: 2999,
        unit: 'bottle',
        barcode: '8901234567903',
        imageUrl: ProductImages.perfume,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      ProductModel(
        id: 'prod_015',
        name: 'Matte Lipstick',
        category: 'Beauty',
        description: 'Long-wear matte lipstick. Rich color and smooth application.',
        purchasePrice: 250,
        sellingPrice: 499,
        unit: 'pcs',
        barcode: '8901234567904',
        imageUrl: ProductImages.lipstick,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),

      // Sports
      ProductModel(
        id: 'prod_016',
        name: 'Premium Yoga Mat',
        category: 'Sports',
        description: 'Non-slip yoga mat with excellent cushioning. Eco-friendly material.',
        purchasePrice: 400,
        sellingPrice: 799,
        unit: 'pcs',
        barcode: '8901234567905',
        imageUrl: ProductImages.yogaMat,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      ProductModel(
        id: 'prod_017',
        name: 'Professional Football',
        category: 'Sports',
        description: 'FIFA approved professional football. Perfect for matches and practice.',
        purchasePrice: 800,
        sellingPrice: 1499,
        unit: 'pcs',
        barcode: '8901234567906',
        imageUrl: ProductImages.football,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),

      // Books
      ProductModel(
        id: 'prod_018',
        name: 'Business Strategy Guide',
        category: 'Books',
        description: 'Comprehensive business strategy guide by leading experts.',
        purchasePrice: 300,
        sellingPrice: 599,
        unit: 'book',
        barcode: '8901234567907',
        imageUrl: ProductImages.book,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      ProductModel(
        id: 'prod_019',
        name: 'Premium Notebook',
        category: 'Stationery',
        description: 'High-quality notebook with ruled pages. Perfect for notes and journaling.',
        purchasePrice: 80,
        sellingPrice: 149,
        unit: 'pcs',
        barcode: '8901234567908',
        imageUrl: ProductImages.notebook,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),

      // Toys
      ProductModel(
        id: 'prod_020',
        name: 'Remote Control Car',
        category: 'Toys',
        description: 'High-speed remote control car. Great gift for kids.',
        purchasePrice: 600,
        sellingPrice: 1299,
        unit: 'pcs',
        barcode: '8901234567909',
        imageUrl: ProductImages.toycar,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  /// Get sample inventory items
  static List<InventoryModel> getSampleInventory(String storeId) {
    final now = DateTime.now();
    final products = getSampleProducts();
    
    return products.asMap().entries.map((entry) {
      final index = entry.key;
      final product = entry.value;
      
      // Vary stock levels for realistic demo
      int currentStock;
      int minLevel;
      int maxLevel;
      
      if (index % 5 == 0) {
        // Out of stock
        currentStock = 0;
        minLevel = 10;
        maxLevel = 50;
      } else if (index % 3 == 0) {
        // Low stock
        currentStock = 8;
        minLevel = 15;
        maxLevel = 50;
      } else {
        // Normal stock
        currentStock = 35 + (index * 3);
        minLevel = 15;
        maxLevel = 100;
      }
      
      return InventoryModel(
        id: '${storeId}_${product.id}',
        storeId: storeId,
        productId: product.id,
        productName: product.name,
        category: product.category,
        currentStock: currentStock,
        minimumStockLevel: minLevel,
        maximumStockLevel: maxLevel,
        imageUrl: product.imageUrl,
        lastUpdated: now,
      );
    }).toList();
  }
}
