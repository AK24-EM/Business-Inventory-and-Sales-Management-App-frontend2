import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/store_header_widget.dart';
import '../../providers/store_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/sales_service.dart';
import '../../services/inventory_service.dart';
import '../../services/customer_service.dart';
import '../../models/analytics_model.dart';

/// Premium Manager Analytics Hub
/// 4-tab comprehensive analytics: Overview, Sales Trends, Top Products, Customer Segments.
/// Pulls real-time Firestore data via AnalyticsService.
class ManagerAnalyticsHubScreen extends StatefulWidget {
  const ManagerAnalyticsHubScreen({super.key});

  @override
  State<ManagerAnalyticsHubScreen> createState() =>
      _ManagerAnalyticsHubScreenState();
}

class _ManagerAnalyticsHubScreenState extends State<ManagerAnalyticsHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AnalyticsService _analytics;

  String _selectedPeriod = 'Last 30 Days';
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 29));
  DateTime _toDate = DateTime.now();

  // Loaded data
  bool _loading = false;
  SalesSummary? _summary;
  List<SalesTrend> _trend = [];
  List<ProductPerformance> _products = [];
  List<CustomerInsight> _customers = [];

  final _fmt = NumberFormat('#,##,##0', 'en_IN');
  final _fmtDec = NumberFormat('#,##,##0.00', 'en_IN');

  static const _periods = [
    'Today',
    'Last 7 Days',
    'Last 30 Days',
    'This Month',
    'Last 3 Months',
  ];

  static const _tabTitles = ['Overview', 'Sales Trend', 'Products', 'Customers'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _analytics = AnalyticsService(
      SalesService(InventoryService(), CustomerService()),
      InventoryService(),
      CustomerService(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _setPeriod(String period) {
    final now = DateTime.now();
    DateTime from;
    switch (period) {
      case 'Today':
        from = DateTime(now.year, now.month, now.day);
        break;
      case 'Last 7 Days':
        from = now.subtract(const Duration(days: 6));
        break;
      case 'Last 30 Days':
        from = now.subtract(const Duration(days: 29));
        break;
      case 'This Month':
        from = DateTime(now.year, now.month, 1);
        break;
      case 'Last 3 Months':
        from = now.subtract(const Duration(days: 89));
        break;
      default:
        from = now.subtract(const Duration(days: 29));
    }
    setState(() {
      _selectedPeriod = period;
      _fromDate = from;
      _toDate = now;
    });
    _loadData();
  }

  Future<void> _loadData() async {
    final storeId = context.read<StoreProvider>().selectedStore?.id;
    if (storeId == null) return;
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _analytics.getSalesSummary(
            storeIds: [storeId], from: _fromDate, to: _toDate),
        _analytics.getDailySalesTrend(
            storeId: storeId, from: _fromDate, to: _toDate),
        _analytics.getProductPerformance(
            storeId: storeId, from: _fromDate, to: _toDate, limit: 15),
        _analytics.getCustomerInsights(from: _fromDate, to: _toDate),
      ]);
      if (mounted) {
        setState(() {
          _summary = results[0] as SalesSummary;
          _trend = results[1] as List<SalesTrend>;
          _products = results[2] as List<ProductPerformance>;
          _customers = results[3] as List<CustomerInsight>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            StoreHeaderWidget(
              title: 'Analytics Hub',
              subtitle: 'INTELLIGENCE CENTRE • Data-Driven Decisions',
              onNotificationTap: () =>
                  context.go('/manager/notifications'),
            ),

            // Hero banner + period pills
            _buildHeroBanner(),

            // Period pills
            _buildPeriodPills(),

            // TabBar
            _buildTabBar(),

            // Content
            Expanded(
              child: _loading
                  ? _buildLoadingState()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(),
                        _buildTrendTab(),
                        _buildProductsTab(),
                        _buildCustomersTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HERO BANNER
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildHeroBanner() {
    final revenue = _summary?.totalRevenue ?? 0;
    final txns = _summary?.totalTransactions ?? 0;
    final avg = _summary?.averageTransactionValue ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFF9333EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.32),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                child: const Icon(Icons.auto_graph_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Analytics Intelligence',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                    Text(
                      _selectedPeriod,
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.8)),
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
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.refresh_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 3-stat strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _heroBannerStat(
                    '₹${_fmt.format(revenue)}',
                    'Revenue',
                    Icons.currency_rupee_rounded,
                    const Color(0xFFA5F3FC)),
                Container(
                    width: 1,
                    height: 32,
                    color: Colors.white.withValues(alpha: 0.2)),
                _heroBannerStat(
                    '$txns',
                    'Transactions',
                    Icons.receipt_long_rounded,
                    const Color(0xFFC4B5FD)),
                Container(
                    width: 1,
                    height: 32,
                    color: Colors.white.withValues(alpha: 0.2)),
                _heroBannerStat(
                    '₹${_fmt.format(avg)}',
                    'Avg Basket',
                    Icons.shopping_bag_rounded,
                    const Color(0xFFFDE68A)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroBannerStat(
      String value, String label, IconData icon, Color iconColor) {
    return Column(
      children: [
        Icon(icon, size: 13, color: iconColor),
        const SizedBox(height: 3),
        Text(value,
            style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        Text(label,
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 9,
                color: Colors.white.withValues(alpha: 0.75))),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // PERIOD PILLS
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildPeriodPills() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: _periods.map((p) {
            final selected = _selectedPeriod == p;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => _setPeriod(p),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF7C3AED)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF7C3AED)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    p,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11.5,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      color:
                          selected ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TABBAR
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(3),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 1)),
            ],
          ),
          labelColor: const Color(0xFF0F172A),
          unselectedLabelColor: const Color(0xFF64748B),
          labelStyle: const TextStyle(
              fontFamily: 'Poppins', fontSize: 11.5, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(
              fontFamily: 'Poppins', fontSize: 11.5, fontWeight: FontWeight.w500),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          tabs: _tabTitles.map((t) => Tab(text: t)).toList(),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // LOADING STATE
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Color(0xFF7C3AED)),
          const SizedBox(height: 16),
          Text(
            'Loading analytics...',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TAB 1: OVERVIEW
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildOverviewTab() {
    if (_summary == null) return _buildEmptyState('No data for selected period');

    final itemsSold = _summary!.totalItemsSold;
    final topCategory = _summary!.revenueByCategory.isNotEmpty
        ? (_summary!.revenueByCategory.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .first
            .key
        : 'N/A';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // KPI Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.55,
            children: [
              _kpiCard(
                label: 'Total Revenue',
                value: '₹${_fmt.format(_summary!.totalRevenue)}',
                icon: Icons.currency_rupee_rounded,
                color: const Color(0xFF10B981),
                badge: 'Gross Sales',
              ),
              _kpiCard(
                label: 'Transactions',
                value: '${_summary!.totalTransactions}',
                icon: Icons.receipt_long_rounded,
                color: const Color(0xFF2563EB),
                badge: 'Bills Issued',
              ),
              _kpiCard(
                label: 'Avg Basket',
                value: '₹${_fmt.format(_summary!.averageTransactionValue)}',
                icon: Icons.shopping_basket_rounded,
                color: const Color(0xFF8B5CF6),
                badge: 'Per Customer',
              ),
              _kpiCard(
                label: 'Units Sold',
                value: '$itemsSold',
                icon: Icons.inventory_2_rounded,
                color: const Color(0xFFF59E0B),
                badge: 'Stock Moved',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Top category callout
          _calloutCard(
            icon: Icons.star_rounded,
            iconColor: const Color(0xFFF59E0B),
            bg: const Color(0xFFFFFBEB),
            border: const Color(0xFFFDE68A),
            title: 'Top Category This Period',
            body: topCategory,
            sub:
                '₹${_fmtDec.format(_summary!.revenueByCategory[topCategory] ?? 0)} in revenue',
          ),
          const SizedBox(height: 12),

          // Payment breakdown
          if (_summary!.revenueByPaymentMode.isNotEmpty)
            _breakdownCard(
              title: 'Revenue by Payment Mode',
              icon: Icons.account_balance_wallet_rounded,
              data: _summary!.revenueByPaymentMode,
            ),
          const SizedBox(height: 12),

          // Category breakdown
          if (_summary!.revenueByCategory.isNotEmpty)
            _breakdownCard(
              title: 'Revenue by Category',
              icon: Icons.category_rounded,
              data: _summary!.revenueByCategory,
            ),
          const SizedBox(height: 12),

          // Quick links
          Row(
            children: [
              Expanded(
                child: _quickLinkTile(
                  'Restocking',
                  'Manage Low Stock',
                  Icons.autorenew_rounded,
                  const Color(0xFF059669),
                  () => context.go('/manager/restocking'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _quickLinkTile(
                  'Festival Demand',
                  'Surge Planning',
                  Icons.celebration_rounded,
                  const Color(0xFFD97706),
                  () => context.go('/manager/festivals'),
                ),
              ),
            ],
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
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(badge,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 8.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const Spacer(),
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 9.5,
                  letterSpacing: 0.4,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  Widget _calloutCard({
    required IconData icon,
    required Color iconColor,
    required Color bg,
    required Color border,
    required String title,
    required String body,
    required String sub,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10.5,
                        color: Color(0xFF64748B))),
                Text(body,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A))),
                Text(sub,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10.5,
                        color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _breakdownCard({
    required String title,
    required IconData icon,
    required Map<String, double> data,
  }) {
    final sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = sorted.isNotEmpty ? sorted.first.value : 1.0;

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
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: const Color(0xFF7C3AED)),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A))),
          ]),
          const SizedBox(height: 12),
          ...sorted.take(6).map((e) {
            final pct = maxVal > 0 ? (e.value / maxVal) : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                          child: Text(e.key,
                              style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF334155)),
                              overflow: TextOverflow.ellipsis)),
                      Text('₹${_fmt.format(e.value)}',
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A))),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct.clamp(0.05, 1.0),
                      minHeight: 5,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF7C3AED)),
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

  Widget _quickLinkTile(String title, String sub, IconData icon, Color color,
      VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A))),
                  Text(sub,
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          color: Color(0xFF64748B))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TAB 2: SALES TREND LINE CHART
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildTrendTab() {
    if (_trend.isEmpty) {
      return _buildEmptyState('No sales trend data available');
    }

    final spots = _trend
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.revenue))
        .toList();
    final maxY = _trend.fold<double>(
        0, (m, t) => t.revenue > m ? t.revenue : m);
    final dateFmt = DateFormat('d MMM');

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Chart card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.show_chart_rounded,
                        color: Color(0xFF7C3AED), size: 18),
                    const SizedBox(width: 8),
                    const Text('Daily Revenue Trend',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A))),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: const Color(0xFFF5F3FF),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        '${_trend.length} days',
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: Color(0xFF7C3AED),
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 220,
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: maxY * 1.2,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: const Color(0xFFF1F5F9),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 52,
                            getTitlesWidget: (val, meta) {
                              if (val == 0) return const Text('');
                              return Text(
                                '₹${_fmt.format(val ~/ 1000)}K',
                                style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 9,
                                    color: Color(0xFF94A3B8)),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: (_trend.length / 4).ceilToDouble(),
                            getTitlesWidget: (val, meta) {
                              final idx = val.toInt();
                              if (idx < 0 || idx >= _trend.length) {
                                return const Text('');
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  dateFmt.format(_trend[idx].date),
                                  style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 9,
                                      color: Color(0xFF94A3B8)),
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          curveSmoothness: 0.35,
                          color: const Color(0xFF7C3AED),
                          barWidth: 3,
                          dotData: FlDotData(
                            show: _trend.length <= 14,
                            getDotPainter: (spot, pct, bar, idx) =>
                                FlDotCirclePainter(
                              radius: 4,
                              color: const Color(0xFF7C3AED),
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF7C3AED).withValues(alpha: 0.18),
                                const Color(0xFF7C3AED).withValues(alpha: 0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Daily summary cards (last 7)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Recent Days',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A))),
                const SizedBox(height: 12),
                ...(_trend.reversed.take(7).map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('EEE, d MMM').format(t.date),
                            style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: Color(0xFF334155),
                                fontWeight: FontWeight.w500),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                    color: const Color(0xFFF5F3FF),
                                    borderRadius: BorderRadius.circular(5)),
                                child: Text(
                                  '${t.transactions} txns',
                                  style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 10,
                                      color: Color(0xFF7C3AED),
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '₹${_fmt.format(t.revenue)}',
                                style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF10B981)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TAB 3: TOP PRODUCTS BAR CHART
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildProductsTab() {
    if (_products.isEmpty) {
      return _buildEmptyState('No product performance data');
    }

    final top10 = _products.take(10).toList();
    final maxQty = top10.fold<int>(0, (m, p) => p.quantitySold > m ? p.quantitySold : m);

    const barColors = [
      Color(0xFF7C3AED),
      Color(0xFF8B5CF6),
      Color(0xFFA78BFA),
      Color(0xFF6D28D9),
      Color(0xFF4C1D95),
      Color(0xFF5B21B6),
      Color(0xFF7C3AED),
      Color(0xFF8B5CF6),
      Color(0xFFA78BFA),
      Color(0xFF6D28D9),
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bar chart
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.bar_chart_rounded,
                      color: Color(0xFF7C3AED), size: 18),
                  const SizedBox(width: 8),
                  const Text('Top Products by Units Sold',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A))),
                ]),
                const SizedBox(height: 20),
                SizedBox(
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      maxY: maxQty * 1.3,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => FlLine(
                            color: const Color(0xFFF1F5F9), strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              final idx = val.toInt();
                              if (idx < 0 || idx >= top10.length) {
                                return const Text('');
                              }
                              final name = top10[idx].productName;
                              final short = name.length > 6
                                  ? '${name.substring(0, 6)}.'
                                  : name;
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(short,
                                    style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 8,
                                        color: Color(0xFF94A3B8))),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (val, meta) => Text(
                              val.toInt().toString(),
                              style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 9,
                                  color: Color(0xFF94A3B8)),
                            ),
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      barGroups: top10.asMap().entries.map((e) {
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: e.value.quantitySold.toDouble(),
                              color: barColors[e.key % barColors.length],
                              width: 16,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(5)),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Product list
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: top10.asMap().entries.map((e) {
                final rank = e.key + 1;
                final p = e.value;
                final isTop3 = rank <= 3;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: e.key < top10.length - 1
                        ? const Border(
                            bottom:
                                BorderSide(color: Color(0xFFF1F5F9), width: 1))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isTop3
                              ? const Color(0xFF7C3AED)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('#$rank',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isTop3
                                    ? Colors.white
                                    : const Color(0xFF64748B))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.productName,
                                style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A))),
                            Text(p.category.toUpperCase(),
                                style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 9.5,
                                    color: Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: const Color(0xFFF5F3FF),
                                borderRadius: BorderRadius.circular(5)),
                            child: Text('${p.quantitySold} sold',
                                style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 10,
                                    color: Color(0xFF7C3AED),
                                    fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(height: 2),
                          Text('₹${_fmt.format(p.revenue)}',
                              style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TAB 4: CUSTOMERS
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildCustomersTab() {
    if (_customers.isEmpty) {
      return _buildEmptyState(
          'No customer data available.\nComplete some sales to see insights.');
    }

    // Segment counts
    final segments = <String, int>{
      'VIP': 0,
      'Loyal': 0,
      'Regular': 0,
      'Occasional': 0,
    };
    for (final c in _customers) {
      segments[c.segment] = (segments[c.segment] ?? 0) + 1;
    }

    const segColors = {
      'VIP': Color(0xFFF59E0B),
      'Loyal': Color(0xFF10B981),
      'Regular': Color(0xFF2563EB),
      'Occasional': Color(0xFF94A3B8),
    };

    final top5 = _customers.take(5).toList();
    final totalSpend = _customers.fold<double>(0, (s, c) => s + c.totalSpend);
    final avgSpend =
        _customers.isNotEmpty ? totalSpend / _customers.length : 0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Segment pie chart card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.donut_large_rounded,
                      color: Color(0xFF7C3AED), size: 18),
                  const SizedBox(width: 8),
                  const Text('Customer Segments',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A))),
                  const Spacer(),
                  Text('${_customers.length} customers',
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          color: Color(0xFF64748B))),
                ]),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Pie chart
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 160,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 3,
                            centerSpaceRadius: 40,
                            sections: segments.entries
                                .where((e) => e.value > 0)
                                .map((e) {
                              final pct = e.value / _customers.length * 100;
                              return PieChartSectionData(
                                color: segColors[e.key] ??
                                    const Color(0xFF94A3B8),
                                value: e.value.toDouble(),
                                title:
                                    '${pct.toStringAsFixed(0)}%',
                                radius: 45,
                                titleStyle: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Legend
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: segments.entries.map((e) {
                          final color =
                              segColors[e.key] ?? const Color(0xFF94A3B8);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(e.key,
                                          style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF334155))),
                                      Text('${e.value} customers',
                                          style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 9,
                                              color: Color(0xFF94A3B8))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // KPI summary row
          Row(
            children: [
              Expanded(
                child: _miniStatCard(
                  '${_customers.length}',
                  'Active Customers',
                  Icons.people_alt_rounded,
                  const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _miniStatCard(
                  '₹${_fmt.format(avgSpend)}',
                  'Avg Spend / Customer',
                  Icons.wallet_rounded,
                  const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Top 5 customers
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.military_tech_rounded,
                      color: Color(0xFFF59E0B), size: 18),
                  const SizedBox(width: 8),
                  const Text('Top 5 Customers by Spend',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A))),
                ]),
                const SizedBox(height: 12),
                ...top5.asMap().entries.map((e) {
                  final rank = e.key + 1;
                  final c = e.value;
                  final segColor = segColors[c.segment] ?? const Color(0xFF94A3B8);
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: e.key < top5.length - 1
                        ? const BoxDecoration(
                            border: Border(
                                bottom: BorderSide(
                                    color: Color(0xFFF1F5F9), width: 1)))
                        : null,
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: rank == 1
                                ? const Color(0xFFFEF3C7)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text('#$rank',
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: rank == 1
                                      ? const Color(0xFFD97706)
                                      : const Color(0xFF64748B))),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: segColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                              c.customerName.isNotEmpty
                                  ? c.customerName[0].toUpperCase()
                                  : 'C',
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: segColor)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.customerName,
                                  style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A))),
                              Text(c.phone,
                                  style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 10,
                                      color: Color(0xFF94A3B8))),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: segColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(5)),
                              child: Text(c.segment,
                                  style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: segColor)),
                            ),
                            const SizedBox(height: 2),
                            Text('₹${_fmt.format(c.totalSpend)}',
                                style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A))),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Navigate to full customer analytics
          ElevatedButton.icon(
            onPressed: () => context.go('/manager/customer-analytics'),
            icon: const Icon(Icons.people_alt_rounded, size: 16),
            label: const Text('Full Customer Analytics →'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStatCard(
      String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A))),
                Text(label,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart_rounded, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: Colors.grey.shade500),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF7C3AED),
              side: const BorderSide(color: Color(0xFF7C3AED)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(
                  fontFamily: 'Poppins', fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
