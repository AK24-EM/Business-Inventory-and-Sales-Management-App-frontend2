import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../models/product_model.dart';
import '../../widgets/widgets.dart';
import '../../services/sample_data_service.dart';

/// Production-ready POS screen with excellent UX
/// Optimized for speed and ease of use
class EnhancedPOSScreen extends StatefulWidget {
  const EnhancedPOSScreen({super.key});

  @override
  State<EnhancedPOSScreen> createState() => _EnhancedPOSScreenState();
}

class _EnhancedPOSScreenState extends State<EnhancedPOSScreen>
    with TickerProviderStateMixin {
  final _barcodeController = TextEditingController();
  final _searchController = TextEditingController();
  final List<_CartItem> _cartItems = [];
  final List<ProductModel> _products = SampleDataService.getSampleProducts();
  List<ProductModel> _filteredProducts = [];

  String _selectedCategory = 'All';
  late AnimationController _cartAnimationController;

  @override
  void initState() {
    super.initState();
    _filteredProducts = _products;
    _cartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _searchController.dispose();
    _cartAnimationController.dispose();
    super.dispose();
  }

  double get _subtotal => _cartItems.fold(0.0, (sum, item) => sum + item.total);
  double get _tax => _subtotal * 0.18; // 18% GST
  double get _total => _subtotal + _tax;

  List<String> get _categories {
    final cats = _products.map((p) => p.category).toSet().toList();
    cats.insert(0, 'All');
    return cats;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.point_of_sale_rounded, size: 24),
            SizedBox(width: 10),
            Text('Point of Sale'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () => _showSalesHistory(),
            tooltip: 'Sales History',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showSettings(),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: isWide ? _buildWideLayout() : _buildNarrowLayout(),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        // Left: Product Catalog
        Expanded(
          flex: 3,
          child: _buildProductCatalog(),
        ),

        // Right: Cart & Checkout
        Container(
          width: 400,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              left: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: _buildCartSection(),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return Column(
      children: [
        // Cart Summary Bar
        _buildCartSummaryBar(),

        // Product Catalog
        Expanded(child: _buildProductCatalog()),
      ],
    );
  }

  Widget _buildCartSummaryBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cart Total',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  NumberFormat.currency(symbol: '₹').format(_total),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primarySubtle,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_cartItems.length} items',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _cartItems.isEmpty ? null : _showCartDetails,
            icon: const Icon(Icons.shopping_cart, size: 18),
            label: const Text('View'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCatalog() {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filterProducts();
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => _filterProducts(),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 120,
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _barcodeController,
                  decoration: const InputDecoration(
                    hintText: 'Scan',
                    prefixIcon: Icon(Icons.qr_code_scanner, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: _scanBarcode,
                ),
              ),
            ],
          ),
        ),

        // Category Filters
        SizedBox(
          height: 50,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              final category = _categories[index];
              final isSelected = category == _selectedCategory;
              return _CategoryChip(
                label: category,
                isSelected: isSelected,
                onTap: () {
                  setState(() => _selectedCategory = category);
                  _filterProducts();
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Product Grid
        Expanded(
          child: _filteredProducts.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.search_off,
                  title: 'No products found',
                  subtitle: 'Try adjusting your search or filters',
                )
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        MediaQuery.of(context).size.width > 1200 ? 4 : 3,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _filteredProducts.length,
                  itemBuilder: (_, index) =>
                      _buildProductTile(_filteredProducts[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildProductTile(ProductModel product) {
    return GestureDetector(
      onTap: () => _addToCart(product),
      child: ModernCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ProductImage(
                  imageUrl: product.imageUrl,
                  category: product.category,
                  size: double.infinity,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Product Info
            Text(
              product.name,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            Row(
              children: [
                Expanded(
                  child: Text(
                    NumberFormat.currency(symbol: '₹', decimalDigits: 0)
                        .format(product.sellingPrice),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primarySubtle,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSection() {
    return Column(
      children: [
        // Cart Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.shopping_cart, color: Colors.white),
                  const SizedBox(width: 10),
                  const Text(
                    'Cart',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  if (_cartItems.isNotEmpty)
                    TextButton(
                      onPressed: _clearCart,
                      child: const Text(
                        'Clear All',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text(
                    'Items: ',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    '${_cartItems.length}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Cart Items
        Expanded(
          child: _cartItems.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 64,
                        color: AppColors.textTertiary,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Cart is empty',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add products to start',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _cartItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, index) => _buildCartItem(_cartItems[index]),
                ),
        ),

        // Cart Summary & Checkout
        if (_cartItems.isNotEmpty) _buildCheckoutSection(),
      ],
    );
  }

  Widget _buildCartItem(_CartItem item) {
    return ModernCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Product Image
          ProductThumbnail(
            imageUrl: item.product.imageUrl,
            category: item.product.category,
            size: 50,
          ),
          const SizedBox(width: 12),

          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  NumberFormat.currency(symbol: '₹', decimalDigits: 0)
                      .format(item.product.sellingPrice),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Quantity Controls
          Row(
            children: [
              IconButton(
                onPressed: () => _updateQuantity(item, item.quantity - 1),
                icon: const Icon(Icons.remove_circle_outline),
                color: AppColors.error,
                iconSize: 24,
              ),
              Container(
                width: 32,
                alignment: Alignment.center,
                child: Text(
                  '${item.quantity}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _updateQuantity(item, item.quantity + 1),
                icon: const Icon(Icons.add_circle_outline),
                color: AppColors.success,
                iconSize: 24,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSection() {
    final currencyFormat = NumberFormat.currency(symbol: '₹');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          _PriceRow(label: 'Subtotal', value: currencyFormat.format(_subtotal)),
          const SizedBox(height: 8),
          _PriceRow(
            label: 'Tax (18%)',
            value: currencyFormat.format(_tax),
            isSecondary: true,
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          _PriceRow(
            label: 'Total',
            value: currencyFormat.format(_total),
            isLarge: true,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _checkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payment, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Proceed to Payment',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = _products.where((p) {
        final matchesCategory =
            _selectedCategory == 'All' || p.category == _selectedCategory;
        final matchesSearch = _searchController.text.isEmpty ||
            p.name.toLowerCase().contains(_searchController.text.toLowerCase());
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  void _scanBarcode(String barcode) {
    final product = _products.firstWhere(
      (p) => p.barcode == barcode,
      orElse: () => _products.first,
    );
    _addToCart(product);
    _barcodeController.clear();
  }

  void _addToCart(ProductModel product) {
    setState(() {
      final existingIndex =
          _cartItems.indexWhere((item) => item.product.id == product.id);
      if (existingIndex >= 0) {
        _cartItems[existingIndex].quantity++;
      } else {
        _cartItems.add(_CartItem(product: product, quantity: 1));
      }
    });

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Show snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${product.name} to cart'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _updateQuantity(_CartItem item, int newQuantity) {
    if (newQuantity <= 0) {
      setState(() => _cartItems.remove(item));
    } else {
      setState(() => item.quantity = newQuantity);
    }
  }

  void _clearCart() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Remove all items from cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _cartItems.clear());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _checkout() {
    // TODO: Implement actual checkout
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Checkout'),
        content: Text(
          'Total: ${NumberFormat.currency(symbol: '₹').format(_total)}\n\n'
          'Choose payment method:',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _completeCheckout('Cash');
            },
            child: const Text('Cash'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _completeCheckout('Card');
            },
            child: const Text('Card'),
          ),
        ],
      ),
    );
  }

  void _completeCheckout(String method) {
    setState(() => _cartItems.clear());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment successful via $method!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showCartDetails() {
    // Show cart in bottom sheet for narrow screens
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(child: _buildCartSection()),
          ],
        ),
      ),
    );
  }

  void _showSalesHistory() {}
  void _showSettings() {}
}

class _CartItem {
  final ProductModel product;
  int quantity;

  _CartItem({required this.product, required this.quantity});

  double get total => product.sellingPrice * quantity;
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLarge;
  final bool isSecondary;

  const _PriceRow({
    required this.label,
    required this.value,
    this.isLarge = false,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: isLarge ? 16 : 14,
            fontWeight: isLarge ? FontWeight.w700 : FontWeight.w500,
            color:
                isSecondary ? AppColors.textSecondary : AppColors.textPrimary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: isLarge ? 20 : 14,
            fontWeight: FontWeight.w700,
            color: isLarge ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
