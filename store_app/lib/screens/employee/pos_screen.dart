import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../providers/sales_provider.dart';
import '../../providers/store_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/sale_model.dart';
import '../../widgets/store_header_widget.dart';


class CustomerInfo {
  final String id;
  final String name;
  final String phone;
  final String tier;
  final int points;

  const CustomerInfo({
    required this.id,
    required this.name,
    required this.phone,
    required this.tier,
    required this.points,
  });
}

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();

  String _selectedCategory = 'All';
  bool _loyaltyRedeemed = true;
  PaymentMode _selectedTender = PaymentMode.upi;
  bool _cartInitialized = false;

  final List<String> _categories = [
    'All',
    'Beverages',
    'Packaged Foods',
    'Personal Care',
    'Dairy & Fresh',
    'Snacks',
  ];

  static const List<CustomerInfo> _defaultCustomers = [
    CustomerInfo(
      id: 'cust_01',
      name: 'Rahul Sharma',
      phone: '+91 98451 22394',
      tier: 'Gold Tier',
      points: 480,
    ),
    CustomerInfo(
      id: 'cust_02',
      name: 'Priya Patel',
      phone: '+91 98200 11223',
      tier: 'Silver Tier',
      points: 220,
    ),
    CustomerInfo(
      id: 'cust_03',
      name: 'Amit Verma',
      phone: '+91 99100 44556',
      tier: 'Platinum Tier',
      points: 850,
    ),
    CustomerInfo(
      id: 'cust_04',
      name: 'Ananya Deshmukh',
      phone: '+91 97654 32109',
      tier: 'Gold Tier',
      points: 520,
    ),
    CustomerInfo(
      id: 'cust_05',
      name: 'Vikram Malhotra',
      phone: '+91 98111 22334',
      tier: 'Bronze Tier',
      points: 90,
    ),
    CustomerInfo(
      id: 'cust_06',
      name: 'Sneha Kulkarni',
      phone: '+91 98333 44556',
      tier: 'Silver Tier',
      points: 310,
    ),
  ];

  final List<CustomerInfo> _customCustomers = [];

  CustomerInfo? _selectedCustomer;

  List<CustomerInfo> get _allCustomers =>
      [..._customCustomers, ..._defaultCustomers];

  // Curated showcase products matching the inspiration design
  final List<Map<String, dynamic>> _referenceProducts = [
    {
      'id': 'prod_almond_milk',
      'name': 'Organic Almond Milk 1L',
      'category': 'Beverages',
      'sku': 'SKU: ALM-0924',
      'price': 240.0,
      'stock': 18,
      'isLow': false,
      'image': 'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=500',
    },
    {
      'id': 'prod_basmati_rice',
      'name': 'Basmati Royal Rice 5kg',
      'category': 'Packaged Foods',
      'sku': 'SKU: RCE-4410',
      'price': 550.0,
      'stock': 6,
      'isLow': true,
      'image': 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=500',
    },
    {
      'id': 'prod_olive_oil',
      'name': 'Cold Pressed Olive Oil 500ml',
      'category': 'Packaged Foods',
      'sku': 'SKU: OIL-8B21',
      'price': 420.0,
      'stock': 14,
      'isLow': false,
      'image': 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=500',
    },
    {
      'id': 'prod_coffee_beans',
      'name': 'Dark Roast Coffee Beans 250g',
      'category': 'Beverages',
      'sku': 'SKU: COF-3309',
      'price': 310.0,
      'stock': 9,
      'isLow': false,
      'image': 'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?w=500',
    },
    {
      'id': 'prod_mango_pulp',
      'name': 'Alfonso Mango Pulp 850g',
      'category': 'Packaged Foods',
      'sku': 'SKU: AMP-102',
      'price': 180.0,
      'stock': 4,
      'isLow': true,
      'image': 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=500',
    },
    {
      'id': 'prod_green_tea',
      'name': 'Organic Green Tea 100 ct',
      'category': 'Beverages',
      'sku': 'SKU: OGT-884',
      'price': 220.0,
      'stock': 34,
      'isLow': false,
      'image': 'https://images.unsplash.com/photo-1564890369478-c89ca6d9cde9?w=500',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Default to Rahul Sharma matching reference screenshot
    _selectedCustomer = _defaultCustomers[0];
    _phoneCtrl.text = _selectedCustomer!.phone;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initDemoCartIfNeeded();
    });
  }

  void _initDemoCartIfNeeded() {
    final sales = context.read<SalesProvider>();
    if (sales.cartIsEmpty && !_cartInitialized) {
      _cartInitialized = true;
      // Pre-seed matching items from screenshot
      sales.addToCart(CartItem(
        productId: 'prod_almond_milk',
        productName: 'Organic Almond Milk 1L',
        category: 'Beverages',
        unitPrice: 240.0,
        quantity: 2,
        availableStock: 18,
      ));
      sales.addToCart(CartItem(
        productId: 'prod_basmati_rice',
        productName: 'Basmati Royal Rice 5kg',
        category: 'Packaged Foods',
        unitPrice: 550.0,
        quantity: 1,
        availableStock: 6,
      ));
      sales.addToCart(CartItem(
        productId: 'prod_olive_oil',
        productName: 'Cold Pressed Olive Oil 500ml',
        category: 'Packaged Foods',
        unitPrice: 420.0,
        quantity: 1,
        availableStock: 14,
      ));
      if (_selectedCustomer != null) {
        sales.setCustomer(
          name: _selectedCustomer!.name,
          phone: _selectedCustomer!.phone,
          availablePoints: _selectedCustomer!.points,
        );
        sales.redeemPoints(_loyaltyRedeemed ? 100.0 : 0.0);
      }
    }
  }

  void _selectCustomer(CustomerInfo customer) {
    setState(() {
      _selectedCustomer = customer;
      _phoneCtrl.text = customer.phone;
      _loyaltyRedeemed = customer.points >= 100;
    });

    final sales = context.read<SalesProvider>();
    sales.setCustomer(
      name: customer.name,
      phone: customer.phone,
      availablePoints: customer.points,
    );
    sales.redeemPoints(_loyaltyRedeemed ? 100.0 : 0.0);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Attached customer: ${customer.name} (${customer.tier})'),
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

  // ─────────────────────────────────────────────────────────────────────────
  // 1. Customer Loyalty Bar with Find Out from Customers
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCustomerLoyaltySection() {
    final phoneText = _phoneCtrl.text.trim();
    // Check if there are live autocomplete suggestions
    List<CustomerInfo> quickSuggestions = [];
    if (phoneText.isNotEmpty &&
        (_selectedCustomer == null || _selectedCustomer!.phone != phoneText)) {
      final q = phoneText.toLowerCase();
      quickSuggestions = _allCustomers.where((c) {
        return c.phone.toLowerCase().contains(q) ||
            c.name.toLowerCase().contains(q);
      }).take(3).toList();
    }

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

          // Live quick autocomplete matches if typing
          if (quickSuggestions.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(10, 6, 10, 2),
                    child: Text(
                      'Matching Customers (Tap to select):',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                  ),
                  ...quickSuggestions.map((c) => InkWell(
                        onTap: () => _selectCustomer(c),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person_rounded,
                                      size: 14, color: Color(0xFF2563EB)),
                                  const SizedBox(width: 6),
                                  Text(
                                    c.name,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    c.phone,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 10.5,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${c.tier} • ${c.points} pts',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                ],
              ),
            ),
          ],

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
                  // Verified shield icon
                  const Icon(
                    Icons.verified_user_rounded,
                    color: Color(0xFF2563EB),
                    size: 19,
                  ),
                  const SizedBox(width: 8),

                  // Name & Tier
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
                            // Switch customer button
                            InkWell(
                              onTap: () => _showCustomerFinderSheet(context),
                              child: const Icon(Icons.swap_horiz_rounded,
                                  size: 15, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                        Text(
                          '${_selectedCustomer!.tier} • ${_selectedCustomer!.points} pts',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Redeem Points Button (Dark Green Pill)
                  if (_selectedCustomer!.points > 0)
                    InkWell(
                      onTap: () {
                        setState(() {
                          _loyaltyRedeemed = !_loyaltyRedeemed;
                          final sales = context.read<SalesProvider>();
                          final redeemAmount = _selectedCustomer!.points >= 100
                              ? 100.0
                              : _selectedCustomer!.points.toDouble();
                          sales.redeemPoints(
                              _loyaltyRedeemed ? redeemAmount : 0.0);
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _loyaltyRedeemed
                              ? const Color(0xFF065F46) // Forest green
                              : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: _loyaltyRedeemed
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF065F46)
                                        .withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _loyaltyRedeemed
                                  ? Icons.stars_rounded
                                  : Icons.stars_outlined,
                              color: _loyaltyRedeemed
                                  ? Colors.white
                                  : const Color(0xFF475569),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _loyaltyRedeemed
                                  ? 'Redeem 100 pts (-₹100)'
                                  : 'Apply Loyalty (-₹100)',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: _loyaltyRedeemed
                                    ? Colors.white
                                    : const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(width: 6),
                  // Clear button
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
  // Customer Finder Modal (Find Out From Customers)
  // ─────────────────────────────────────────────────────────────────────────
  void _showCustomerFinderSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CustomerFinderModal(
        customers: _allCustomers,
        selectedId: _selectedCustomer?.id,
        onSelect: (customer) {
          Navigator.pop(ctx);
          _selectCustomer(customer);
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
  // 3. Category Filter Chips
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCategoryFilterRow() {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = _categories[i];
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
  // 4. Product Catalog Grid (2 Columns)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildProductGrid() {
    final q = _searchCtrl.text.toLowerCase().trim();
    final items = _referenceProducts.where((p) {
      final matchesCat =
          _selectedCategory == 'All' || p['category'] == _selectedCategory;
      final matchesQuery = q.isEmpty ||
          p['name'].toString().toLowerCase().contains(q) ||
          p['sku'].toString().toLowerCase().contains(q);
      return matchesCat && matchesQuery;
    }).toList();

    if (items.isEmpty) {
      return Container(
        height: 160,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Text(
            'No matching products found',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
        ),
      );
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
        itemCount: items.length,
        itemBuilder: (context, i) {
          final p = items[i];
          return _buildProductCard(p);
        },
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> p) {
    final bool isLow = p['isLow'] as bool;
    final int stock = p['stock'] as int;
    final String name = p['name'] as String;
    final String sku = p['sku'] as String;
    final double price = p['price'] as double;
    final String image = p['image'] as String;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
          // Image with Stock Badge Overlay
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(13)),
                child: SizedBox(
                  height: 96,
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: image,
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
                  ),
                ),
              ),

              // Stock status badge in top-left
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isLow
                        ? const Color(0xFFFEE2E2) // Soft red
                        : const Color(0xFFDCFCE7), // Soft emerald
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isLow
                          ? const Color(0xFFFCA5A5)
                          : const Color(0xFF86EFAC),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLow) ...[
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Color(0xFFDC2626),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '$stock Left (Low)',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF991B1B),
                          ),
                        ),
                      ] else ...[
                        Text(
                          '$stock In Stock',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF166534),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Product Details
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
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
                  sku,
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
                      '₹${price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),

                    // Vibrant Blue "+" button
                    InkWell(
                      onTap: () => _addToCart(p),
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
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
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

  void _addToCart(Map<String, dynamic> p) {
    final sales = context.read<SalesProvider>();
    sales.addToCart(CartItem(
      productId: p['id'],
      productName: p['name'],
      category: p['category'],
      unitPrice: p['price'],
      quantity: 1,
      availableStock: p['stock'],
    ));

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${p['name']}" to active cart'),
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
    final loyaltyDiscount = _loyaltyRedeemed
        ? (_selectedCustomer != null && _selectedCustomer!.points >= 100
            ? 100.0
            : (_selectedCustomer?.points.toDouble() ?? 0.0))
        : 0.0;
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
              'Align barcode or enter SKU code manually:',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
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
              _addToCart(_referenceProducts[0]);
            },
            child: const Text('Scan Sample SKU'),
          ),
        ],
      ),
    );
  }

  void _showRegisterCustomerDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Register New Customer',
            style: TextStyle(fontFamily: 'Poppins')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
                final newCust = CustomerInfo(
                  id: 'cust_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  tier: 'Silver Tier',
                  points: 100,
                );

                setState(() {
                  _customCustomers.add(newCust);
                });
                _selectCustomer(newCust);

                Navigator.pop(ctx);
              }
            },
            child: const Text('Register & Attach'),
          ),
        ],
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
      // completeSale catches internally and sets _error; we proceed to dialog
    }

    if (!mounted) return;
    // Pop only the dialog using its own context — avoids GoRouter interference.
    // Guard with loadingCtx!.mounted (the dialog context's own mounted flag)
    // to satisfy use_build_context_synchronously across the async gap.
    if (loadingCtx != null && loadingCtx!.mounted && Navigator.of(loadingCtx!).canPop()) {
      Navigator.of(loadingCtx!).pop();
    }


    final invoiceNo = completedSale?.invoiceNumber ??
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
// Customer Finder Bottom Sheet Modal
// ─────────────────────────────────────────────────────────────────────────────
class _CustomerFinderModal extends StatefulWidget {
  final List<CustomerInfo> customers;
  final String? selectedId;
  final ValueChanged<CustomerInfo> onSelect;
  final VoidCallback onRegisterNew;

