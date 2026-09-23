import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/store_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/sales_service.dart';
import '../../services/inventory_service.dart';
import '../../services/customer_service.dart';
import '../../services/supplier_service.dart';
import '../../models/supplier_model.dart';
import '../../models/analytics_model.dart';
import '../../models/user_model.dart';
import '../../widgets/store_header_widget.dart';

class RestockingScreen extends StatefulWidget {
  const RestockingScreen({super.key});

  @override
  State<RestockingScreen> createState() => _RestockingScreenState();
}

class _RestockingScreenState extends State<RestockingScreen> {
  List<RestockingRequirement> _requirements = [];
  final Map<String, int> _ownerQuantities = {};
  bool _loading = true;
  String? _selectedStoreFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final storeProvider = context.read<StoreProvider>();
    final auth = context.read<AuthProvider>();
    if (auth.currentUser?.role == UserRole.manager && storeProvider.selectedStore != null) {
      _selectedStoreFilter ??= storeProvider.selectedStore!.id;
    }
    final products = context.read<ProductProvider>();
    final stores = storeProvider.stores;
    await products.loadProducts();
    final svc = AnalyticsService(
      SalesService(InventoryService(), CustomerService()),
      InventoryService(),
      CustomerService(),
    );
    _requirements = await svc.getRestockingRequirements(
        stores.map((s) => s.id).toList());

    // Enrich with store names and product prices
    for (int i = 0; i < _requirements.length; i++) {
      final req = _requirements[i];
      final store = storeProvider.getStoreById(req.storeId);
      final product = products.getById(req.productId);
      if (store != null || product != null) {
        _requirements[i] = RestockingRequirement(
          productId: req.productId,
          productName: req.productName,
          category: req.category,
          storeId: req.storeId,
          storeName: store?.name ?? req.storeId,
          supplierId: req.supplierId,
          supplierName: req.supplierName,
          currentStock: req.currentStock,
          minimumStockLevel: req.minimumStockLevel,
          recommendedOrderQuantity: req.recommendedOrderQuantity,
          purchasePrice: product?.purchasePrice ?? 0,
          estimatedCost: (product?.purchasePrice ?? 0) *
              req.recommendedOrderQuantity,
        );
        _ownerQuantities['${req.storeId}_${req.productId}'] =
            req.recommendedOrderQuantity;
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  double get _totalEstimatedCost {
    return _requirements.fold(0.0, (sum, req) {
      final qty =
          _ownerQuantities['${req.storeId}_${req.productId}'] ??
              req.recommendedOrderQuantity;
      return sum + req.purchasePrice * qty;
    });
  }

  Future<void> _generatePO() async {
    final supplierService = SupplierService();
    final auth = context.read<AuthProvider>();
    // Group by supplier
    final Map<String, List<RestockingRequirement>> bySupplier = {};
    for (final req in _requirements) {
      if (req.supplierId != null) {
        bySupplier
            .putIfAbsent(req.supplierId!, () => [])
            .add(req);
      }
    }
    int created = 0;
    for (final entry in bySupplier.entries) {
      final items = entry.value
          .map((req) {
            final qty =
                _ownerQuantities['${req.storeId}_${req.productId}'] ??
                    req.recommendedOrderQuantity;
            return PurchaseOrderItem(
              productId: req.productId,
              productName: req.productName,
              orderedQuantity: qty,
              unitPrice: req.purchasePrice,
              totalPrice: req.purchasePrice * qty,
            );
          })
          .toList();
      final total =
          items.fold(0.0, (s, i) => s + i.totalPrice);
      await supplierService.createPurchaseOrder(PurchaseOrder(
        id: '',
        supplierId: entry.key,
        supplierName: entry.value.first.supplierName ?? entry.key,
        items: items,
        totalAmount: total,
        createdByUserId: auth.currentUser!.id,
        createdByUserName: auth.currentUser!.name,
        createdAt: DateTime.now(),
        targetStoreId: entry.value.first.storeId,
      ));
      created++;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$created purchase order(s) created.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    final stores = context.watch<StoreProvider>().stores;
    final displayedReqs = _selectedStoreFilter == null
        ? _requirements
        : _requirements.where((r) => r.storeId == _selectedStoreFilter).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Enterprise Top Header
            const StoreHeaderWidget(
              title: 'Restocking & Supply',
              subtitle: 'AUTO-REPLENISHMENT • Multi-Branch Procurement',
            ),

            // 2. Emerald Procurement Hero Banner
            _buildRestockHeroBanner(fmt),

            // Store Filter Chips
            if (stores.length > 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: const Text('All Stores'),
                          selected: _selectedStoreFilter == null,
                          onSelected: (_) => setState(() => _selectedStoreFilter = null),
                          selectedColor: const Color(0xFF059669),
                          labelStyle: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _selectedStoreFilter == null ? Colors.white : const Color(0xFF475569),
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: _selectedStoreFilter == null ? const Color(0xFF059669) : const Color(0xFFCBD5E1),
                            ),
                          ),
                        ),
                      ),
                      ...stores.map((s) {
                        final isSel = _selectedStoreFilter == s.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(s.name),
                            selected: isSel,
                            onSelected: (_) => setState(() => _selectedStoreFilter = isSel ? null : s.id),
                            selectedColor: const Color(0xFF059669),
                            labelStyle: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSel ? Colors.white : const Color(0xFF475569),
                            ),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSel ? const Color(0xFF059669) : const Color(0xFFCBD5E1),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : displayedReqs.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_outline,
                                  size: 56,
                                  color: AppColors.secondary),
                              SizedBox(height: 12),
                              Text('All stocks are adequate',
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontFamily: 'Poppins',
                                      fontSize: 16)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: displayedReqs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final req = displayedReqs[i];
                            final key =
                                '${req.storeId}_${req.productId}';
                            final qty = _ownerQuantities[key] ??
                                req.recommendedOrderQuantity;
                            return _RestockCard(
                              requirement: req,
                              ownerQty: qty,
                              onQtyChanged: (newQty) {
                                setState(() =>
                                    _ownerQuantities[key] = newQty);
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Emerald Procurement Hero Banner ──
  Widget _buildRestockHeroBanner(NumberFormat fmt) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF065F46), Color(0xFF059669), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha: 0.30),
            blurRadius: 16,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Automated Reorder Pipeline',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${_requirements.length} SKUs need replenishment',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10.5,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: _requirements.isEmpty ? null : _generatePO,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_task_rounded, size: 13, color: Color(0xFF065F46)),
                      SizedBox(width: 4),
                      Text(
                        'Create PO',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF065F46),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _restockBannerStat('Need Restock', '${_requirements.length} Items', Icons.inventory_2_outlined, const Color(0xFFFDE68A)),
                Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.2)),
                _restockBannerStat('Est. Outlay', '₹${fmt.format(_totalEstimatedCost)}', Icons.currency_rupee_rounded, const Color(0xFF6EE7B7)),
                Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.2)),
                _restockBannerStat('Auto-Reorder', 'Active', Icons.autorenew_rounded, const Color(0xFF93C5FD)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _restockBannerStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 9.5,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}

