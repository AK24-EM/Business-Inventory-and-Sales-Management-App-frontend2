import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_constants.dart';
import '../../widgets/store_header_widget.dart';
import '../../providers/store_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../models/inventory_model.dart';
import '../../models/restock_model.dart';
import '../../models/supplier_model.dart';
import '../../models/analytics_model.dart';
import '../../services/sales_service.dart';
import '../../services/inventory_service.dart';
import '../../services/customer_service.dart';
import '../../services/supplier_service.dart';
import '../../services/notification_service.dart';

/// Manager-specific Smart Restocking Screen with Real-Time Firestore Sync
/// Features:j
/// - Real-time stream updates whenever stock changes
/// - Instant 1-click restock with visual feedback
/// - Live stream of recent restock activity movements
/// - Multi-view: Urgent Needs Restock vs All Products vs Live Feed
/// - AI-powered restock recommendations based on sales velocity
/// - One-click purchase order generation
class ManagerRestockingScreen extends StatefulWidget {
  const ManagerRestockingScreen({super.key});

  @override
  State<ManagerRestockingScreen> createState() => _ManagerRestockingScreenState();
}

class _ManagerRestockingScreenState extends State<ManagerRestockingScreen>
    with SingleTickerProviderStateMixin {
  // Real-time stream subscriptions
  StreamSubscription<List<InventoryModel>>? _inventorySubscription;
  String? _subscribedStoreId;
  Timer? _loadingTimeoutTimer; // Safety timeout so spinner never freezes
  int _initRetries = 0;

  // Data state
  List<RestockingRequirement> _allRequirements = [];
  Map<String, int> _monthlySales = {};
  final Map<String, int> _quantities = {};
  final Map<String, bool> _selected = {};
  final Set<String> _restockingItemKeys = {};

  bool _loading = true;
  String _activeTab = 'needs_restock'; // 'needs_restock' | 'all_products' | 'activity'
  String _sortBy = 'urgency'; // 'urgency' | 'alphabetical' | 'category' | 'cost'
  String _searchQuery = '';
  String _selectedCategory = 'All';

  // Live pulse animation controller
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initRealtimeSync();
    });
  }

  @override
  void dispose() {
    _inventorySubscription?.cancel();
    _loadingTimeoutTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  List<InventoryModel>? _latestLiveInventory;

  void _initRealtimeSync() {
    if (!mounted) return;

    final storeProvider = context.read<StoreProvider>();
    final store = storeProvider.selectedStore;

    // If StoreProvider is still loading, retry briefly (up to 10 times)
    if (store == null) {
      if (storeProvider.isLoading && _initRetries < 10) {
        _initRetries++;
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _initRealtimeSync();
        });
        return;
      }
      // Store is null and not loading — give up, show empty state
      if (mounted) setState(() => _loading = false);
      return;
    }

    if (_subscribedStoreId == store.id && _inventorySubscription != null) {
      return; // Already listening to this store
    }

    _subscribedStoreId = store.id;

    final productProvider = context.read<ProductProvider>();
    final supplierProvider = context.read<SupplierProvider>();
    final inventoryProvider = context.read<InventoryProvider>();

    // --- SAFETY TIMEOUT: If stream hasn't fired in 2.5s, unlock UI ---
    _loadingTimeoutTimer?.cancel();
    _loadingTimeoutTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted && _loading) {
        debugPrint('Restock: stream timeout — unlocking UI with empty state');
        setState(() => _loading = false);
      }
    });

    // 1. If we already have cached inventory in provider, render instantly
    if (inventoryProvider.inventory.isNotEmpty) {
      _latestLiveInventory = inventoryProvider.inventory
          .where((i) => i.storeId == store.id)
          .toList();
      if (_latestLiveInventory!.isNotEmpty) {
        _processLiveInventory(_latestLiveInventory!);
      }
    }

    // 2. Subscribe to real-time inventory stream
    _inventorySubscription?.cancel();
    _inventorySubscription = inventoryProvider.watchInventory(store.id).listen(
      (liveInventory) {
        _loadingTimeoutTimer?.cancel(); // Stream fired — no need for timeout
        _latestLiveInventory = liveInventory;
        _processLiveInventory(liveInventory);
      },
      onError: (err) {
        debugPrint('Inventory stream error: $err');
        if (mounted) setState(() => _loading = false);
      },
    );

    // 3. Load products & suppliers in background if not already cached
    if (productProvider.products.isEmpty) {
      productProvider.loadProducts().then((_) {
        if (mounted && _latestLiveInventory != null) {
          _processLiveInventory(_latestLiveInventory!);
        }
      }).catchError((e) => debugPrint('Background product load: $e'));
    }

    if (supplierProvider.suppliers.isEmpty) {
      supplierProvider.loadSuppliers().then((_) {
        if (mounted && _latestLiveInventory != null) {
          _processLiveInventory(_latestLiveInventory!);
        }
      }).catchError((e) => debugPrint('Background supplier load: $e'));
    }

    // 4. Fetch sales velocity in background — does NOT block UI render
    _loadSalesVelocityInBackground(store.id);
  }

  void _loadSalesVelocityInBackground(String storeId) async {
    try {
      final salesService = SalesService(InventoryService(), CustomerService());
      // Use Firestore-level date filter with a limit to avoid full collection scans
      final sales = await salesService.getSalesByStoreRecent(storeId, limitDays: 30);

      final Map<String, int> soldMap = {};
      for (final sale in sales) {
        for (final item in sale.items) {
          soldMap[item.productId] = (soldMap[item.productId] ?? 0) + item.quantity;
        }
      }
      if (mounted) {
        _monthlySales = soldMap;
        if (_latestLiveInventory != null) {
          _processLiveInventory(_latestLiveInventory!);
        }
      }
    } catch (e) {
      debugPrint('Background sales query error (non-blocking): $e');
      // Non-fatal: restock screen still works without sales velocity data
    }
  }

  void _processLiveInventory(List<InventoryModel> liveInventory) {
    if (!mounted) return;

    final store = context.read<StoreProvider>().selectedStore;
    if (store == null) return;

    final productProvider = context.read<ProductProvider>();
    final allProducts = productProvider.products;
    final suppliers = context.read<SupplierProvider>().suppliers;
    final supplierMap = {for (final s in suppliers) s.id: s.name};

    final List<RestockingRequirement> reqList = [];

    // If products are already in memory, enrich them;
    // Otherwise render directly from liveInventory so UI appears in < 150ms!
    if (allProducts.isNotEmpty) {
      final invMap = {for (var inv in liveInventory) inv.productId: inv};

      for (final product in allProducts) {
        final inv = invMap[product.id];
        final currentStock = inv?.currentStock ?? 0;
        final minStock = inv?.minimumStockLevel ?? AppConstants.defaultMinStockLevel;
        final monthly = _monthlySales[product.id] ?? 0;

        int recommended = 20;
        if (currentStock <= 0) {
          recommended = minStock * 2;
        } else if (currentStock <= minStock) {
          final deficit = minStock - currentStock;
          recommended = monthly > 0
              ? (monthly * AppConstants.defaultRestockMultiplier).toInt()
              : (deficit + minStock);
        } else {
          recommended = 20;
        }
        if (recommended < 10) recommended = 10;

        String? resolvedSupplierId = product.supplierId;
        if (resolvedSupplierId == null || resolvedSupplierId.isEmpty) {
          for (final s in suppliers) {
            if (s.productIds.contains(product.id)) {
              resolvedSupplierId = s.id;
              break;
            }
          }
          resolvedSupplierId ??=
              suppliers.isNotEmpty ? suppliers.first.id : null;
        }
        final resolvedSupplierName = resolvedSupplierId != null
            ? (supplierMap[resolvedSupplierId] ?? 'Unknown supplier')
            : 'No supplier assigned';

        final purchasePrice = product.purchasePrice > 0 ? product.purchasePrice : 45.0;

        final req = RestockingRequirement(
          productId: product.id,
          productName: product.name,
          category: product.category,
          storeId: store.id,
          storeName: store.name,
          supplierId: resolvedSupplierId,
          supplierName: resolvedSupplierName,
          currentStock: currentStock,
          minimumStockLevel: minStock,
          recommendedOrderQuantity: recommended,
          purchasePrice: purchasePrice,
          estimatedCost: purchasePrice * recommended,
        );

        final key = '${store.id}_${product.id}';
        if (!_quantities.containsKey(key)) {
          _quantities[key] = req.recommendedOrderQuantity;
        }
        if (!_selected.containsKey(key)) {
          _selected[key] = currentStock <= minStock;
        }

        reqList.add(req);
      }
    } else {
      // Immediate render path: build requirements directly from live inventory
      for (final inv in liveInventory) {
        final currentStock = inv.currentStock;
        final minStock = inv.minimumStockLevel > 0 ? inv.minimumStockLevel : AppConstants.defaultMinStockLevel;
        final monthly = _monthlySales[inv.productId] ?? 0;

        int recommended = currentStock <= 0
            ? minStock * 2
            : (monthly > 0
                ? (monthly * AppConstants.defaultRestockMultiplier).toInt()
                : (minStock * 2 - currentStock));
        if (recommended < 10) recommended = 10;

        String? resolvedSupplierId;
        for (final s in suppliers) {
          if (s.productIds.contains(inv.productId)) {
            resolvedSupplierId = s.id;
            break;
          }
        }
        resolvedSupplierId ??=
            suppliers.isNotEmpty ? suppliers.first.id : null;
        final resolvedSupplierName = resolvedSupplierId != null
            ? (supplierMap[resolvedSupplierId] ?? 'Unknown supplier')
            : 'No supplier assigned';

        final req = RestockingRequirement(
          productId: inv.productId,
          productName: inv.productName,
          category: inv.category,
          storeId: store.id,
          storeName: store.name,
          supplierId: resolvedSupplierId,
          supplierName: resolvedSupplierName,
          currentStock: currentStock,
          minimumStockLevel: minStock,
          recommendedOrderQuantity: recommended,
          purchasePrice: 45.0,
          estimatedCost: 45.0 * recommended,
        );

        final key = '${store.id}_${inv.productId}';
        if (!_quantities.containsKey(key)) {
          _quantities[key] = req.recommendedOrderQuantity;
        }
        if (!_selected.containsKey(key)) {
          _selected[key] = currentStock <= minStock;
        }

        reqList.add(req);
      }
    }

    setState(() {
      _allRequirements = reqList;
      _loading = false;
    });
  }

  // ── Filtered & Sorted Lists ────────────────────────────────────────────────
  List<RestockingRequirement> get _needsRestockList {
    return _allRequirements.where((r) => r.currentStock <= r.minimumStockLevel).toList();
  }

  List<RestockingRequirement> get _currentDisplayList {
    List<RestockingRequirement> list;
    if (_activeTab == 'needs_restock') {
      list = List.from(_needsRestockList);
    } else {
      list = List.from(_allRequirements);
    }

    // Category filter
    if (_selectedCategory != 'All') {
      list = list.where((r) => r.category == _selectedCategory).toList();
    }

    // Search filter
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      list = list.where((r) =>
          r.productName.toLowerCase().contains(q) ||
          r.category.toLowerCase().contains(q)).toList();
    }

    // Sort
    switch (_sortBy) {
      case 'urgency':
        list.sort((a, b) {
          // 1. Out of stock (0 units) always ranked first
          if (a.currentStock == 0 && b.currentStock > 0) return -1;
          if (b.currentStock == 0 && a.currentStock > 0) return 1;
          // 2. Highest deficit below minimum safety stock
          final aDeficit = a.minimumStockLevel - a.currentStock;
          final bDeficit = b.minimumStockLevel - b.currentStock;
          return bDeficit.compareTo(aDeficit);
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
          final aQty = _quantities['${a.storeId}_${a.productId}'] ?? a.recommendedOrderQuantity;
          final bQty = _quantities['${b.storeId}_${b.productId}'] ?? b.recommendedOrderQuantity;
          final aCost = a.purchasePrice * aQty;
          final bCost = b.purchasePrice * bQty;
          return bCost.compareTo(aCost);
        });
        break;
    }
    return list;
  }

  double get _totalSelectedCost {
    final list = _activeTab == 'needs_restock' ? _needsRestockList : _allRequirements;
    return list.fold(0.0, (sum, req) {
      final key = '${req.storeId}_${req.productId}';
      if (_selected[key] == true) {
        final qty = _quantities[key] ?? req.recommendedOrderQuantity;
        return sum + (req.purchasePrice * qty);
      }
      return sum;
    });
  }

  int get _selectedCount {
    final list = _activeTab == 'needs_restock' ? _needsRestockList : _allRequirements;
    return list.where((r) => _selected['${r.storeId}_${r.productId}'] == true).length;
  }

  // ── Actions ────────────────────────────────────────────────────────────────
  Future<void> _quickRestockItem(RestockingRequirement req, int qty) async {
    final itemKey = '${req.storeId}_${req.productId}';
    if (_restockingItemKeys.contains(itemKey)) return;

    setState(() => _restockingItemKeys.add(itemKey));

    try {
      final auth = context.read<AuthProvider>();
      final user = auth.currentUser;

      await context.read<InventoryProvider>().quickRestock(
            storeId: req.storeId,
            productId: req.productId,
            productName: req.productName,
            quantity: qty,
            userId: user?.id ?? 'manager',
            userName: user?.name ?? 'Store Manager',
            // Extra context written to the dedicated restocks collection
            storeName: req.storeName,
            category: req.category,
            supplierId: req.supplierId,
            supplierName: req.supplierName,
            unitCost: req.purchasePrice,
            notes: '⚡ Quick Restock from Manager Hub (+$qty units)',
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '✓ Restocked +$qty units of ${req.productName}! (Stock: ${req.currentStock + qty})',
                    style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF059669),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restock: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _restockingItemKeys.remove(itemKey));
      }
    }
  }
  Future<void> _generatePurchaseOrders() async {
    final targetList = _activeTab == 'needs_restock' ? _needsRestockList : _allRequirements;
    final selectedReqs = targetList
        .where((r) => _selected['${r.storeId}_${r.productId}'] == true)
        .toList();

    if (selectedReqs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one item to order'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Navigate to Purchase Order screen with selected items
    // Group selected items by supplier for better organization
    final supplierProvider = context.read<SupplierProvider>();
    final suppliers = supplierProvider.suppliers;

    // Collect all items with their quantities
    final List<Map<String, dynamic>> itemsData = selectedReqs.map((req) {
      final key = '${req.storeId}_${req.productId}';
      final qty = _quantities[key] ?? req.recommendedOrderQuantity;

      String? supplierId;
      String? supplierName;
      if (req.supplierId != null && req.supplierId!.isNotEmpty) {
        supplierId = req.supplierId;
        if (suppliers.isNotEmpty) {
          final supplier = suppliers.firstWhere(
            (s) => s.id == supplierId,
            orElse: () => suppliers.first,
          );
          supplierName = supplier.name;
        } else {
          supplierName = req.supplierName;
        }
      } else {
        for (final s in suppliers) {
          if (s.productIds.contains(req.productId)) {
            supplierId = s.id;
            supplierName = s.name;
            break;
          }
        }
        if (supplierId == null && suppliers.isNotEmpty) {
          supplierId = suppliers.first.id;
          supplierName = suppliers.first.name;
        }
      }

      return {
        'productId': req.productId,
        'productName': req.productName,
        'quantity': qty,
        'unitPrice': req.purchasePrice,
        'supplierId': supplierId,
        'supplierName': supplierName,
      };
    }).toList();

    // Navigate to Purchase Order screen with these items
    if (mounted) {
      context.push('/manager/purchase-orders', extra: {
        'prefilledItems': itemsData,
      });
    }
  }

  // ── Build UI ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    final store = context.watch<StoreProvider>().selectedStore;

    // Detect if store switched
    if (store != null && store.id != _subscribedStoreId) {
      _subscribedStoreId = store.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initRealtimeSync();
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Store Header
            StoreHeaderWidget(
              title: 'Smart Restocking',
              subtitle: 'AI REPLENISHMENT • Real-Time Firestore Sync',
              onNotificationTap: () => context.go('/manager/notifications'),
            ),

            // Hero Live Banner
            _buildHeroBanner(fmt),

            // Navigation Tabs (Needs Restock | All Products | Live Activity)
            _buildTabBar(),

            // Filters & Search Bar (only for list views)
            if (_activeTab != 'activity') _buildFilterBar(),

            // Content Area
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF059669)),
                    )
                  : _activeTab == 'activity'
                      ? _buildLiveActivityView(store?.id ?? '')
                      : _currentDisplayList.isEmpty
                          ? _buildEmptyState()
                          : _buildRestockList(),
            ),

            // Bottom Floating Bar for Purchase Orders
            if (_activeTab != 'activity' && _currentDisplayList.isNotEmpty)
              _buildBottomBar(fmt),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner(NumberFormat fmt) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF065F46), Color(0xFF059669), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Live Restock Hub',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Live Pulse Dot
                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF34D399),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle, color: Color(0xFF064E3B), size: 6),
                                SizedBox(width: 4),
                                Text(
                                  'LIVE SYNC',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF064E3B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'Changes reflect instantly across all cashiers and stores',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10.5,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _initRealtimeSync,
                tooltip: 'Re-sync Stream',
                icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  padding: const EdgeInsets.all(6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _bannerStat(
                  '${_needsRestockList.length}',
                  'Needs Restock',
                  Icons.warning_amber_rounded,
                  const Color(0xFFFDE68A),
                ),
                Container(width: 1, height: 30, color: Colors.white24),
                _bannerStat(
                  '${_allRequirements.length}',
                  'Total Products',
                  Icons.inventory_2_outlined,
                  const Color(0xFF93C5FD),
                ),
                Container(width: 1, height: 30, color: Colors.white24),
                _bannerStat(
                  '₹${fmt.format(_totalSelectedCost)}',
                  'Selected Cost',
                  Icons.currency_rupee_rounded,
                  const Color(0xFF6EE7B7),
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 9.5,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _tabButton('🚨 Needs Restock (${_needsRestockList.length})', 'needs_restock'),
          _tabButton('📦 All Products (${_allRequirements.length})', 'all_products'),
          _tabButton('⚡ Live Activity', 'activity'),
        ],
      ),
    );
  }

  Widget _tabButton(String label, String tabKey) {
    final isSelected = _activeTab == tabKey;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = tabKey),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    final categories = ['All', ...{for (var r in _allRequirements) r.category}];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Column(
        children: [
          // Search & Sort Row
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
                      prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Sort dropdown
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    icon: const Icon(Icons.swap_vert_rounded, size: 18, color: Color(0xFF059669)),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'urgency', child: Text('Urgency')),
                      DropdownMenuItem(value: 'alphabetical', child: Text('Name A-Z')),
                      DropdownMenuItem(value: 'category', child: Text('Category')),
                      DropdownMenuItem(value: 'cost', child: Text('Est. Cost')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _sortBy = val);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Category chips
          SizedBox(
            height: 28,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final cat = categories[i];
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(
                    cat,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: const Color(0xFF059669),
                  backgroundColor: Colors.white,
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                  onSelected: (val) {
                    if (val) setState(() => _selectedCategory = cat);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
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

  Widget _buildRestockList() {
    final list = _currentDisplayList;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final req = list[i];
        final key = '${req.storeId}_${req.productId}';
        final qty = _quantities[key] ?? req.recommendedOrderQuantity;
        final isSelected = _selected[key] ?? false;
        final isRestocking = _restockingItemKeys.contains(key);

        return _RestockCard(
          requirement: req,
          quantity: qty,
          isSelected: isSelected,
          isRestocking: isRestocking,
          onSelectionChanged: (val) {
            setState(() => _selected[key] = val);
          },
          onQuantityChanged: (newQty) {
            setState(() => _quantities[key] = newQty);
          },
          onQuickRestock: () => _quickRestockItem(req, qty),
        );
      },
    );
  }

  Widget _buildLiveActivityView(String storeId) {
    if (storeId.isEmpty) {
      return const Center(child: Text('No store selected'));
    }

    final inventoryProvider = context.read<InventoryProvider>();
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    final df = DateFormat('dd MMM yyyy • hh:mm a');

    return StreamBuilder<List<RestockModel>>(
      stream: inventoryProvider.watchRestocks(storeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF059669)),
                SizedBox(height: 12),
                Text('Loading restock history…',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          );
        }

        final restocks = snapshot.data ?? [];

        if (restocks.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF059669).withValues(alpha: 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.inventory_2_rounded, size: 48, color: Color(0xFF059669)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Restocks Yet',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'When you restock products using Quick Restock\nor generate Purchase Orders, they appear here.',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF94A3B8)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: restocks.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final r = restocks[i];
            final isQuick = r.source == 'quick_restock';
            final isPO = r.source == 'purchase_order';
            final sourceColor = isPO ? const Color(0xFF7C3AED) : const Color(0xFF059669);
            final sourceBg = isPO ? const Color(0xFFF3E8FF) : const Color(0xFFECFDF5);

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Source icon
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: sourceBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isPO ? Icons.receipt_long_rounded : Icons.bolt_rounded,
                          color: sourceColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Product name + meta
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.productName,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            if (r.category.isNotEmpty)
                              Text(
                                r.category,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Quantity badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: sourceColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '+${r.quantity} units',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Details row
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        // Stock flow
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.trending_up_rounded, size: 14, color: Color(0xFF059669)),
                              const SizedBox(width: 4),
                              Text(
                                'Stock: ${r.stockBefore} → ${r.stockAfter}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Cost (if known)
                        if (r.totalCost > 0)
                          Text(
                            '₹${fmt.format(r.totalCost)}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Bottom meta: source, supplier, who did it, when
                  Row(
                    children: [
                      // Source badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: sourceBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          r.sourceLabel,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: sourceColor,
                          ),
                        ),
                      ),
                      if (r.supplierName.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.local_shipping_outlined, size: 10, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 3),
                        Text(
                          r.supplierName,
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 9.5, color: Color(0xFF64748B)),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        '${r.performedByUserName} • ${df.format(r.timestamp)}',
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 9, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
                size: 56,
                color: Color(0xFF059669),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'All Inventory Levels are Healthy!',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'No items currently below minimum safety stock levels.\nYou can still pre-restock any catalog item.',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => setState(() => _activeTab = 'all_products'),
              icon: const Icon(Icons.inventory_2_outlined, size: 16),
              label: const Text('Browse All Products to Refill'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(NumberFormat fmt) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
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
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    '₹${fmt.format(_totalSelectedCost)}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _selectedCount > 0 ? _generatePurchaseOrders : null,
              icon: const Icon(Icons.add_task_rounded, size: 17),
              label: const Text('Create Purchase Orders'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.5,
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

// ── Item Restock Card ────────────────────────────────────────────────────────
class _RestockCard extends StatelessWidget {
  final RestockingRequirement requirement;
  final int quantity;
  final bool isSelected;
  final bool isRestocking;
  final ValueChanged<bool> onSelectionChanged;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onQuickRestock;

  const _RestockCard({
    required this.requirement,
    required this.quantity,
    required this.isSelected,
    required this.isRestocking,
    required this.onSelectionChanged,
    required this.onQuantityChanged,
    required this.onQuickRestock,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    final isOutOfStock = requirement.currentStock <= 0;
    final isLow = requirement.currentStock <= requirement.minimumStockLevel;

    final urgencyColor = isOutOfStock
        ? const Color(0xFFDC2626)
        : isLow
            ? const Color(0xFFD97706)
            : const Color(0xFF059669);

    final urgencyBg = isOutOfStock
        ? const Color(0xFFFEF2F2)
        : isLow
            ? const Color(0xFFFFFBEB)
            : const Color(0xFFECFDF5);

    final urgencyLabel = isOutOfStock
        ? 'OUT OF STOCK'
        : isLow
            ? 'LOW STOCK'
            : 'HEALTHY';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFECFDF5) : Colors.transparent,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (val) => onSelectionChanged(val ?? false),
                    activeColor: const Color(0xFF059669),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        requirement.productName,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        requirement.category,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: urgencyBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOutOfStock
                            ? Icons.error_outline_rounded
                            : isLow
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle_outline_rounded,
                        size: 11,
                        color: urgencyColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        urgencyLabel,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: urgencyColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Body
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Real-Time Stock Status Badges
                Row(
                  children: [
                    _InfoBadge(
                      icon: Icons.inventory_2_outlined,
                      label: 'Current Live',
                      value: '${requirement.currentStock}',
                      color: isOutOfStock
                          ? const Color(0xFFDC2626)
                          : isLow
                              ? const Color(0xFFD97706)
                              : const Color(0xFF059669),
                    ),
                    const SizedBox(width: 8),
                    _InfoBadge(
                      icon: Icons.flag_outlined,
                      label: 'Min Safety',
                      value: '${requirement.minimumStockLevel}',
                      color: const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    _InfoBadge(
                      icon: Icons.recommend_outlined,
                      label: 'Suggested',
                      value: '${requirement.recommendedOrderQuantity}',
                      color: const Color(0xFF2563EB),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Quick Increment Presets
                Row(
                  children: [
                    const Text(
                      'Quick Add:',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _presetChip('+10', () => onQuantityChanged(quantity + 10)),
                    _presetChip('+25', () => onQuantityChanged(quantity + 25)),
                    _presetChip('+50', () => onQuantityChanged(quantity + 50)),
                    _presetChip('+100', () => onQuantityChanged(quantity + 100)),
                  ],
                ),
                const SizedBox(height: 8),

                // Stepper Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Restock Quantity:',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: quantity > 1 ? () => onQuantityChanged(quantity - 1) : null,
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                        color: const Color(0xFF059669),
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      SizedBox(
                        width: 50,
                        child: Text(
                          '$quantity',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => onQuantityChanged(quantity + 1),
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        color: const Color(0xFF059669),
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Cost & Total Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${fmt.format(requirement.purchasePrice)} × $quantity units',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      '₹${fmt.format(requirement.purchasePrice * quantity)}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
                // Supplier Info Badge
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_shipping_outlined, size: 14, color: Color(0xFFD97706)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Supplier: ${requirement.supplierName ?? "Maharashtra FMCG"}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ⚡ Instant Restock Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isRestocking ? null : onQuickRestock,
                    icon: isRestocking
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.bolt_rounded, size: 16),
                    label: Text(
                      isRestocking
                          ? 'Updating Live Firestore...'
                          : '⚡ Instant Restock (+ $quantity Units)',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      disabledBackgroundColor: const Color(0xFF059669).withValues(alpha: 0.6),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
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

  Widget _presetChip(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ),
    );
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 8.5,
                color: color.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
