/// Production-ready product image URLs
/// These are placeholder.com images that can be replaced with your actual CDN URLs

class ProductImages {
  ProductImages._();

  // Category-specific placeholder images
  static const String _placeholderBase = 'https://images.unsplash.com';

  // Electronics
  static const String headphones = '$_placeholderBase/photo-1505740420928-5e560c06d30e?w=400'; // Headphones
  static const String laptop = '$_placeholderBase/photo-1496181133206-80ce9b88a853?w=400'; // Laptop
  static const String smartphone = '$_placeholderBase/photo-1511707171634-5f897ff02aa9?w=400'; // Phone
  static const String tablet = '$_placeholderBase/photo-1561154464-82e9adf32764?w=400'; // Tablet
  static const String smartwatch = '$_placeholderBase/photo-1523275335684-37898b6baf30?w=400'; // Watch
  static const String camera = '$_placeholderBase/photo-1526170375885-4d8ecf77b99f?w=400'; // Camera

  // Food & Grocery
  static const String rice = '$_placeholderBase/photo-1586201375761-83865001e31c?w=400'; // Rice
  static const String pasta = '$_placeholderBase/photo-1551462147-37bd70de335a?w=400'; // Pasta
  static const String coffee = '$_placeholderBase/photo-1559056199-641a0ac8b55e?w=400'; // Coffee
  static const String tea = '$_placeholderBase/photo-1564890369478-c89ca6d9cde9?w=400'; // Tea
  static const String bread = '$_placeholderBase/photo-1509440159596-0249088772ff?w=400'; // Bread
  static const String milk = '$_placeholderBase/photo-1563636619-e9143da7973b?w=400'; // Milk
  static const String fruits = '$_placeholderBase/photo-1610832958506-aa56368176cf?w=400'; // Fruits
  static const String vegetables = '$_placeholderBase/photo-1540420773420-3366772f4999?w=400'; // Vegetables

  // Clothing
  static const String tshirt = '$_placeholderBase/photo-1521572163474-6864f9cf17ab?w=400'; // T-shirt
  static const String jeans = '$_placeholderBase/photo-1542272604-787c3835535d?w=400'; // Jeans
  static const String dress = '$_placeholderBase/photo-1595777457583-95e059d581b8?w=400'; // Dress
  static const String jacket = '$_placeholderBase/photo-1551028719-00167b16eac5?w=400'; // Jacket
  static const String shoes = '$_placeholderBase/photo-1542291026-7eec264c27ff?w=400'; // Shoes
  static const String sneakers = '$_placeholderBase/photo-1460353581641-37baddab0fa2?w=400'; // Sneakers

  // Home & Living
  static const String sofa = '$_placeholderBase/photo-1555041469-a586c61ea9bc?w=400'; // Sofa
  static const String lamp = '$_placeholderBase/photo-1507473885765-e6ed057f782c?w=400'; // Lamp
  static const String cushion = '$_placeholderBase/photo-1629352759186-7a2fa9a1638a?w=400'; // Cushion
  static const String plant = '$_placeholderBase/photo-1463320726281-696a485928c7?w=400'; // Plant

  // Beauty & Personal Care
  static const String perfume = '$_placeholderBase/photo-1541643600914-78b084683601?w=400'; // Perfume
  static const String lipstick = '$_placeholderBase/photo-1586495777744-4413f21062fa?w=400'; // Lipstick
  static const String skincare = '$_placeholderBase/photo-1556228578-0d85b1a4d571?w=400'; // Skincare

  // Sports & Fitness
  static const String dumbbell = '$_placeholderBase/photo-1517836357463-d25dfeac3438?w=400'; // Gym
  static const String yogaMat = '$_placeholderBase/photo-1601925260368-ae2f83cf8b7f?w=400'; // Yoga
  static const String football = '$_placeholderBase/photo-1606925797300-0b35e9d1794e?w=400'; // Football

  // Books & Stationery
  static const String book = '$_placeholderBase/photo-1512820790803-83ca734da794?w=400'; // Book
  static const String notebook = '$_placeholderBase/photo-1517842645767-c639042777db?w=400'; // Notebook
  static const String pen = '$_placeholderBase/photo-1585366119957-e9730b6d0f60?w=400'; // Pen

  // Toys
  static const String toycar = '$_placeholderBase/photo-1558060370-d644479cb6f7?w=400'; // Toy Car
  static const String teddybear = '$_placeholderBase/photo-1530325553241-4f6e7690cf36?w=400'; // Teddy

  // Sample product images for demos
  static const Map<String, String> sampleProducts = {
    // Electronics
    'Premium Wireless Headphones': headphones,
    'MacBook Pro 2024': laptop,
    'iPhone 15 Pro': smartphone,
    'iPad Air': tablet,
    'Apple Watch Series 9': smartwatch,
    'Canon EOS R6': camera,
    
    // Food & Grocery
    'Basmati Rice 5kg': rice,
    'Organic Green Tea': tea,
    'Premium Coffee Beans': coffee,
    'Whole Wheat Bread': bread,
    'Fresh Milk 1L': milk,
    'Penne Pasta 500g': pasta,
    'Seasonal Fruits Mix': fruits,
    'Farm Fresh Vegetables': vegetables,
    
    // Clothing
    'Cotton T-Shirt': tshirt,
    'Slim Fit Jeans': jeans,
    'Summer Dress': dress,
    'Leather Jacket': jacket,
    'Running Shoes': shoes,
    'White Sneakers': sneakers,
    
    // Home
    'Modern Sofa': sofa,
    'Designer Table Lamp': lamp,
    'Decorative Cushion': cushion,
    'Indoor Plant': plant,
    
    // Beauty
    'Designer Perfume': perfume,
    'Matte Lipstick': lipstick,
    'Anti-Aging Cream': skincare,
    
    // Sports
    'Adjustable Dumbbells': dumbbell,
    'Premium Yoga Mat': yogaMat,
    'Professional Football': football,
    
    // Books
    'Business Strategy Guide': book,
    'Premium Notebook': notebook,
    'Luxury Fountain Pen': pen,
    
    // Toys
    'Remote Control Car': toycar,
    'Soft Teddy Bear': teddybear,
  };

  /// Get image URL for a product by name
  static String? getImageUrl(String productName) {
    return sampleProducts[productName];
  }

  /// Get sample image for category
  static String getCategoryImage(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('electronic')) return headphones;
    if (cat.contains('food') || cat.contains('grocery')) return rice;
    if (cat.contains('cloth') || cat.contains('fashion')) return tshirt;
    if (cat.contains('home')) return sofa;
    if (cat.contains('beauty')) return perfume;
    if (cat.contains('sport')) return dumbbell;
    if (cat.contains('book')) return book;
    if (cat.contains('toy')) return toycar;
    return headphones; // Default
  }
}
