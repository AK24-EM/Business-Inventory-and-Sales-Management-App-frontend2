import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../providers/sales_provider.dart';
import '../../providers/store_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../models/sale_model.dart';
import '../../models/product_model.dart';
import '../../models/inventory_model.dart';
import '../../models/customer_model.dart';
import '../../services/customer_service.dart';
import '../../widgets/store_header_widget.dart';



class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();

  String _selectedCategory = 'All';
  bool _loyaltyRedeemed = false;
  PaymentMode _selectedTender = PaymentMode.upi;

  // Live customer from Firestore lookup
  CustomerModel? _selectedCustomer;

  @override
  void initState() {
    super.initState();
    // Cart starts empty — no demo seeding
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Trigger product load
      context.read<ProductProvider>().loadProducts();
    });
  }

  void _selectCustomerModel(CustomerModel customer, {int loyaltyPoints = 0}) {
    setState(() {
      _selectedCustomer = customer;
      _phoneCtrl.text = customer.phone;
      _loyaltyRedeemed = loyaltyPoints >= 100;
    });

    final sales = context.read<SalesProvider>();
    sales.setCustomer(
      id: customer.id,
      name: customer.name,
      phone: customer.phone,
      availablePoints: loyaltyPoints,
    );
    sales.redeemPoints(_loyaltyRedeemed ? 100.0 : 0.0);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Attached customer: ${customer.name}'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _clearCustomer() {
    setState(() {
      _selectedCustomer = null;
      _phoneCtrl.clear();
      _loyaltyRedeemed = false;
    });
    final sales = context.read<SalesProvider>();
    sales.clearCustomer();
    sales.redeemPoints(0.0);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: isWide ? _buildWideLayout() : _buildMobileLayout(),
      ),
    );
  }

  // ── MOBILE LAYOUT (Continuous vertical scroll matching screenshot) ──
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top Store Header
          const StoreHeaderWidget(
            title: 'Pos Billing',
            subtitle: 'ACTIVE SHIFT • Till #02',
          ),

          const SizedBox(height: 8),

          // 2. Customer Loyalty Section
          _buildCustomerLoyaltySection(),

          const SizedBox(height: 12),

          // 3. Search Bar
          _buildSearchBar(),

          const SizedBox(height: 10),

          // 4. Category Filter Chips
          _buildCategoryFilterRow(),

          const SizedBox(height: 12),

          // 5. Product Catalog Grid
          _buildProductGrid(),

          const SizedBox(height: 12),

          // 6. Store Validation Banner
          _buildValidationBanner(),

          const SizedBox(height: 14),

          // 7. Active Cart & Checkout Panel
          _buildActiveCartSection(),
        ],
      ),
    );
  }

  // ── WIDE LAYOUT (Split screen for tablets / POS terminals) ──
  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Catalog
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const StoreHeaderWidget(
                  title: 'Pos Billing',
                  subtitle: 'ACTIVE SHIFT • Till #02',
                ),
                const SizedBox(height: 8),
                _buildCustomerLoyaltySection(),
                const SizedBox(height: 12),
                _buildSearchBar(),
                const SizedBox(height: 10),
                _buildCategoryFilterRow(),
                const SizedBox(height: 12),
                _buildProductGrid(),
                const SizedBox(height: 12),
                _buildValidationBanner(),
              ],
            ),
          ),
        ),

        // Vertical divider
        Container(
          width: 1,
          color: const Color(0xFFE2E8F0),
        ),

        // Right Column: Active Cart
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: _buildActiveCartSection(),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerLoyaltySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Phone / Name Search Input Box
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                // Tapping search icon opens customer finder modal
                InkWell(
                  onTap: () => _showCustomerFinderSheet(context),
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.person_search_rounded,
                      color: Color(0xFF2563EB),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.text,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintText: 'Search or enter customer phone / name...',
                      hintStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    onChanged: (v) => setState(() {}),
                  ),
                ),
                // Find from customers button
                TextButton(
                  onPressed: () => _showCustomerFinderSheet(context),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text(
                    'Find',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
                // Add customer button
                IconButton(
                  icon: const Icon(
                    Icons.person_add_alt_1_outlined,
                    color: Color(0xFF2563EB),
                    size: 19,
                  ),
                  tooltip: 'Register New Customer',
                  onPressed: () => _showRegisterCustomerDialog(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Attached Customer Card (or Walk-in placeholder)
          if (_selectedCustomer != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_user_rounded,
                    color: Color(0xFF2563EB),
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _selectedCustomer!.name,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () => _showCustomerFinderSheet(context),
                              child: const Icon(Icons.swap_horiz_rounded,
                                  size: 15, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                        Text(
                          _selectedCustomer!.phone,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: _clearCustomer,
                    child: const Icon(Icons.close,
                        size: 16, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_outline_rounded,
                      size: 20, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Walk-in Customer (No loyalty attached)',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showCustomerFinderSheet(context),
                    icon: const Icon(Icons.person_search_rounded,
                        size: 16, color: Color(0xFF2563EB)),
                    label: const Text(
                      'Find',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Customer Finder Modal — loaded from Firestore
  // ─────────────────────────────────────────────────────────────────────────
  void _showCustomerFinderSheet(BuildContext context) {
    final storeId = context.read<StoreProvider>().selectedStore?.id ?? '';
    final customerService = CustomerService();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FirestoreCustomerFinderModal(
        storeId: storeId,
        customerService: customerService,
        selectedId: _selectedCustomer?.id,
        onSelect: (customer) {
          Navigator.pop(ctx);
          _selectCustomerModel(customer);
        },
        onRegisterNew: () {
          Navigator.pop(ctx);
          _showRegisterCustomerDialog();
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. Search Bar + Barcode Scanner Action
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Search Input
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF64748B),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12.5,
                        color: Color(0xFF0F172A),
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Search product, SKU, barcode...',
                        hintStyle: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (v) => setState(() {}),
                    ),
                  ),
                  if (_searchCtrl.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear,
                          size: 16, color: Color(0xFF94A3B8)),
                      onPressed: () => setState(() => _searchCtrl.clear()),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Dedicated Barcode Scanner Button (Blue rounded tile)
          InkWell(
            onTap: () => _simulateBarcodeScan(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. Category Filter Chips — dynamic from Firestore
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCategoryFilterRow() {
    final categories = context.watch<ProductProvider>().categories;
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = categories[i];
          final isSelected = cat == _selectedCategory;

          return InkWell(
            onTap: () => setState(() => _selectedCategory = cat),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFE2E8F0),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  cat,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }



  // ─────────────────────────────────────────────────────────────────────────
  // 4. Product Catalog Grid — live from Firestore
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildProductGrid() {
    final q = _searchCtrl.text.toLowerCase().trim();
    final storeId =
        context.read<StoreProvider>().selectedStore?.id ?? 'store_01';
    final productProvider = context.watch<ProductProvider>();

    final products = productProvider.products.where((p) {
      if (!p.isActive) return false;
      final matchesCat =
          _selectedCategory == 'All' || p.category == _selectedCategory;
      final matchesQuery = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          (p.barcode?.toLowerCase().contains(q) ?? false);
      return matchesCat && matchesQuery;
    }).toList();

    if (productProvider.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: CircularProgressIndicator(color: Color(0xFF2563EB)),
        ),
      );
    }

    if (products.isEmpty) {
      return Container(
        height: 160,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inventory_2_outlined,
                  size: 40, color: Color(0xFF94A3B8)),
              const SizedBox(height: 8),
              Text(
                q.isNotEmpty
                    ? 'No matching products'
                    : 'No products added yet',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<List<InventoryModel>>(
      stream: context.read<InventoryProvider>().watchInventory(storeId),
      builder: (context, snapshot) {
        final inventoryMap = <String, InventoryModel>{};
        if (snapshot.hasData) {
          for (final inv in snapshot.data!) {
            inventoryMap[inv.productId] = inv;
          }
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.82,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: products.length,
            itemBuilder: (context, i) {
              final p = products[i];
              final inv = inventoryMap[p.id];
              final stock = inv?.currentStock ?? 0;
              final isLow = inv?.isLowStock ?? false;
              return _buildProductCard(p, stock: stock, isLow: isLow);
            },
          ),
        );
      },
    );
  }

  Widget _buildProductCard(ProductModel p,
      {required int stock, required bool isLow}) {
    final bool outOfStock = stock == 0;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: outOfStock
                ? const Color(0xFFFCA5A5)
                : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(13)),
                child: SizedBox(
                  height: 96,
                  width: double.infinity,
                  child: p.imageUrl != null && p.imageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: p.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: const Color(0xFFF1F5F9),
                            child: const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: const Color(0xFFF1F5F9),
                            child: const Icon(
                              Icons.inventory_2_outlined,
                              color: Color(0xFF94A3B8),
                              size: 32,
                            ),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFF1F5F9),
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            color: Color(0xFF94A3B8),
                            size: 32,
                          ),
                        ),
                ),
              ),
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: outOfStock
                        ? const Color(0xFFFEE2E2)
                        : isLow
                            ? const Color(0xFFFEF3C7)
                            : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: outOfStock
                          ? const Color(0xFFFCA5A5)
                          : isLow
                              ? const Color(0xFFFCD34D)
                              : const Color(0xFF86EFAC),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    outOfStock
                        ? 'Out of Stock'
                        : isLow
                            ? '$stock Left (Low)'
                            : '$stock In Stock',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: outOfStock
                          ? const Color(0xFF991B1B)
                          : isLow
                              ? const Color(0xFF92400E)
                              : const Color(0xFF166534),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  p.category,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '\u20b9${p.sellingPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (!outOfStock)
                      InkWell(
                        onTap: () => _addProductToCart(p, stock: stock),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB)
                                    .withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 18),
                        ),
                      )
                    else
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.block,
                            color: Color(0xFF94A3B8), size: 16),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addProductToCart(ProductModel p, {required int stock}) {
    final sales = context.read<SalesProvider>();
    sales.addToCart(CartItem(
      productId: p.id,
      productName: p.name,
      category: p.category,
      unitPrice: p.sellingPrice,
      quantity: 1,
      availableStock: stock,
    ));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${p.name}" to cart'),
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 5. Store Stock Validation Banner
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildValidationBanner() {
    final sales = context.watch<SalesProvider>();
    final count = sales.cart.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF047857), // Forest green pill
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF047857).withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.storefront_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'All $count active items validated against Downtown Store stock',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 6. Active Cart & Checkout Experience
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildActiveCartSection() {
    final sales = context.watch<SalesProvider>();
    final items = sales.cart;
    final totalUnits = sales.cartItemCount;

    final subtotal = sales.subtotal;
    // Loyalty discount is tracked by SalesProvider when customer is attached
    final loyaltyDiscount = sales.pointsDiscount;
    final gst = ((subtotal - loyaltyDiscount).clamp(0.0, double.infinity)) * 0.05;
    final netPayable =
        (subtotal - loyaltyDiscount + gst).clamp(0.0, double.infinity);

    final fmt = NumberFormat('#,##,##0.00', 'en_IN');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Bag Icon + Active Cart + 4 units + Clear
          Row(
            children: [
              const Icon(
                Icons.shopping_bag_outlined,
                color: Color(0xFF2563EB),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Active Cart',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Text(
                  '$totalUnits units',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ),
              const Spacer(),
              if (items.isNotEmpty)
                InkWell(
                  onTap: () => _confirmClearCart(),
                  child: const Row(
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          size: 15, color: Color(0xFFEF4444)),
                      SizedBox(width: 2),
                      Text(
                        'Clear',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // Item Rows
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Cart is empty. Tap "+" on any product above.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12.5,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 16, color: Color(0xFFF8FAFC)),
              itemBuilder: (context, i) {
                final item = items[i];
                return _buildCartItemRow(item);
              },
            ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),

          // Cost Breakdown
          _buildSummaryRow(
            'Cart Subtotal',
            '₹${fmt.format(subtotal)}',
            isBold: false,
          ),
          const SizedBox(height: 6),
          if (_loyaltyRedeemed && loyaltyDiscount > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.stars_rounded,
                        size: 14, color: Color(0xFF059669)),
                    SizedBox(width: 4),
                    Text(
                      'Loyalty Redeemed',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
                Text(
                  '-₹${fmt.format(loyaltyDiscount)}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF059669),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          _buildSummaryRow(
            'GST (5% Integrated)',
            '₹${fmt.format(gst)}',
            isBold: false,
          ),

          const SizedBox(height: 12),

          // NET TOTAL PAYABLE ROW
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'NET TOTAL PAYABLE',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              if (_loyaltyRedeemed && loyaltyDiscount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Savings: ₹${loyaltyDiscount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF166534),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 2),

          // Big bold blue total
          Text(
            '₹${fmt.format(netPayable)}',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1D4ED8), // Vibrant royal blue
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 14),

          // SELECT TENDER MODE
          const Text(
            'SELECT TENDER MODE',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),

          // 3 Tender Tabs: UPI / QR, Cash, Card
          Row(
            children: [
              _buildTenderTab(
                mode: PaymentMode.upi,
                label: 'UPI / QR',
                icon: Icons.qr_code_rounded,
              ),
              const SizedBox(width: 8),
              _buildTenderTab(
                mode: PaymentMode.cash,
                label: 'Cash',
                icon: Icons.payments_outlined,
              ),
              const SizedBox(width: 8),
              _buildTenderTab(
                mode: PaymentMode.card,
                label: 'Card',
                icon: Icons.credit_card_rounded,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Dynamic Tender Mode View
          _buildDynamicTenderView(netPayable),

          const SizedBox(height: 14),

          // Complete Sale Primary CTA
          ElevatedButton(
            onPressed: items.isEmpty ? null : () => _completeSale(netPayable),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF047857), // Forest green
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline_rounded,
                    size: 19, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Complete Sale (₹${fmt.format(netPayable)})',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Hold Bill / Print Quotation Secondary CTA
          OutlinedButton(
            onPressed: () => _showHoldBillDialog(netPayable),
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0xFFEFF6FF), // Soft ice blue
              foregroundColor: const Color(0xFF1E40AF),
              side: const BorderSide(color: Color(0xFFBFDBFE)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 17, color: Color(0xFF1E40AF)),
                SizedBox(width: 6),
                Text(
                  'Hold Bill / Print Quotation',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemRow(CartItem item) {
    final sales = context.read<SalesProvider>();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Name & Unit Price
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '₹${item.unitPrice.toStringAsFixed(0)} × ${item.quantity}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),

        // Stepper: [-] Qty [+]
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => sales.updateQuantity(
                    item.productId, item.quantity - 1),
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.remove, size: 14, color: Color(0xFF334155)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '${item.quantity}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              InkWell(
                onTap: () => sales.updateQuantity(
                    item.productId, item.quantity + 1),
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.add, size: 14, color: Color(0xFF334155)),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 14),

        // Line Total
        SizedBox(
          width: 58,
          child: Text(
            '₹${item.totalPrice.toStringAsFixed(0)}',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12.5,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildTenderTab({
    required PaymentMode mode,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedTender == mode;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTender = mode),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF2563EB) // Vibrant blue
                : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFFE2E8F0),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicTenderView(double amount) {
    if (_selectedTender == PaymentMode.upi) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            // Clean QR Code Graphic representation
            Container(
              width: 58,
              height: 58,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Image.network(
                'https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=upi://pay?pa=retailpulse.dt02@icici&pn=DowntownStore&am=${amount.toStringAsFixed(2)}',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.qr_code_2_rounded,
                      size: 40, color: Color(0xFF1E293B)),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Live status & UPI ID
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Store Counter QR Live',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'UPI ID: retailpulse.dt02@icici',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Auto-verifying payment...',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (_selectedTender == PaymentMode.cash) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Cash Received:',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _cashQuickChip('Exact (₹${amount.toStringAsFixed(0)})'),
                const SizedBox(width: 6),
                _cashQuickChip('₹500'),
                const SizedBox(width: 6),
                _cashQuickChip('₹2,000'),
              ],
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Row(
          children: [
            Icon(Icons.contactless_outlined,
                color: Color(0xFF2563EB), size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Card Machine #POS-02 Ready • Tap, Swipe or Insert Card on PIN pad',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _cashQuickChip(String label) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tender recorded: $label'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helper Actions & Dialogs
  // ─────────────────────────────────────────────────────────────────────────
  void _confirmClearCart() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Cart?', style: TextStyle(fontFamily: 'Poppins')),
        content: const Text(
          'Are you sure you want to remove all items from active cart?',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<SalesProvider>().clearCart();
              Navigator.pop(ctx);
            },
            child: const Text('Clear All',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _simulateBarcodeScan() {
    final barcodeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text('Scan Barcode', style: TextStyle(fontFamily: 'Poppins')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.qr_code_2_rounded,
                    color: Colors.white70, size: 60),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Enter barcode or SKU code manually:',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: barcodeCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Barcode / SKU',
                prefixIcon: Icon(Icons.qr_code),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              final code = barcodeCtrl.text.trim().toLowerCase();
              if (code.isEmpty) return;
              // Search in live products
              final products = context.read<ProductProvider>().products;
              final match = products.where((p) {
                return (p.barcode?.toLowerCase() == code) ||
                    p.name.toLowerCase().contains(code);
              }).firstOrNull;
              if (match != null) {
                setState(() => _searchCtrl.text = match.name);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('No product found for "$code"'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showRegisterCustomerDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Register New Customer',
              style: TextStyle(fontFamily: 'Poppins')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email (optional)',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (nameCtrl.text.trim().isEmpty ||
                          phoneCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Name and phone are required')),
                        );
                        return;
                      }
                      setDialogState(() => isSaving = true);

                      try {
                        final authProvider = context.read<AuthProvider>();
                        final storeProvider = context.read<StoreProvider>();
                        final customerService = CustomerService();

                        final customer = await customerService.registerCustomer(
                          name: nameCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          email: emailCtrl.text.trim().isEmpty
                              ? null
                              : emailCtrl.text.trim(),
                          storeId:
                              storeProvider.selectedStore?.id ?? 'store_01',
                          registeredByUserId: authProvider.currentUser?.id ?? '',
                        );

                        if (ctx.mounted) Navigator.pop(ctx);
                        _selectCustomerModel(customer);
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Failed to register customer: $e')),
                          );
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Register & Attach'),
            ),
          ],
        ),
      ),
    );
  }

  void _showHoldBillDialog(double amount) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hold Bill / Quotation',
            style: TextStyle(fontFamily: 'Poppins')),
        content: Text(
          'Current cart with payable ₹${amount.toStringAsFixed(2)} has been saved to Pending Bills #HLD-1092.\nYou can resume it anytime.',
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Dismiss'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Quotation printed on Till receipt printer'),
                ),
              );
            },
            child: const Text('Print Quotation'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeSale(double netPayable) async {
    final sales = context.read<SalesProvider>();
    final storeProvider = context.read<StoreProvider>();
    final authProvider = context.read<AuthProvider>();

    // Sync the UI-selected tender mode to provider before completing
    sales.setPaymentMode(_selectedTender);

    // Show loading indicator while persisting
    // We capture the dialog's own context so that Navigator.pop only
    // closes the dialog overlay — not a GoRouter route — avoiding the
    // "popped last page off the stack" assertion error.
    if (!mounted) return;
    BuildContext? loadingCtx;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        loadingCtx = ctx;
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF2563EB)),
        );
      },
    );

    SaleModel? completedSale;
    String? saleError;
    try {
      final store = storeProvider.selectedStore;
      final user = authProvider.currentUser;

      completedSale = await sales.completeSale(
        storeId: store?.id ?? 'store_default',
        storeName: store?.name ?? 'Downtown Central',
        employeeId: user?.id ?? 'emp_till02',
        employeeName: user?.name ?? 'Cashier',
      );
    } catch (e) {
      saleError = e.toString();
    }

    if (!mounted) return;
    // Pop loading dialog
    if (loadingCtx != null && loadingCtx!.mounted && Navigator.of(loadingCtx!).canPop()) {
      Navigator.of(loadingCtx!).pop();
    }

    if (completedSale == null || saleError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Could not complete sale to Firestore: ${saleError ?? "Unknown error"}'),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    final invoiceNo = completedSale.invoiceNumber ??
        'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Color(0xFF16A34A),
                size: 36,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Payment Received!',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '₹${netPayable.toStringAsFixed(2)} settled via ${_selectedTender.displayName.toUpperCase()}',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF059669),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Bill No: $invoiceNo\nTill #02 • Downtown Central\nCustomer: ${_selectedCustomer?.name ?? "Walk-in"}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<SalesProvider>().clearCart();
            },
            child: const Text('New Sale'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<SalesProvider>().clearCart();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Receipt printed successfully!'),
                ),
              );
            },
            child: const Text('Print Receipt'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Firestore-Backed Customer Finder Bottom Sheet Modal
// ─────────────────────────────────────────────────────────────────────────────
class _FirestoreCustomerFinderModal extends StatefulWidget {
  final String storeId;
  final CustomerService customerService;
  final String? selectedId;
  final ValueChanged<CustomerModel> onSelect;
  final VoidCallback onRegisterNew;

  const _FirestoreCustomerFinderModal({
    required this.storeId,
    required this.customerService,
    this.selectedId,
    required this.onSelect,
    required this.onRegisterNew,
  });

  @override
  State<_FirestoreCustomerFinderModal> createState() =>
      _FirestoreCustomerFinderModalState();
}

class _FirestoreCustomerFinderModalState
    extends State<_FirestoreCustomerFinderModal> {
  final TextEditingController _filterCtrl = TextEditingController();

  @override
  void dispose() {
    _filterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: EdgeInsets.only(
        top: 14,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Title & Register Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Find Customer',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              InkWell(
                onTap: widget.onRegisterNew,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.person_add_alt_1,
                          size: 14, color: Color(0xFF2563EB)),
                      SizedBox(width: 4),
                      Text(
                        '+ Register New',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Search Field inside modal
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 10),
                const Icon(Icons.search_rounded,
                    size: 18, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _filterCtrl,
                    autofocus: false,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12.5,
                      color: Color(0xFF0F172A),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search by customer name, phone, or email...',
                      hintStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11.5,
                        color: Color(0xFF94A3B8),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                if (_filterCtrl.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear,
                        size: 15, color: Color(0xFF94A3B8)),
                    onPressed: () => setState(() => _filterCtrl.clear()),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Real-time List of customers from Firestore
          Expanded(
            child: StreamBuilder<List<CustomerModel>>(
              stream: widget.customerService.getCustomersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading customers: ${snapshot.error}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  );
                }

                final allCustomers = snapshot.data ?? [];
                final query = _filterCtrl.text.toLowerCase().trim();
                final filtered = allCustomers.where((c) {
                  if (query.isEmpty) return true;
                  return c.name.toLowerCase().contains(query) ||
                      c.phone.toLowerCase().contains(query) ||
                      (c.email?.toLowerCase().contains(query) ?? false);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_off_outlined,
                            size: 44, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 8),
                        Text(
                          query.isEmpty
                              ? 'No customers registered yet'
                              : 'No customer found for "$query"',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: widget.onRegisterNew,
                          child: const Text('+ Register this customer now'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final c = filtered[i];
                    final isSelected = widget.selectedId == c.id;

                    final initials = c.name.isNotEmpty
                        ? c.name
                            .split(' ')
                            .where((w) => w.isNotEmpty)
                            .map((w) => w[0])
                            .take(2)
                            .join()
                            .toUpperCase()
                        : 'C';

                    return InkWell(
                      onTap: () => widget.onSelect(c),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFEFF6FF)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF2563EB)
                                : const Color(0xFFE2E8F0),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Avatar circle
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  initials,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Name + Phone + Email
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.name,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    c.phone.isNotEmpty
                                        ? c.phone
                                        : (c.email ?? 'No contact'),
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Checkmark or Select icon
                            Icon(
                              isSelected
                                  ? Icons.check_circle_rounded
                                  : Icons.chevron_right_rounded,
                              color: isSelected
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF94A3B8),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
