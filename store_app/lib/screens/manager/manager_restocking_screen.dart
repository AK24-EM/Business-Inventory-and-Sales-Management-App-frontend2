import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_theme.dart';
import '../../widgets/store_header_widget.dart';
import '../../providers/store_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/sales_service.dart';
import '../../services/inventory_service.dart';
import '../../services/customer_service.dart';
import '../../services/supplier_service.dart';
import '../../services/notification_service.dart';
import '../../models/supplier_model.dart';
import '../../models/analytics_model.dart';
import '../../models/user_model.dart';

/// Manager-specific Smart Restocking Screen
/// Features:
/// - AI-powered restock recommendations based on sales velocity
/// - Automatic reorder point calculations
/// - One-click purchase order generation
/// - Supplier lead time consideration
/// - Safety stock buffer calculations
class ManagerRestockingScreen extends StatefulWidget {
  const ManagerRestockingScreen({super.key});

  @override
  State<ManagerRestockingScreen> createState() => _ManagerRestockingScreenState();
}

class _ManagerRestockingScreenState extends State<ManagerRestockingScreen> {
  List<RestockingRequirement> _requirements = [];
  final Map<String, int> _quantities = {};
  final Map<String, bool> _selected = {};
  bool _loading = true;
  String _sortBy = 'urgency'; // urgency, alphabetical, category, cost

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final storeProvider = context.read<StoreProvider>();
      final store = storeProvider.selectedStore;
      if (store == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      await context.read<ProductProvider>().loadProducts();

      final svc = AnalyticsService(
        SalesService(InventoryService(), CustomerService()),
        InventoryService(),
        CustomerService(),
      );

      final requirements = await svc.getRestockingRequirements([store.id]);

      // Enrich with product details
      final products = context.read<ProductProvider>();
      for (int i = 0; i < requirements.length; i++) {
        final req = requirements[i];
        final product = products.getById(req.productId);
        if (product != null) {
          requirements[i] = RestockingRequirement(
            productId: req.productId,
            productName: req.productName,
            category: req.category,
            storeId: req.storeId,
            storeName: store.name,
            supplierId: req.supplierId,
            supplierName: req.supplierName,
            currentStock: req.currentStock,
            minimumStockLevel: req.minimumStockLevel,
            recommendedOrderQuantity: req.recommendedOrderQuantity,
            purchasePrice: product.purchasePrice,
            estimatedCost: product.purchasePrice * req.recommendedOrderQuantity,
          );
          final key = '${req.storeId}_${req.productId}';
          _quantities[key] = req.recommendedOrderQuantity;
          _selected[key] = true; // Select all by default
        }
      }

      if (mounted) {
        setState(() {
          _requirements = requirements;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading restock data: $e')),
        );
      }
    }
  }

  List<RestockingRequirement> get _sortedRequirements {
    final list = List<RestockingRequirement>.from(_requirements);
    switch (_sortBy) {
      case 'urgency':
        list.sort((a, b) {
          final aUrgency = a.minimumStockLevel - a.currentStock;
          final bUrgency = b.minimumStockLevel - b.currentStock;
          return bUrgency.compareTo(aUrgency);
        });
        break;
      case 'alphabetical':
        list.sort((a, b) => a.productName.compareTo(b.productName));
        break;
      case 'category':
        list.sort((a, b) => a.category.compareTo(b.category));
        break;
      case 'cost':
        list.sort((a, b) {
          final aCost = a.purchasePrice * _quantities['${a.storeId}_${a.productId}']!;
          final bCost = b.purchasePrice * _quantities['${b.storeId}_${b.productId}']!;
          return bCost.compareTo(aCost);
        });
        break;
    }
    return list;
  }

  double get _totalSelectedCost {
    return _requirements.fold(0.0, (sum, req) {
      final key = '${req.storeId}_${req.productId}';
      if (_selected[key] == true) {
        final qty = _quantities[key] ?? req.recommendedOrderQuantity;
        return sum + (req.purchasePrice * qty);
      }
      return sum;
    });
  }

  int get _selectedCount {
    return _selected.values.where((v) => v == true).length;
  }