class _RestockCard extends StatelessWidget {
  final RestockingRequirement requirement;
  final int ownerQty;
  final ValueChanged<int> onQtyChanged;

  const _RestockCard({
    required this.requirement,
    required this.ownerQty,
    required this.onQtyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(requirement.productName,
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                    Text(
                        '${requirement.category} · ${requirement.storeName}',
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${requirement.currentStock} in stock',
                    style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoChip(label: 'Min Stock',
                  value: '${requirement.minimumStockLevel}'),
              const SizedBox(width: 8),
              _InfoChip(label: 'Recommended',
                  value: '${requirement.recommendedOrderQuantity}'),
              const SizedBox(width: 8),
              _InfoChip(
                  label: 'Unit Price',
                  value: '₹${fmt.format(requirement.purchasePrice)}'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Order Qty:',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
              const Spacer(),
              IconButton(
                onPressed: ownerQty > 1
                    ? () => onQtyChanged(ownerQty - 1)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: AppColors.primary,
                iconSize: 20,
              ),
              Text('$ownerQty',
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 18)),
              IconButton(
                onPressed: () => onQtyChanged(ownerQty + 1),
                icon: const Icon(Icons.add_circle_outline),
                color: AppColors.primary,
                iconSize: 20,
              ),
              Text(
                  '= ₹${fmt.format(requirement.purchasePrice * ownerQty)}',
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      fontSize: 14)),
            ],
          ),
          if (requirement.supplierName != null) ...[
            const Divider(height: 16),
            Row(
              children: [
                const Icon(Icons.local_shipping_outlined,
                    size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text('Supplier: ${requirement.supplierName}',
                    style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 11)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 9, color: AppColors.textTertiary)),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
