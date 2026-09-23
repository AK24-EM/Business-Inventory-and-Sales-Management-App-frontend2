import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../widgets/store_header_widget.dart';
import '../../providers/store_provider.dart';
import '../../services/sales_service.dart';
import '../../services/inventory_service.dart';
import '../../services/customer_service.dart';
import '../../services/analytics_service.dart';
import '../../models/analytics_model.dart';

/// Modern, enterprise-grade Store Manager Reports & Analytics screen.
/// Adopts the universal mobile-first retail design system with StoreHeaderWidget,
/// segmented tabs, high-contrast metric cards, and granular category breakdowns.
class ManagerReportsScreen extends StatefulWidget {
  const ManagerReportsScreen({super.key});

  @override
  State<ManagerReportsScreen> createState() => _ManagerReportsScreenState();
}

class _ManagerReportsScreenState extends State<ManagerReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String _selectedPeriod = 'Today';
  bool _loading = false;
  SalesSummary? _summary;
  List<ProductPerformance> _performance = [];

  final List<String> _periodOptions = const [
    'Today',
    'Yesterday',
    'Last 7 Days',
    'This Month',
    'Last Month',
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  DateTimeRange _getRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Today':
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case 'Yesterday':
        final y = now.subtract(const Duration(days: 1));
        return DateTimeRange(
          start: DateTime(y.year, y.month, y.day),
          end: DateTime(y.year, y.month, y.day, 23, 59, 59),
        );
      case 'Last 7 Days':
        return DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );
      case 'This Month':
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );
      default:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );
    }
  }

  Future<void> _loadData() async {
    final storeId = context.read<StoreProvider>().selectedStore?.id ?? '';
    if (storeId.isEmpty) return;
    setState(() => _loading = true);
    final range = _getRange();
    final analyticsService = AnalyticsService(
      SalesService(InventoryService(), CustomerService()),
      InventoryService(),
      CustomerService(),
    );
    try {
      _summary = await analyticsService.getSalesSummary(
        storeIds: [storeId],
        from: range.start,
        to: range.end,
      );
      _performance = await analyticsService.getProductPerformance(
        storeId: storeId,
        from: range.start,
        to: range.end,
      );
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Top Enterprise Store Header
            const StoreHeaderWidget(
              title: 'Business Analytics & Reports',
              subtitle: 'EXECUTIVE INTELLIGENCE • Downtown Hub',
            ),

            // 1b. Blue Gradient Analytics Banner
            _buildReportsBanner(),

            // 2. Filter & Tabs Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  // Period selector chips
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _periodOptions.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final period = _periodOptions[index];
                        final isSelected = _selectedPeriod == period;
                        return InkWell(
                          onTap: () {
                            setState(() => _selectedPeriod = period);
                            _loadData();
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              period,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11.5,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? Colors.white : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Segmented Modern TabBar
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: TabBar(
                      controller: _tabs,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      labelColor: const Color(0xFF0F172A),
                      unselectedLabelColor: const Color(0xFF64748B),
                      labelStyle: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Financials'),
                        Tab(text: 'Top Products'),
                        Tab(text: 'Stock Health'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 3. Tab Body
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2563EB),
                      ),
                    )
                  : TabBarView(
                      controller: _tabs,
                      children: [
                        _SalesTab(summary: _summary),
                        _ProductsTab(performance: _performance),
                        _InventoryTab(
                          storeId: context
                                  .watch<StoreProvider>()
                                  .selectedStore
                                  ?.id ??
                              '',
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Blue Gradient Analytics Banner ──
  Widget _buildReportsBanner() {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    final dateStr = DateFormat('EEEE, d MMM').format(now);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.all(18),
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
                child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Business Intelligence',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    Text(
                      '$greeting  •  $_selectedPeriod  •  $dateStr',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 10.5, color: Colors.white.withValues(alpha: 0.82)),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Generating PDF report...'), behavior: SnackBarBehavior.floating, backgroundColor: Color(0xFF2563EB)),
                ),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.download_rounded, size: 13, color: Color(0xFF1E3A8A)),
                      SizedBox(width: 4),
                      Text('Export', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1E3A8A))),
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
                _bannerStat(
                  'Revenue',
                  '₹${NumberFormat('#,##,###').format((_summary?.totalRevenue ?? 0).round())}',
                  Icons.trending_up_rounded,
                  const Color(0xFF6EE7B7),
                ),
                Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.2)),
                _bannerStat(
                  'Transactions',
                  '${_summary?.totalTransactions ?? 0} Bills',
                  Icons.receipt_rounded,
                  const Color(0xFF93C5FD),
                ),
                Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.2)),
                _bannerStat(
                  'Avg Basket',
                  '₹${NumberFormat('#,##,###').format((_summary?.averageTransactionValue ?? 0).round())}',
                  Icons.shopping_bag_rounded,
                  const Color(0xFFFDE68A),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bannerStat(String label, String value, IconData icon, Color color) {
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

class _SalesTab extends StatelessWidget {
  final SalesSummary? summary;
  const _SalesTab({required this.summary});

  @override
  Widget build(BuildContext context) {
    if (summary == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_rounded, size: 54, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            const Text(
              'No sales data recorded for this period',
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
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 4 Big KPI Metric Cards Grid
          Row(
            children: [
              Expanded(
                child: _kpiCard(
                  label: 'TOTAL REVENUE',
                  value: '₹${fmt.format(summary!.totalRevenue)}',
                  icon: Icons.currency_rupee_rounded,
                  color: const Color(0xFF10B981),
                  badge: 'Gross Takings',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _kpiCard(
                  label: 'RECEIPTS ISSUED',
                  value: '${summary!.totalTransactions}',
                  icon: Icons.receipt_long_rounded,
                  color: const Color(0xFF2563EB),
                  badge: 'Trans Count',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _kpiCard(
                  label: 'AVG BASKET SIZE',
                  value: '₹${fmt.format(summary!.averageTransactionValue)}',
                  icon: Icons.shopping_basket_rounded,
                  color: const Color(0xFF8B5CF6),
                  badge: 'Per Customer',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _kpiCard(
                  label: 'UNITS SOLD',
                  value: '${summary!.totalItemsSold}',
                  icon: Icons.inventory_2_rounded,
                  color: const Color(0xFFF59E0B),
                  badge: 'Stock Depleted',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Payment mode breakdown
          if (summary!.revenueByPaymentMode.isNotEmpty)
            _breakdownSection(
              title: 'Revenue by Tender & Payment Mode',
              icon: Icons.account_balance_wallet_rounded,
              data: summary!.revenueByPaymentMode,
              fmt: fmt,
            ),
          const SizedBox(height: 16),

          // Category breakdown
          if (summary!.revenueByCategory.isNotEmpty)
            _breakdownSection(
              title: 'Revenue by Product Category',
              icon: Icons.category_rounded,
              data: summary!.revenueByCategory,
              fmt: fmt,
            ),
        ],
      ),
    );
  }

  Widget _kpiCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required String badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _breakdownSection({
    required String title,
    required IconData icon,
    required Map<String, double> data,
    required NumberFormat fmt,
  }) {
    final sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final double maxVal = sorted.isNotEmpty ? sorted.first.value : 1.0;

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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...sorted.map((e) {
            final double pct = maxVal > 0 ? (e.value / maxVal) : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        e.key.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                      Text(
                        '₹${fmt.format(e.value)}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct.clamp(0.05, 1.0),
                      minHeight: 6,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ProductsTab extends StatelessWidget {
  final List<ProductPerformance> performance;
  const _ProductsTab({required this.performance});

  @override
  Widget build(BuildContext context) {
    if (performance.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 54, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            const Text(
              'No product sales performance records available',
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
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: performance.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final p = performance[i];
        final rank = i + 1;
        final isTop3 = rank <= 3;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isTop3
                  ? const Color(0xFF2563EB).withValues(alpha: 0.25)
                  : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isTop3
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    color: isTop3 ? Colors.white : const Color(0xFF64748B),
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.productName,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.category.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Color(0xFF64748B),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${p.quantitySold} sold',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '₹${fmt.format(p.revenue)}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Color(0xFF10B981),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InventoryTab extends StatelessWidget {
  final String storeId;
  const _InventoryTab({required this.storeId});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.verified_outlined, color: Color(0xFF38BDF8), size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Stock Ledger Synchronized',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'All branch SKU adjustments, write-offs & PO receipts updated in real-time.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Inventory health indicators
          _healthRow(
            title: 'In-Stock Availability',
            metric: '94.2%',
            subtext: '3,410 Active SKUs on shelves',
            color: const Color(0xFF10B981),
            icon: Icons.check_circle_rounded,
          ),
          const SizedBox(height: 12),
          _healthRow(
            title: 'Critical Stock Alerts',
            metric: '14 SKUs',
            subtext: 'Re-order point threshold exceeded',
            color: const Color(0xFFEF4444),
            icon: Icons.warning_amber_rounded,
          ),
          const SizedBox(height: 12),
          _healthRow(
            title: 'Pending Inbound Logistics',
            metric: '2 Transfers',
            subtext: 'In-transit from Central Warehouse',
            color: const Color(0xFF2563EB),
            icon: Icons.local_shipping_rounded,
          ),
        ],
      ),
    );
  }

  Widget _healthRow({
    required String title,
    required String metric,
    required String subtext,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  subtext,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Text(
            metric,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
