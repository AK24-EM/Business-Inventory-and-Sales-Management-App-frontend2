import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../widgets/store_header_widget.dart';
import '../../providers/supplier_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/store_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/supplier_service.dart';
import '../../models/supplier_model.dart';
import '../../models/product_model.dart';

/// Modern Enterprise Purchase Orders & Procurement Screen.
/// Follows the market-ready retail design system.
class PurchaseOrderScreen extends StatefulWidget {
  final SupplierModel? supplier;
  final List<Map<String, dynamic>>? prefilledItems;

  const PurchaseOrderScreen({
    super.key, 
    this.supplier,
    this.prefilledItems,
  });

  @override
  State<PurchaseOrderScreen> createState() => _PurchaseOrderScreenState();
}

class _PurchaseOrderScreenState extends State<PurchaseOrderScreen> {
  int _activeTabIndex = 0; // 0: Create PO, 1: Order History

  @override
  void initState() {
    super.initState();
    if (widget.supplier != null) {
      _activeTabIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeId =
        context.watch<StoreProvider>().selectedStore?.id;
    final supplierService = SupplierService();
    return StreamBuilder<List<PurchaseOrder>>(
      stream: supplierService.getPurchaseOrdersStream(storeId: storeId),
      builder: (context, snapshot) {
        final orders = snapshot.data ?? [];
        final activePOs = orders
            .where((o) =>
                o.status == PurchaseOrderStatus.sent ||
                o.status == PurchaseOrderStatus.draft)
            .toList();
        final inTransit = activePOs
            .where((o) => o.status == PurchaseOrderStatus.sent)
            .length;
        final committedAmount =
            activePOs.fold<double>(0, (s, o) => s + o.totalAmount);
        final vendorSet = orders.map((o) => o.supplierId).toSet();
        final fmt =
            NumberFormat.currency(symbol: '\u20b9', decimalDigits: 0);

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Top Enterprise Store Header
                  const StoreHeaderWidget(
                    title: 'Purchase Orders',
                    subtitle: 'VENDOR PROCUREMENT',
                  ),

                  // 1b. Procurement Hub Banner
                  _buildPOBanner(
                      activePOs.length, fmt.format(committedAmount),
                      vendorSet.length, inTransit),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 2. Summary KPI Metrics
                        _buildPOKPIRow(activePOs.length, inTransit,
                            committedAmount, vendorSet.length, fmt),
                        const SizedBox(height: 16),

                        // 3. Segmented Pill Tab Bar
                        _buildSegmentedTabs(),
                        const SizedBox(height: 16),

                        // 4. Tab Body Content
                        if (_activeTabIndex == 0)
                          _CreatePurchaseOrderTab(
                            supplier: widget.supplier,
                            prefilledItems: widget.prefilledItems,
                            onDispatched: () =>
                                setState(() => _activeTabIndex = 1),
                          )
                        else
                          const _PurchaseOrderHistoryTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── KPI Summary Row ──
  Widget _buildPOKPIRow(int activePOs, int inTransit, double committed,
      int vendors, NumberFormat fmt) {
    return Row(
      children: [
        Expanded(
          child: _buildKPICard(
            title: 'ACTIVE POS',
            value: '$activePOs orders',
            badgeText: '$inTransit In transit',
            badgeColor: const Color(0xFF2563EB),
            badgeBg: const Color(0xFFEFF6FF),
            icon: Icons.receipt_long_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildKPICard(
            title: 'COMMITTED',
            value: fmt.format(committed),
            badgeText: 'Net total',
            badgeColor: const Color(0xFF10B981),
            badgeBg: const Color(0xFFDCFCE7),
            icon: Icons.currency_rupee_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildKPICard(
            title: 'VENDORS',
            value: '$vendors Active',
            badgeText: 'on file',
            badgeColor: const Color(0xFF6366F1),
            badgeBg: const Color(0xFFEEF2FF),
            icon: Icons.local_shipping_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required String badgeText,
    required Color badgeColor,
    required Color badgeBg,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.4,
                ),
              ),
              Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: badgeColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Segmented Pill Tabs ──
  Widget _buildSegmentedTabs() {
    final tabs = ['Create Purchase Order', 'Purchase Order History'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _activeTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTabIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    tabs[index],
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Procurement Hub Banner ──
  Widget _buildPOBanner(int activePOs, String committedAmount, int vendors, int inTransit) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
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
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Procurement Hub', style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                    Text('Vendor Orders & Supply Chain', style: TextStyle(fontFamily: 'Poppins', fontSize: 10.5, color: Colors.white.withValues(alpha: 0.82))),
                  ],
                ),
              ),
              InkWell(
                onTap: () => setState(() => _activeTabIndex = 0),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 13, color: Color(0xFF065F46)),
                      SizedBox(width: 4),
                      Text('New PO', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF065F46))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _poBannerStat('Active POs', '$activePOs Orders', Icons.receipt_long_rounded, const Color(0xFFFDE68A)),
                Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.2)),
                _poBannerStat('Committed', committedAmount, Icons.currency_rupee_rounded, const Color(0xFF6EE7B7)),
                Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.2)),
                _poBannerStat('Vendors', '$vendors Active', Icons.business_rounded, const Color(0xFF93C5FD)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _poBannerStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
        Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 9.5, color: Colors.white.withValues(alpha: 0.75))),
      ],
    );
  }
}

