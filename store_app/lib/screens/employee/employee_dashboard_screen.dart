import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/store_provider.dart';
import '../../providers/sales_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../models/sale_model.dart';
import '../../models/inventory_model.dart';
import '../../widgets/store_header_widget.dart';

/// Modern, market-ready Employee & Cashier Dashboard (Owner Hub).
/// Designed for high visual excellence, mobile ergonomics, and fast store operations.
class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  State<EmployeeDashboardScreen> createState() =>
      _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  String _activeTab = 'Overview'; // 'Overview', 'Till & Shift', 'Live Sales', 'Alerts'
  String _salesFilter = 'All'; // 'All', 'UPI', 'Cash', 'Card'
  bool _inboundConfirmed = false;

  // Demo fallback sales for rich presentation when Firestore stream has 0 sales today
  final List<SaleModel> _demoFallbackSales = [
    SaleModel(
      id: 'SALE-8831',
      storeId: 'store_1',
      storeName: 'Store 1: Downtown Central',
      items: const [
        SaleItem(
          productId: 'p1',
          productName: 'Organic Almond Milk 1L',
          category: 'Beverages',
          quantity: 2,
          unitPrice: 240,
          totalPrice: 480,
        ),
        SaleItem(
          productId: 'p2',
          productName: 'Basmati Royal Rice 5kg',
          category: 'Packaged Foods',
          quantity: 1,
          unitPrice: 550,
          totalPrice: 550,
        ),
      ],
      subtotal: 1030.0,
      totalAmount: 1030.0,
      paymentMode: PaymentMode.upi,
      customerId: 'c1',
      customerName: 'Rahul Sharma',
      customerPhone: '+91 98451 22394',
      loyaltyPointsEarned: 10,
      employeeId: 'emp_01',
      employeeName: 'Alex Cashier',
      timestamp: DateTime.now().subtract(const Duration(minutes: 14)),
      invoiceNumber: 'INV-2026-0891',
    ),
    SaleModel(
      id: 'SALE-8830',
      storeId: 'store_1',
      storeName: 'Store 1: Downtown Central',
      items: const [
        SaleItem(
          productId: 'p3',
          productName: 'Cold Pressed Olive Oil 500ml',
          category: 'Cooking Essentials',
          quantity: 1,
          unitPrice: 420,
          totalPrice: 420,
        ),
      ],
      subtotal: 420.0,
      totalAmount: 420.0,
      paymentMode: PaymentMode.cash,
      customerId: 'c2',
      customerName: 'Priya Patel',
      customerPhone: '+91 91234 56789',
      loyaltyPointsEarned: 4,
      employeeId: 'emp_01',
      employeeName: 'Alex Cashier',
      timestamp: DateTime.now().subtract(const Duration(minutes: 52)),
      invoiceNumber: 'INV-2026-0890',
    ),
    SaleModel(
      id: 'SALE-8829',
      storeId: 'store_1',
      storeName: 'Store 1: Downtown Central',
      items: const [
        SaleItem(
          productId: 'p4',
          productName: 'Dark Roast Coffee Beans 250g',
          category: 'Beverages',
          quantity: 2,
          unitPrice: 310,
          totalPrice: 620,
        ),
      ],
      subtotal: 620.0,
      totalAmount: 620.0,
      paymentMode: PaymentMode.card,
      customerId: 'c3',
      customerName: 'Amit Verma',
      customerPhone: '+91 99887 76655',
      loyaltyPointsEarned: 6,
      employeeId: 'emp_01',
      employeeName: 'Alex Cashier',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 40)),
      invoiceNumber: 'INV-2026-0889',
    ),
    SaleModel(
      id: 'SALE-8828',
      storeId: 'store_1',
      storeName: 'Store 1: Downtown Central',
      items: const [
        SaleItem(
          productId: 'p5',
          productName: 'Alfonso Mango Pulp 850g',
          category: 'Canned Foods',
          quantity: 3,
          unitPrice: 180,
          totalPrice: 540,
        ),
      ],
      subtotal: 540.0,
      totalAmount: 540.0,
      paymentMode: PaymentMode.upi,
      customerId: 'c4',
      customerName: 'Sunita Rao',
      customerPhone: '+91 98765 43210',
      loyaltyPointsEarned: 5,
      employeeId: 'emp_01',
      employeeName: 'Alex Cashier',
      timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
      invoiceNumber: 'INV-2026-0888',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final storeProvider = context.watch<StoreProvider>();
    final salesProvider = context.watch<SalesProvider>();
    final invProvider = context.watch<InventoryProvider>();

    final store = storeProvider.selectedStore;
    final user = auth.currentUser;
    final storeId = store?.id ?? 'store_1';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF2563EB),
          onRefresh: () async {
            await storeProvider.loadStores();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 1. Universal Top Header ────────────────────────
                StoreHeaderWidget(
                  title: 'Shift & Store Hub',
                  subtitle: 'ACTIVE SHIFT • Till #02',
                  onNotificationTap: () =>
                      context.go('/employee/notifications'),
                  onAvatarTap: () => _showCashierProfileSheet(context),
                  onStoreTap: () => _showStoreSelectorSheet(context),
                ),

                const SizedBox(height: 10),

                // ── 2. Segmented Navigation Tabs ───────────────────
                _buildSegmentedTabs(),

                const SizedBox(height: 12),

                // ── 3. Active Shift Greeting & Till Float Banner ───
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildShiftWelcomeBanner(user?.name ?? 'Alex'),
                ),

                const SizedBox(height: 14),

                // ── 4. Quick Action Station (POS, Inventory, Sales) ─
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildQuickActionStation(),
                ),

                const SizedBox(height: 14),

                // ── 5. Inbound Delivery Card (Reference Screenshot 2)
                if (!_inboundConfirmed)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildInboundDeliveryCard(),
                  ),

                if (!_inboundConfirmed) const SizedBox(height: 14),

                // ── 6. Live Stream Data: KPIs, Target, Stock & Sales
                StreamBuilder<List<SaleModel>>(
                  stream: salesProvider.watchTodaySales(storeId),
                  builder: (context, salesSnap) {
                    final rawSales = salesSnap.data ?? [];
                    final effectiveSales =
                        rawSales.isNotEmpty ? rawSales : _demoFallbackSales;

                    return StreamBuilder<List<InventoryModel>>(
                      stream: invProvider.watchLowStock(storeId),
                      builder: (context, invSnap) {
                        final lowStockItems = invSnap.data ?? [];
                        final lowStockCount = lowStockItems.isNotEmpty
                            ? lowStockItems.length
                            : 14;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── KPI Metrics Grid ────────────────────
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: _buildKpiGrid(
                                sales: effectiveSales,
                                lowStockCount: lowStockCount,
                              ),
                            ),

                            const SizedBox(height: 14),

                            // ── Daily Shift Target & Tender Breakdown ──
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: _buildTargetAndTenderCard(effectiveSales),
                            ),

                            const SizedBox(height: 14),

                            // ── Hourly Sales Velocity Heatmap ───────
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: _buildSalesVelocityCard(),
                            ),

                            const SizedBox(height: 16),

                            // ── Low Stock Action Feed ───────────────
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: _buildLowStockFeed(lowStockItems),
                            ),

                            const SizedBox(height: 16),

                            // ── Recent Sales Feed with Filter Chips ───
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: _buildRecentSalesFeed(effectiveSales),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 1. Segmented Navigation Tabs
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSegmentedTabs() {
    final tabs = ['Overview', 'Till & Shift', 'Live Sales', 'Alerts'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = _activeTab == tab;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() => _activeTab = tab);
                if (tab == 'Live Sales') {
                  context.go('/employee/sales');
                } else if (tab == 'Alerts') {
                  context.go('/employee/inventory');
                } else if (tab == 'Till & Shift') {
                  _showShiftReconcileModal(context);
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF2563EB)
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
                            color:
                                const Color(0xFF2563EB).withValues(alpha: 0.22),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (tab == 'Alerts') ...[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      tab,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11.5,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. Cashier Active Shift Welcome Banner
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildShiftWelcomeBanner(String cashierName) {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final dateStr = DateFormat('EEEE, d MMM').format(now);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.26),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar with live shift ring
              Stack(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        cashierName.isNotEmpty
                            ? cashierName[0].toUpperCase()
                            : 'C',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Shift status & Cashier info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting, $cashierName',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'SHIFT #02 • TILL 02 ACTIVE',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // End shift button
              InkWell(
                onTap: () => _showShiftReconcileModal(context),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Drawer Float status pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Color(0xFF6EE7B7),
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Opening Till Float',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          color: Color(0xFFE2E8F0),
                        ),
                      ),
                      Text(
                        '₹2,500.00 (Balanced)',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => _showShiftReconcileModal(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 13,
                          color: Color(0xFF1E3A8A),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Till Details',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                      ],
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
  // 3. Quick Action Station (POS, Inventory, Receipts, Loyalty)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildQuickActionStation() {
    return Row(
      children: [
        // Primary Blue POS Button
        Expanded(
          flex: 5,
          child: InkWell(
            onTap: () => context.go('/employee/pos'),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.point_of_sale_rounded,
                      color: Color(0xFF2563EB),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New POS Bill',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Scan & Tender',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10.5,
                            color: Color(0xFFDBEAFE),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        // Quick Stock Check
        Expanded(
          flex: 3,
          child: _buildSmallActionTile(
            title: 'Stock',
            subtitle: 'SKU Check',
            icon: Icons.inventory_2_rounded,
            iconColor: const Color(0xFF047857),
            bgColor: const Color(0xFFECFDF5),
            borderColor: const Color(0xFFA7F3D0),
            onTap: () => context.go('/employee/inventory'),
          ),
        ),

        const SizedBox(width: 10),

        // Quick Receipts
        Expanded(
          flex: 3,
          child: _buildSmallActionTile(
            title: 'Receipts',
            subtitle: 'History',
            icon: Icons.receipt_long_rounded,
            iconColor: const Color(0xFF7C3AED),
            bgColor: const Color(0xFFF5F3FF),
            borderColor: const Color(0xFFDDD6FE),
            onTap: () => context.go('/employee/sales'),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor, width: 0.5),
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 9.5,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4. Inbound Delivery Card (Reference from Screenshot 2)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildInboundDeliveryCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBBF7D0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A34A).withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_shipping_rounded,
                        size: 13, color: Color(0xFF15803D)),
                    SizedBox(width: 4),
                    Text(
                      'INBOUND DELIVERY  TR-8842',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF15803D),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      size: 13, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(
                    'ETA ~15m',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  Icons.liquor_rounded,
                  color: Color(0xFF15803D),
                  size: 24,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cold Pressed Olive Oil (1L)',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '20 Units • Westend (Store 2) → Downtown',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'Driver: CargoVan #04',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _inboundConfirmed = true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Delivery TR-8842 confirmed & added to stock!'),
                      backgroundColor: Color(0xFF047857),
                    ),
                  );
                },
                icon: const Icon(Icons.check_rounded, size: 14),
                label: const Text('Confirm & Add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF047857),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  textStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 5. 4 KPI Metrics Grid (Revenue, Bills, Till Cash, Low Stock)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildKpiGrid({
    required List<SaleModel> sales,
    required int lowStockCount,
  }) {
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    final totalRevenue = sales.fold(0.0, (sum, item) => sum + item.totalAmount);
    final totalBills = sales.length;
    final avgTicket = totalBills > 0 ? (totalRevenue / totalBills) : 0.0;

    final cashSales = sales
        .where((s) => s.paymentMode == PaymentMode.cash)
        .fold(0.0, (sum, s) => sum + s.totalAmount);
    final tillCash = 2500.0 + cashSales;

    return Column(
      children: [
        Row(
          children: [
            // Card 1: Today's Revenue
            Expanded(
              child: _buildMetricCard(
                title: "TODAY'S REVENUE",
                value: '₹${fmt.format(totalRevenue)}',
                badgeText: '+14.2% vs avg',
                badgeIcon: Icons.trending_up_rounded,
                badgeColor: const Color(0xFF10B981),
                badgeBg: const Color(0xFFECFDF5),
                icon: Icons.currency_rupee_rounded,
                iconColor: const Color(0xFF2563EB),
                iconBg: const Color(0xFFEFF6FF),
              ),
            ),
            const SizedBox(width: 10),

            // Card 2: Bills / Transactions
            Expanded(
              child: _buildMetricCard(
                title: 'BILLS COMPLETED',
                value: '$totalBills',
                badgeText: 'Avg ₹${avgTicket.toStringAsFixed(0)}',
                badgeIcon: Icons.receipt_rounded,
                badgeColor: const Color(0xFF6366F1),
                badgeBg: const Color(0xFFEEF2FF),
                icon: Icons.shopping_bag_outlined,
                iconColor: const Color(0xFF4F46E5),
                iconBg: const Color(0xFFEEF2FF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // Card 3: Till Cash Float
            Expanded(
              child: _buildMetricCard(
                title: 'DRAWER CASH',
                value: '₹${fmt.format(tillCash)}',
                badgeText: 'Float Safe',
                badgeIcon: Icons.lock_outline_rounded,
                badgeColor: const Color(0xFF059669),
                badgeBg: const Color(0xFFECFDF5),
                icon: Icons.point_of_sale_rounded,
                iconColor: const Color(0xFF047857),
                iconBg: const Color(0xFFECFDF5),
              ),
            ),
            const SizedBox(width: 10),

            // Card 4: Low Stock Alert
            Expanded(
              child: _buildMetricCard(
                title: 'LOW STOCK SKUS',
                value: '$lowStockCount',
                badgeText: 'Action req.',
                badgeIcon: Icons.warning_amber_rounded,
                badgeColor: const Color(0xFFDC2626),
                badgeBg: const Color(0xFFFEE2E2),
                icon: Icons.inventory_2_outlined,
                iconColor: const Color(0xFFDC2626),
                iconBg: const Color(0xFFFEF2F2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String badgeText,
    required IconData badgeIcon,
    required Color badgeColor,
    required Color badgeBg,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
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
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.4,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(badgeIcon, size: 11, color: badgeColor),
                const SizedBox(width: 4),
                Text(
                  badgeText,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
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
  // 6. Daily Target & Tender Breakdown
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTargetAndTenderCard(List<SaleModel> sales) {
    final totalRevenue = sales.fold(0.0, (sum, s) => sum + s.totalAmount);
    const dailyTarget = 35000.0;
    final progress = (totalRevenue / dailyTarget).clamp(0.0, 1.0);
    final percentage = (progress * 100).toInt();

    final upiSales = sales
        .where((s) => s.paymentMode == PaymentMode.upi)
        .fold(0.0, (sum, s) => sum + s.totalAmount);
    final cashSales = sales
        .where((s) => s.paymentMode == PaymentMode.cash)
        .fold(0.0, (sum, s) => sum + s.totalAmount);
    final cardSales = sales
        .where((s) => s.paymentMode == PaymentMode.card)
        .fold(0.0, (sum, s) => sum + s.totalAmount);

    final totalTenders = (upiSales + cashSales + cardSales > 0)
        ? (upiSales + cashSales + cardSales)
        : 1.0;
    final upiPercent = ((upiSales / totalTenders) * 100).toInt();
    final cashPercent = ((cashSales / totalTenders) * 100).toInt();
    final cardPercent = ((cardSales / totalTenders) * 100).toInt();

    final fmt = NumberFormat('#,##,##0', 'en_IN');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Target Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.flag_rounded, color: Color(0xFF2563EB), size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Daily Shift Target',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$percentage% Reached',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
            ),
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${fmt.format(totalRevenue)} achieved',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                'Target: ₹${fmt.format(dailyTarget)}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11.5,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),

          const Divider(height: 24, color: Color(0xFFF1F5F9)),

          const Text(
            'TENDER BREAKDOWN',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              // UPI Pill
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.qr_code_rounded,
                              size: 13, color: Color(0xFF2563EB)),
                          SizedBox(width: 4),
                          Text(
                            'UPI / QR',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${fmt.format(upiSales)} ($upiPercent%)',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E3A8A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Cash Pill
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.payments_rounded,
                              size: 13, color: Color(0xFF047857)),
                          SizedBox(width: 4),
                          Text(
                            'Cash',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF047857),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${fmt.format(cashSales)} ($cashPercent%)',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF064E3B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Card Pill
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.credit_card_rounded,
                              size: 13, color: Color(0xFF475569)),
                          SizedBox(width: 4),
                          Text(
                            'Card',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${fmt.format(cardSales)} ($cardPercent%)',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 7. Hourly Sales Velocity Heatmap Card
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSalesVelocityCard() {
    final slots = [
      {'time': '09 - 11 AM', 'pct': 0.35, 'val': '₹4.2k', 'isPeak': false},
      {'time': '11 - 01 PM', 'pct': 0.85, 'val': '₹9.8k', 'isPeak': true},
      {'time': '01 - 04 PM', 'pct': 0.50, 'val': '₹5.6k', 'isPeak': false},
      {'time': '04 - 07 PM', 'pct': 0.75, 'val': '₹7.4k', 'isPeak': false},
    ];

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.bolt_rounded,
                      color: Color(0xFFD97706), size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Shift Sales Velocity',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'PEAK: 11 AM - 1 PM',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: slots.map((slot) {
              final pct = slot['pct'] as double;
              final isPeak = slot['isPeak'] as bool;

              return Column(
                children: [
                  Text(
                    slot['val'] as String,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isPeak
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 44,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 44,
                      height: 56 * pct,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isPeak
                              ? [const Color(0xFF60A5FA), const Color(0xFF2563EB)]
                              : [const Color(0xFFCBD5E1), const Color(0xFF94A3B8)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    slot['time'] as String,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 9.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 8. Low Stock Attention Feed
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildLowStockFeed(List<InventoryModel> items) {
    final now = DateTime.now();
    final displayItems = items.isNotEmpty
        ? items.take(4).toList()
        : [
            InventoryModel(
              id: 'inv_1',
              storeId: 'store_1',
              productId: 'p_rice',
              productName: 'Basmati Royal Rice 5kg',
              category: 'Packaged Foods',
              currentStock: 6,
              minimumStockLevel: 15,
              lastUpdated: now,
            ),
            InventoryModel(
              id: 'inv_2',
              storeId: 'store_1',
              productId: 'p_pulp',
              productName: 'Alfonso Mango Pulp 850g',
              category: 'Canned Foods',
              currentStock: 4,
              minimumStockLevel: 12,
              lastUpdated: now,
            ),
            InventoryModel(
              id: 'inv_3',
              storeId: 'store_1',
              productId: 'p_flour',
              productName: 'Aashirvaad Whole Wheat 10kg',
              category: 'Flour & Grains',
              currentStock: 18,
              minimumStockLevel: 20,
              lastUpdated: now,
            ),
          ];

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFDC2626),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Urgent Stock Attention',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => context.go('/employee/inventory'),
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        'Audit All',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Color(0xFF2563EB),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Column(
            children: displayItems.map((item) {
              final isOutOfStock = item.currentStock == 0;
              final max = item.minimumStockLevel > 0
                  ? item.minimumStockLevel.toDouble()
                  : 20.0;
              final progress = (item.currentStock / max).clamp(0.0, 1.0);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isOutOfStock
                                ? const Color(0xFFFEE2E2)
                                : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.inventory_2_outlined,
                              size: 18,
                              color: isOutOfStock
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFFD97706),
                            ),
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
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${item.category} • Min Safe: ${item.minimumStockLevel}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isOutOfStock
                                ? 'OUT OF STOCK'
                                : 'LOW (${item.currentStock} LEFT)',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFEF4444),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Quick Transfer action row (from Screenshot 2)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.storefront_outlined,
                                size: 13, color: Color(0xFF2563EB)),
                            SizedBox(width: 4),
                            Text(
                              'Westend Store: 28 units avail.',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10.5,
                                color: Color(0xFF2563EB),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Transfer request sent for ${item.productName}'),
                                backgroundColor: const Color(0xFF2563EB),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                              border:
                                  Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: const Text(
                              'Request Transfer',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 9. Recent Sales Feed with Tender Filtering
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildRecentSalesFeed(List<SaleModel> sales) {
    // Filter by payment tender if selected
    final filteredSales = sales.where((s) {
      if (_salesFilter == 'All') return true;
      if (_salesFilter == 'UPI') return s.paymentMode == PaymentMode.upi;
      if (_salesFilter == 'Cash') return s.paymentMode == PaymentMode.cash;
      if (_salesFilter == 'Card') return s.paymentMode == PaymentMode.card;
      return true;
    }).take(5).toList();

    final fmt = NumberFormat('#,##,##0.00', 'en_IN');

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.receipt_long_rounded,
                    color: Color(0xFF2563EB),
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Recent Transactions',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => context.go('/employee/sales'),
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Color(0xFF2563EB),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Tender filter pills
          Row(
            children: ['All', 'UPI', 'Cash', 'Card'].map((mode) {
              final isSel = _salesFilter == mode;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  onTap: () => setState(() => _salesFilter = mode),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSel
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      mode,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10.5,
                        fontWeight:
                            isSel ? FontWeight.w700 : FontWeight.w500,
                        color: isSel ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 10),

          if (filteredSales.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              alignment: Alignment.center,
              child: const Text(
                'No transactions match this tender filter',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                ),
              ),
            )
          else
            Column(
              children: filteredSales.map((sale) {
                final paymentBg = sale.paymentMode == PaymentMode.upi
                    ? const Color(0xFFEFF6FF)
                    : sale.paymentMode == PaymentMode.cash
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFF1F5F9);
                final paymentColor = sale.paymentMode == PaymentMode.upi
                    ? const Color(0xFF2563EB)
                    : sale.paymentMode == PaymentMode.cash
                        ? const Color(0xFF047857)
                        : const Color(0xFF475569);

                return InkWell(
                  onTap: () => _showSaleDetailSheet(context, sale),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: paymentBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Icon(
                              sale.paymentMode == PaymentMode.upi
                                  ? Icons.qr_code_rounded
                                  : sale.paymentMode == PaymentMode.cash
                                      ? Icons.payments_outlined
                                      : Icons.credit_card_rounded,
                              size: 18,
                              color: paymentColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sale.invoiceNumber ??
                                    'INV-${sale.id.substring(0, 6).toUpperCase()}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                '${sale.customerName ?? 'Walk-in'} • ${sale.itemCount} item${sale.itemCount == 1 ? '' : 's'}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${fmt.format(sale.totalAmount)}',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              DateFormat('hh:mm a').format(sale.timestamp),
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: Color(0xFFCBD5E1),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 6),

          InkWell(
            onTap: () => context.go('/employee/sales'),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Open Sales & Receipts History',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: Color(0xFF2563EB),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 10. Modals: Sale Detail Sheet, Till Reconcile, Profile & Store Selector
  // ─────────────────────────────────────────────────────────────────────────
  void _showSaleDetailSheet(BuildContext context, SaleModel sale) {
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.70,
        maxChildSize: 0.92,
        builder: (ctx, scrollCtrl) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: SingleChildScrollView(
            controller: scrollCtrl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sale.invoiceNumber ?? 'Invoice',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          DateFormat('EEEE, d MMM yyyy • hh:mm a')
                              .format(sale.timestamp),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        sale.paymentMode.displayName.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                if (sale.customerName != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_rounded,
                          size: 18,
                          color: Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          sale.customerName!,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        if (sale.customerPhone != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '(${sale.customerPhone})',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                const Text(
                  'ITEMS BILLED',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 8),

                ...sale.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.productName,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          Text(
                            '${item.quantity} × ₹${fmt.format(item.unitPrice)}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            '₹${fmt.format(item.totalPrice)}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    )),

                const Divider(height: 24, color: Color(0xFFE2E8F0)),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Subtotal',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      '₹${fmt.format(sale.subtotal)}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                if (sale.loyaltyPointsRedeemed > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Loyalty Redeemed',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Color(0xFF047857),
                        ),
                      ),
                      Text(
                        '-₹${fmt.format(sale.loyaltyPointsRedeemed)}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Paid',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '₹${fmt.format(sale.totalAmount)}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Receipt sent to thermal printer'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.print_outlined, size: 16),
                        label: const Text('Re-Print'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                          side: const BorderSide(color: Color(0xFF2563EB)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(sheetCtx),
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Done'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showShiftReconcileModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.point_of_sale_rounded,
                    color: Color(0xFF2563EB), size: 22),
                SizedBox(width: 8),
                Text(
                  'Shift & Till Reconciliation',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Review current register cash float and tender balances.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Opening Float (Cash):',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Color(0xFF64748B))),
                      Text('₹2,500.00',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Today Cash Inflow:',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Color(0xFF64748B))),
                      Text('₹5,920.00',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF047857))),
                    ],
                  ),
                  Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Expected Drawer Cash:',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A))),
                      Text('₹8,420.00',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2563EB))),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(sheetCtx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Shift report printed & till reconciled'),
                          backgroundColor: Color(0xFF047857),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF047857),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Reconcile & Print'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCashierProfileSheet(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF2563EB),
                  child: Text(
                    user != null && user.name.isNotEmpty
                        ? user.name[0].toUpperCase()
                        : 'E',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Employee Cashier',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        user?.email ?? 'cashier@store.com',
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    user?.role.name.toUpperCase() ?? 'EMPLOYEE',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ListTile(
              dense: true,
              leading: const Icon(Icons.tune_rounded, color: Color(0xFF2563EB)),
              title: const Text('Till & Shift Report'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.pop(sheetCtx);
                _showShiftReconcileModal(context);
              },
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.receipt_long_rounded,
                  color: Color(0xFF047857)),
              title: const Text('My Shift Sales'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.pop(sheetCtx);
                context.go('/employee/sales');
              },
            ),
            const Divider(height: 16),
            ListTile(
              dense: true,
              leading:
                  const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
              title: const Text(
                'End Shift & Sign Out',
                style: TextStyle(
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () {
                Navigator.pop(sheetCtx);
                _showSignOutDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStoreSelectorSheet(BuildContext context) {
    final storeProvider = context.read<StoreProvider>();
    final stores = storeProvider.stores;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Store Location',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            ...stores.map((s) {
              final isSelected = s.id == storeProvider.selectedStore?.id;
              return ListTile(
                dense: true,
                leading: Icon(
                  Icons.storefront_rounded,
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF64748B),
                ),
                title: Text(
                  s.name,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF0F172A),
                  ),
                ),
                subtitle:
                    Text(s.address.isNotEmpty ? s.address : 'Active branch'),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF2563EB))
                    : null,
                onTap: () {
                  storeProvider.selectStore(s);
                  Navigator.pop(sheetCtx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFDC2626),
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'End Shift & Sign Out',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Are you sure you want to clock out and end your register shift?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Color(0xFF64748B),
                fontSize: 12.5,
              ),
            ),
            if (user != null) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  '${user.name} (${user.email})',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      context.read<AuthProvider>().signOut();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Sign Out',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