  const _CustomerFinderModal({
    required this.customers,
    this.selectedId,
    required this.onSelect,
    required this.onRegisterNew,
  });

  @override
  State<_CustomerFinderModal> createState() => _CustomerFinderModalState();
}

class _CustomerFinderModalState extends State<_CustomerFinderModal> {
  final TextEditingController _filterCtrl = TextEditingController();

  @override
  void dispose() {
    _filterCtrl.dispose();
    super.dispose();
  }

  Color _getTierBg(String tier) {
    if (tier.contains('Platinum')) return const Color(0xFFF3E8FF);
    if (tier.contains('Gold')) return const Color(0xFFFEF3C7);
    if (tier.contains('Silver')) return const Color(0xFFF1F5F9);
    return const Color(0xFFFFF7ED);
  }

  Color _getTierText(String tier) {
    if (tier.contains('Platinum')) return const Color(0xFF6B21A8);
    if (tier.contains('Gold')) return const Color(0xFF92400E);
    if (tier.contains('Silver')) return const Color(0xFF475569);
    return const Color(0xFF9A3412);
  }

  @override
  Widget build(BuildContext context) {
    final query = _filterCtrl.text.toLowerCase().trim();
    final filtered = widget.customers.where((c) {
      if (query.isEmpty) return true;
      return c.name.toLowerCase().contains(query) ||
          c.phone.toLowerCase().contains(query) ||
          c.tier.toLowerCase().contains(query);
    }).toList();

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
                      hintText: 'Search by customer name, phone, or tier...',
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

          // List of customers
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_off_outlined,
                            size: 44, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 8),
                        const Text(
                          'No customer found',
                          style: TextStyle(
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
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final c = filtered[i];
                      final isSelected = widget.selectedId == c.id;

                      final initials = c.name.isNotEmpty
                          ? c.name
                              .split(' ')
                              .map((w) => w.isNotEmpty ? w[0] : '')
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

                              // Name + Phone
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
                                      c.phone,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 11,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Tier & points
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getTierBg(c.tier),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      c.tier,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: _getTierText(c.tier),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${c.points} pts',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(width: 8),

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
                  ),
          ),
        ],
      ),
    );
  }
}