// ── Tab 0: Create Purchase Order ──
class _CreatePurchaseOrderTab extends StatefulWidget {
  final SupplierModel? supplier;
  final List<Map<String, dynamic>>? prefilledItems;
  final VoidCallback? onDispatched;

  const _CreatePurchaseOrderTab({
    this.supplier,
    this.prefilledItems,
    this.onDispatched,
  });

  @override
  State<_CreatePurchaseOrderTab> createState() => _CreatePurchaseOrderTabState();
}

class _CreatePurchaseOrderTabState extends State<_CreatePurchaseOrderTab> {
  SupplierModel? _selectedSupplier;
  final List<_OrderItem> _items = [];
  DateTime? _expectedDeliveryDate;
  final _notesCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedSupplier = widget.supplier;
    _expectedDeliveryDate = DateTime.now().add(const Duration(days: 3));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;
    final provider = context.read<SupplierProvider>();
    await provider.loadSuppliers();
    if (!mounted) return;

    _loadPrefilledItems(provider);

    _selectedSupplier ??= widget.supplier;
    if (_selectedSupplier == null && provider.activeSuppliers.isNotEmpty) {
      _selectedSupplier = provider.activeSuppliers.first;
    } else if (_selectedSupplier == null && provider.suppliers.isNotEmpty) {
      _selectedSupplier = provider.suppliers.first;
    }