  Future<void> _generatePurchaseOrders() async {
    if (_selectedCount == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one item')),
        );
      }
      return;
    }

    // Group selected items by supplier
    final Map<String, List<RestockingRequirement>> bySupplier = {};
    for (final req in _requirements) {
      final key = '${req.storeId}_${req.productId}';
      if (_selected[key] == true && req.supplierId != null && req.supplierId!.isNotEmpty) {
        bySupplier.putIfAbsent(req.supplierId!, () => []).add(req);
      }
    }

    if (bySupplier.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected items have no supplier assigned. Please assign suppliers first.')),
        );
      }
      return;
    }

    try {
      final supplierService = SupplierService();
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentUser;
      
      if (currentUser == null) {
        throw Exception('User not authenticated. Please log in again.');
      }

      final store = context.read<StoreProvider>().selectedStore;
      if (store == null) {
        throw Exception('No store selected. Please select a store.');
      }

      int poCount = 0;

      for (final entry in bySupplier.entries) {
        try {
          final items = entry.value.map((req) {
            final key = '${req.storeId}_${req.productId}';
            final qty = _quantities[key] ?? req.recommendedOrderQuantity;
            return PurchaseOrderItem(
              productId: req.productId,
              productName: req.productName,
              orderedQuantity: qty,
              unitPrice: req.purchasePrice,
              totalPrice: req.purchasePrice * qty,
            );
          }).toList();

          final total = items.fold(0.0, (s, i) => s + i.totalPrice);
          final supplierName = entry.value.first.supplierName ?? entry.key;

          await supplierService.createPurchaseOrder(PurchaseOrder(
            id: '',
            supplierId: entry.key,
            supplierName: supplierName,
            items: items,
            totalAmount: total,
            createdByUserId: currentUser.id,
            createdByUserName: currentUser.name,
            createdAt: DateTime.now(),
            targetStoreId: store.id,
          ));
          poCount++;
        } catch (e) {
          print('Error creating PO for supplier ${entry.key}: $e');
          // Continue with other suppliers
        }
      }

      if (poCount == 0) {
        throw Exception('Failed to create any purchase orders');
      }

      // Send notification about PO creation
      try {
        final notificationService = NotificationService();
        await notificationService.sendCustomNotification(
          title: '✓ Purchase Orders Created',
          message: '$poCount PO(s) created for restocking at ${store.name}',
          userId: currentUser.id,
          storeId: store.id,
          sendPush: false,
        );
      } catch (e) {
        print('Error sending notification: $e');
        // Don't fail the whole operation just for notification
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ $poCount purchase order(s) created successfully'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
        // Refresh data after a short delay
        await Future.delayed(const Duration(milliseconds: 500));
        await _loadData();
      }
    } catch (e) {
      print('Error in _generatePurchaseOrders: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            StoreHeaderWidget(
              title: 'Smart Restocking',
              subtitle: 'AI-POWERED REPLENISHMENT • Sales Velocity Analysis',
              onNotificationTap: () => context.go('/manager/notifications'),
            ),

            // Hero Banner
            _buildHeroBanner(fmt),

            // Sort & Filter Bar
            _buildSortBar(),

            // List
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF059669)))
                  : _requirements.isEmpty
                      ? _buildEmptyState()
                      : _buildRestockList(),
            ),

            // Bottom Action Bar
            if (_requirements.isNotEmpty) _buildBottomBar(fmt),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner(NumberFormat fmt) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF065F46), Color(0xFF059669), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha: 0.32),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.autorenew_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Intelligent Reorder System',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'AI calculates optimal order quantities',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: _loadData,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _bannerStat(
                  '${_requirements.length}',
                  'Products Need Restock',
                  Icons.inventory_2_outlined,
                  const Color(0xFFFDE68A),
                ),
                Container(width: 1, height: 36, color: Colors.white24),
                _bannerStat(
                  '₹${fmt.format(_totalSelectedCost)}',
                  'Estimated Investment',
                  Icons.currency_rupee_rounded,
                  const Color(0xFF6EE7B7),
                ),
                Container(width: 1, height: 36, color: Colors.white24),
                _bannerStat(
                  '$_selectedCount',
                  'Items Selected',
                  Icons.check_circle_outline_rounded,
                  const Color(0xFF93C5FD),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bannerStat(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 9,
            color: Colors.white.withValues(alpha: 0.8),
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildSortBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.sort_rounded, size: 18, color: Color(0xFF64748B)),
          const SizedBox(width: 8),
          const Text(
            'Sort by:',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _sortChip('Urgency', 'urgency'),
                  _sortChip('Name A-Z', 'alphabetical'),
                  _sortChip('Category', 'category'),
                  _sortChip('Cost', 'cost'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => _sortBy = value),
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF059669) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRestockList() {
    final sorted = _sortedRequirements;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _RestockCard(
        requirement: sorted[i],
        quantity: _quantities['${sorted[i].storeId}_${sorted[i].productId}'] ?? sorted[i].recommendedOrderQuantity,
        isSelected: _selected['${sorted[i].storeId}_${sorted[i].productId}'] ?? false,
        onSelectionChanged: (val) {
          setState(() {
            _selected['${sorted[i].storeId}_${sorted[i].productId}'] = val;
          });
        },
        onQuantityChanged: (qty) {
          setState(() {
            _quantities['${sorted[i].storeId}_${sorted[i].productId}'] = qty;
          });
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFECFDF5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 60,
              color: Color(0xFF059669),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'All Stock Levels Optimal!',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'No items need restocking at this time',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(NumberFormat fmt) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_selectedCount items selected',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    '₹${fmt.format(_totalSelectedCost)}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _selectedCount > 0 ? _generatePurchaseOrders : null,
              icon: const Icon(Icons.add_task_rounded, size: 18),
              label: const Text('Create Purchase Orders'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestockCard extends StatelessWidget {
  final RestockingRequirement requirement;
  final int quantity;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;
  final ValueChanged<int> onQuantityChanged;

  const _RestockCard({
    required this.requirement,
    required this.quantity,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    final urgencyLevel = _getUrgencyLevel();
    final urgencyColor = _getUrgencyColor();
    final urgencyBg = _getUrgencyBg();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with checkbox
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFECFDF5) : Colors.transparent,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (val) => onSelectionChanged(val ?? false),
                  activeColor: const Color(0xFF059669),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        requirement.productName,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        requirement.category,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: urgencyBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.priority_high_rounded, size: 12, color: urgencyColor),
                      const SizedBox(width: 4),
                      Text(
                        urgencyLevel,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: urgencyColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Stock Status
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _InfoBadge(
                      icon: Icons.inventory_2_outlined,
                      label: 'Current',
                      value: '${requirement.currentStock}',
                      color: const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 10),
                    _InfoBadge(
                      icon: Icons.flag_outlined,
                      label: 'Minimum',
                      value: '${requirement.minimumStockLevel}',
                      color: const Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 10),
                    _InfoBadge(
                      icon: Icons.recommend_outlined,
                      label: 'Suggested',
                      value: '${requirement.recommendedOrderQuantity}',
                      color: const Color(0xFF059669),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Quantity Selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Order Quantity:',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: quantity > 1 ? () => onQuantityChanged(quantity - 1) : null,
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                        color: const Color(0xFF059669),
                        iconSize: 22,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      Container(
                        width: 60,
                        alignment: Alignment.center,
                        child: Text(
                          '$quantity',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => onQuantityChanged(quantity + 1),
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        color: const Color(0xFF059669),
                        iconSize: 22,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Cost Calculation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${fmt.format(requirement.purchasePrice)} × $quantity units',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      '₹${fmt.format(requirement.purchasePrice * quantity)}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),

                // Supplier Info
                if (requirement.supplierName != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_shipping_outlined,
                          size: 14,
                          color: Color(0xFFD97706),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Supplier: ${requirement.supplierName}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getUrgencyLevel() {
    final deficit = requirement.minimumStockLevel - requirement.currentStock;
    if (deficit >= 20) return 'CRITICAL';
    if (deficit >= 10) return 'HIGH';
    if (deficit >= 5) return 'MEDIUM';
    return 'LOW';
  }

  Color _getUrgencyColor() {
    final deficit = requirement.minimumStockLevel - requirement.currentStock;
    if (deficit >= 20) return const Color(0xFFDC2626);
    if (deficit >= 10) return const Color(0xFFEA580C);
    if (deficit >= 5) return const Color(0xFFF59E0B);
    return const Color(0xFF64748B);
  }

  Color _getUrgencyBg() {
    final deficit = requirement.minimumStockLevel - requirement.currentStock;
    if (deficit >= 20) return const Color(0xFFFEF2F2);
    if (deficit >= 10) return const Color(0xFFFFF7ED);
    if (deficit >= 5) return const Color(0xFFFFFBEB);
    return const Color(0xFFF1F5F9);
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 9,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