    setState(() {});
  }

  void _loadPrefilledItems(SupplierProvider supplierProvider) {
    final prefilled = widget.prefilledItems;
    if (prefilled == null || prefilled.isEmpty) return;

    for (final itemData in prefilled) {
      final productName = (itemData['productName'] ?? '').toString().trim();
      if (productName.isEmpty) continue;

      final quantity = (itemData['quantity'] as num?)?.toInt() ?? 0;
      if (quantity <= 0) continue;

      _items.add(
        _OrderItem(
          productId: (itemData['productId'] ?? productName).toString(),
          productName: productName,
          quantity: quantity,
          unitPrice: (itemData['unitPrice'] as num?)?.toDouble() ?? 0,
        ),
      );

      if (_selectedSupplier == null && itemData['supplierId'] != null) {
        final supplierId = itemData['supplierId'].toString();
        if (supplierId.isEmpty || supplierProvider.suppliers.isEmpty) continue;
        try {
          _selectedSupplier = supplierProvider.suppliers.firstWhere(
            (s) => s.id == supplierId,
          );
        } catch (_) {
          _selectedSupplier = supplierProvider.suppliers.first;
        }
      }
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _totalAmount {
    return _items.fold(0, (sum, item) => sum + item.totalPrice);
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PROCUREMENT ORDER BUILDER',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Assemble replenishment order items and dispatch to vendor',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),

          // 1. Supplier Selector
          _buildSupplierSelection(),
          const SizedBox(height: 16),

          // 2. Order Line Items
          _buildOrderItems(),
          const SizedBox(height: 16),

          // 3. Expected Delivery Date Picker
          _buildDeliveryDatePicker(),
          const SizedBox(height: 16),

          // 4. Procurement Notes
          _buildNotesField(),
          const SizedBox(height: 16),

          // 5. Total Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ESTIMATED ORDER TOTAL',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      '${_items.length} line items  •  GST 5% included',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                Text(
                  currency.format(_totalAmount),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF059669),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 6. Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearOrder,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Clear All',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: (_submitting || _items.isEmpty || _selectedSupplier == null)
                      ? null
                      : _submitOrder,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(_submitting ? 'Transmitting...' : 'Dispatch Purchase Order'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierSelection() {
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
            'Target Supplier / Vendor',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          if (_selectedSupplier != null)
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.local_shipping_rounded, color: Color(0xFF2563EB), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedSupplier!.name,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Phone: ${_selectedSupplier!.phone}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: _selectSupplier,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Change', style: TextStyle(fontSize: 11)),
                ),
              ],
            )
          else
            InkWell(
              onTap: _selectSupplier,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.storefront_rounded, size: 18, color: Color(0xFF2563EB)),
                        SizedBox(width: 8),
                        Text(
                          'Select a supplier before dispatching',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Order Line Items',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
                color: Color(0xFF475569),
              ),
            ),
            InkWell(
              onTap: _addItem,
              child: const Row(
                children: [
                  Icon(Icons.add_circle_rounded, size: 16, color: Color(0xFF2563EB)),
                  SizedBox(width: 4),
                  Text(
                    'Add Product',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_items.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shopping_cart_outlined,
                    size: 32,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'No Products Added Yet',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Click "Add Product" above to start building your purchase order',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add First Product'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          )
        else
          ..._items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.inventory_2_rounded,
                    color: Color(0xFF2563EB),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Qty: ${item.quantity} × ₹${item.unitPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${item.totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                  onPressed: () => _deleteItem(index),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDeliveryDatePicker() {
    return InkWell(
      onTap: _pickDeliveryDate,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xFF2563EB)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Expected Delivery Date',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      _expectedDeliveryDate != null
                          ? DateFormat('EEEE, d MMMM yyyy').format(_expectedDeliveryDate!)
                          : 'Select target date',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Icon(Icons.edit_calendar_rounded, size: 18, color: Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return TextField(
      controller: _notesCtrl,
      maxLines: 2,
      decoration: InputDecoration(
        labelText: 'Procurement Instructions (Optional)',
        labelStyle: const TextStyle(fontSize: 12),
        prefixIcon: const Icon(Icons.note_alt_rounded, color: Color(0xFF64748B)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
    );
  }

  void _selectSupplier() async {
    final provider = context.read<SupplierProvider>();
    final selected = await showDialog<SupplierModel>(
      context: context,
      builder: (_) => _SupplierSelectionDialog(suppliers: provider.suppliers),
    );
    if (selected != null) {
      setState(() => _selectedSupplier = selected);
    }
  }

  void _addItem() async {
    final item = await showDialog<_OrderItem>(
      context: context,
      builder: (_) => const _AddOrderItemDialog(),
    );
    if (item != null) {
      setState(() => _items.add(item));
    }
  }

  void _deleteItem(int index) {
    setState(() => _items.removeAt(index));
  }

  void _pickDeliveryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expectedDeliveryDate ?? DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _expectedDeliveryDate = picked);
    }
  }

  void _clearOrder() {
    setState(() {
      _items.clear();
      _expectedDeliveryDate = null;
      _notesCtrl.clear();
    });
  }

  Future<void> _submitOrder() async {
    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a supplier before dispatching this PO.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least 1 product item to the PO.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final store = context.read<StoreProvider>().selectedStore;
    if (store == null || store.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No store selected. Open this screen from a store first.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    if (auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be signed in to dispatch a purchase order.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    final provider = context.read<SupplierProvider>();

    final orderItems = _items.map((item) {
      return PurchaseOrderItem(
        productId: item.productId,
        productName: item.productName,
        orderedQuantity: item.quantity,
        unitPrice: item.unitPrice,
        totalPrice: item.totalPrice,
      );
    }).toList();

    try {
      final success = await provider.createPurchaseOrder(
        supplierId: _selectedSupplier!.id,
        supplierName: _selectedSupplier!.name,
        items: orderItems,
        targetStoreId: store.id,
        storeName: store.name,
        userId: auth.currentUser!.id,
        userName: auth.currentUser!.name,
        expectedDeliveryDate: _expectedDeliveryDate,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      if (!mounted) return;
      if (success) {
        final supplierName = _selectedSupplier!.name;
        _clearOrder();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase order dispatched to $supplierName.'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onDispatched?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Could not dispatch purchase order.'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dispatch failed: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    if (mounted) setState(() => _submitting = false);
  }
}

class _OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;

  _OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  double get totalPrice => quantity * unitPrice;
}

// ── Tab 1: Purchase Order History ──
class _PurchaseOrderHistoryTab extends StatelessWidget {
  const _PurchaseOrderHistoryTab();

  @override
  Widget build(BuildContext context) {
    final storeId = context.watch<StoreProvider>().selectedStore?.id;
    final supplierService = SupplierService();

    return StreamBuilder<List<PurchaseOrder>>(
      stream: supplierService.getPurchaseOrdersStream(storeId: storeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Could not load purchase orders: ${snapshot.error}',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: Color(0xFFEF4444),
              ),
            ),
          );
        }

        final liveOrders = snapshot.data ?? [];
        if (liveOrders.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Column(
              children: [
                Icon(Icons.receipt_long_outlined, size: 36, color: Color(0xFF94A3B8)),
                SizedBox(height: 10),
                Text(
                  'No purchase orders yet',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Dispatched orders will appear here.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: liveOrders.map((o) => _PurchaseOrderCard(order: o)).toList(),
        );
      },
    );
  }
}

class _PurchaseOrderCard extends StatelessWidget {
  final PurchaseOrder order;
  const _PurchaseOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.poNumber.isNotEmpty
                    ? order.poNumber
                    : 'PO-${order.id.length > 8 ? order.id.substring(0, 8).toUpperCase() : order.id}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2563EB),
                ),
              ),
              Text(
                order.status.name.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order.supplierName,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${order.items.length} items  •  ₹${order.totalAmount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11.5,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

// Dialogs
class _SupplierSelectionDialog extends StatelessWidget {
  final List<SupplierModel> suppliers;
  const _SupplierSelectionDialog({required this.suppliers});

  @override
  Widget build(BuildContext context) {
    if (suppliers.isEmpty) {
      return AlertDialog(
        title: const Text(
          'Select Supplier',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'No suppliers found. Add a supplier first, then dispatch the purchase order.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('Select Supplier', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: suppliers.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (_, index) {
            final s = suppliers[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.storefront_rounded, color: Color(0xFF2563EB), size: 20),
              ),
              title: Text(s.name, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: Text(s.phone, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              onTap: () => Navigator.pop(context, s),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _AddOrderItemDialog extends StatefulWidget {
  const _AddOrderItemDialog();

  @override
  State<_AddOrderItemDialog> createState() => _AddOrderItemDialogState();
}

class _AddOrderItemDialogState extends State<_AddOrderItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _productNameCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _unitPriceCtrl = TextEditingController();
  String? _selectedProductId;

  // Filter product list as user types
  List<Map<String, String>> _filteredProducts = [];
  bool _dropdownOpen = false;

  void _filterProducts(String query, List<ProductModel> products) {
    if (query.isEmpty) {
      setState(() {
        _filteredProducts = [];
        _dropdownOpen = false;
      });
      return;
    }
    final q = query.toLowerCase();
    final results = products
        .where((p) => p.name.toLowerCase().contains(q))
        .take(6)
        .map<Map<String, String>>(
            (p) => {'id': p.id, 'name': p.name, 'price': p.purchasePrice.toStringAsFixed(2)})
        .toList();
    setState(() {
      _filteredProducts = results;
      _dropdownOpen = results.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _productNameCtrl.dispose();
    _quantityCtrl.dispose();
    _unitPriceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get products directly from ProductProvider
    final allProducts =
        Provider.of<ProductProvider>(context, listen: false).products;
    return _dialog(context, allProducts);
  }

  Widget _dialog(BuildContext context, List<ProductModel> productList) {
    return AlertDialog(
      title: const Text('Add Procurement Item',
          style: TextStyle(
              fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15)),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _productNameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Product Name *',
                  hintText: 'e.g. Organic Almond Milk'),
              onChanged: (v) => _filterProducts(v, productList),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Required' : null,
            ),
            if (_dropdownOpen)
              Container(
                constraints: const BoxConstraints(maxHeight: 160),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: _filteredProducts.map((p) {
                    return ListTile(
                      dense: true,
                      title: Text(p['name']!,
                          style: const TextStyle(
                              fontFamily: 'Poppins', fontSize: 12)),
                      subtitle: Text('₹${p['price']}',
                          style: const TextStyle(fontSize: 11)),
                      onTap: () {
                        setState(() {
                          _selectedProductId = p['id'];
                          _productNameCtrl.text = p['name']!;
                          _unitPriceCtrl.text = p['price']!;
                          _dropdownOpen = false;
                          _filteredProducts = [];
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _quantityCtrl,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Quantity (Units) *'),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) =>
                  v == null || int.tryParse(v) == null
                      ? 'Valid qty required'
                      : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _unitPriceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  const InputDecoration(labelText: 'Unit Price (₹) *'),
              validator: (v) =>
                  v == null || double.tryParse(v) == null
                      ? 'Valid price required'
                      : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final productId = _selectedProductId ??
                  _productNameCtrl.text
                      .toLowerCase()
                      .trim()
                      .replaceAll(' ', '_');
              Navigator.pop(
                context,
                _OrderItem(
                  productId: productId,
                  productName: _productNameCtrl.text.trim(),
                  quantity: int.parse(_quantityCtrl.text),
                  unitPrice: double.parse(_unitPriceCtrl.text),
                ),
              );
            }
          },
          child: const Text('Add Item'),
        ),
      ],
    );
  }
}
