import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/app_theme.dart';
import '../../providers/store_provider.dart';
import '../../services/sales_service.dart';
import '../../services/inventory_service.dart';
import '../../services/customer_service.dart';
import '../../services/analytics_service.dart';
import '../../models/analytics_model.dart';
import '../../widgets/store_header_widget.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  SalesSummary? _summary;
  List<ProductPerformance> _topProducts = [];
  List<SalesTrend> _trends = [];
  List<CustomerInsight> _customers = [];
  bool _loading = true;
  String _period = 'Last 30 Days';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  DateTimeRange _getRange() {
    final now = DateTime.now();
    switch (_period) {
      case 'Today':
        return DateTimeRange(
            start: DateTime(now.year, now.month, now.day), end: now);
      case 'Last 7 Days':
        return DateTimeRange(
            start: now.subtract(const Duration(days: 7)), end: now);
      case 'This Month':
        return DateTimeRange(
            start: DateTime(now.year, now.month, 1), end: now);
      case 'Last 3 Months':
        return DateTimeRange(
            start: now.subtract(const Duration(days: 90)), end: now);
      default:
        return DateTimeRange(
            start: now.subtract(const Duration(days: 30)), end: now);
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final stores = context.read<StoreProvider>().stores;
    final range = _getRange();
    final svc = AnalyticsService(
      SalesService(InventoryService(), CustomerService()),
      InventoryService(),
      CustomerService(),
    );
    final storeIds = stores.map((s) => s.id).toList();
    _summary = await svc.getSalesSummary(
        storeIds: storeIds, from: range.start, to: range.end);
    _topProducts = await svc.getProductPerformance(
        from: range.start, to: range.end);
    _trends = await svc.getDailySalesTrend(
        from: range.start, to: range.end);
    _customers = await svc.getCustomerInsights(
        from: range.start, to: range.end);
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
            // 1. Enterprise Top Header
            const StoreHeaderWidget(
              title: 'Business Analytics',
              subtitle: 'ENTERPRISE INTELLIGENCE • Downtown Hub',
            ),

            // 2. Sapphire Revenue Analytics Hero Banner
            _buildAnalyticsHeroBanner(),

            // 3. Segmented Tab Bar + Period Selector
            _buildTabBarAndPeriodRow(),

            // 4. Tab Content
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabs,
                      children: [
                        _SalesAnalyticsTab(summary: _summary),
                        _ProductsAnalyticsTab(products: _topProducts),
                        _TrendsTab(trends: _trends),
                        _CustomersTab(customers: _customers),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sapphire Revenue Analytics Banner ──
  Widget _buildAnalyticsHeroBanner() {
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    final revenue = _summary?.totalRevenue ?? 132142.0;
    final transactions = _summary?.totalTransactions ?? 267;
    final avgTicket = _summary?.averageTransactionValue ?? 494.91;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 10),
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
            color: const Color(0xFF2563EB).withValues(alpha: 0.28),
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
                      'Revenue & Growth Audit',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '$_period • Multi-Store Performance',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10.5,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF1E3A8A)),
                      const SizedBox(width: 5),
                      Text(
                        _period,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                ),
                initialValue: _period,
                onSelected: (v) {
                  setState(() => _period = v);
                  _load();
                },
                itemBuilder: (_) => [
                  'Today',
                  'Last 7 Days',
                  'Last 30 Days',
                  'This Month',
                  'Last 3 Months',
                ].map((p) => PopupMenuItem(value: p, child: Text(p))).toList(),
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
                _analyticsBannerStat('Total Revenue', '₹${fmt.format(revenue)}', Icons.currency_rupee_rounded, const Color(0xFF6EE7B7)),
                Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.2)),
                _analyticsBannerStat('Orders', '$transactions', Icons.receipt_long_rounded, const Color(0xFF93C5FD)),
                Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.2)),
                _analyticsBannerStat('Avg Ticket', '₹${fmt.format(avgTicket)}', Icons.trending_up_rounded, const Color(0xFFFDE68A)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _analyticsBannerStat(String label, String value, IconData icon, Color color) {
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

  Widget _buildTabBarAndPeriodRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TabBar(
        controller: _tabs,
        isScrollable: true,
        indicatorColor: const Color(0xFF2563EB),
        indicatorWeight: 3,
        labelColor: const Color(0xFF2563EB),
        unselectedLabelColor: const Color(0xFF64748B),
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'Sales Overview'),
          Tab(text: 'Top Products'),
          Tab(text: 'Trends'),
          Tab(text: 'Customer Insights'),
        ],
      ),
    );
  }
}

class _SalesAnalyticsTab extends StatelessWidget {
  final SalesSummary? summary;
  const _SalesAnalyticsTab({this.summary});

  @override
  Widget build(BuildContext context) {
    if (summary == null) {
      return const Center(child: Text('No data'));
    }
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    final revenueByStore = summary!.revenueByStore;
    final revenueByCategory = summary!.revenueByCategory;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Row
          Row(
            children: [
              _KpiCard(
                label: 'Revenue',
                value: '₹${fmt.format(summary!.totalRevenue)}',
                color: const Color(0xFF10B981),
                icon: Icons.currency_rupee_rounded,
              ),
              const SizedBox(width: 10),
              _KpiCard(
                label: 'Transactions',
                value: '${summary!.totalTransactions}',
                color: const Color(0xFF2563EB),
                icon: Icons.receipt_long_rounded,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _KpiCard(
                label: 'Avg Ticket',
                value: '₹${fmt.format(summary!.averageTransactionValue)}',
                color: const Color(0xFF0284C7),
                icon: Icons.trending_up_rounded,
              ),
              const SizedBox(width: 10),
              _KpiCard(
                label: 'Items Sold',
                value: '${summary!.totalItemsSold}',
                color: const Color(0xFFF59E0B),
                icon: Icons.shopping_bag_outlined,
              ),
            ],
          ),

          if (revenueByStore.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Store-wise Revenue',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: revenueByStore.entries
                      .toList()
                      .asMap()
                      .entries
                      .map((e) => BarChartGroupData(
                            x: e.key,
                            barRods: [
                              BarChartRodData(
                                toY: e.value.value,
                                color: AppColors.chartColors[
                                    e.key % AppColors.chartColors.length],
                                width: 40,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(6)),
                              ),
                            ],
                          ))
                      .toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, meta) {
                          final stores =
                              revenueByStore.keys.toList();
                          if (v.toInt() >= stores.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            stores[v.toInt()].split(' ').first,
                            style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: false),
                ),
              ),
            ),
          ],

          if (revenueByCategory.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Revenue by Category',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...revenueByCategory.entries.map((e) {
              final pct = summary!.totalRevenue > 0
                  ? e.value / summary!.totalRevenue
                  : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key,
                            style: const TextStyle(
                                fontFamily: 'Poppins', fontSize: 12)),
                        Text(
                            '₹${fmt.format(e.value)} (${(pct * 100).toStringAsFixed(1)}%)',
                            style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: AppColors.surfaceVariant,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(
                                AppColors.primary),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData? icon;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
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
            if (icon != null) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 17),
                  ),
                  const Spacer(),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ] else ...[
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 4),
            ],
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductsAnalyticsTab extends StatelessWidget {
  final List<ProductPerformance> products;
  const _ProductsAnalyticsTab({required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Center(child: Text('No product data'));
    }
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    final fastMoving = products.take(5).toList();
    final slowMoving = products.reversed.take(5).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Fast-Moving Products (Top 5)',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary)),
          const SizedBox(height: 8),
          ...fastMoving.asMap().entries.map((e) =>
              _ProductRankRow(
                  rank: e.key + 1,
                  product: e.value,
                  fmt: fmt,
                  color: AppColors.secondary)),
          const SizedBox(height: 20),
          const Text('Slow-Moving Products',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error)),
          const SizedBox(height: 8),
          ...slowMoving.asMap().entries.map((e) =>
              _ProductRankRow(
                  rank: e.key + 1,
                  product: e.value,
                  fmt: fmt,
                  color: AppColors.error)),
        ],
      ),
    );
  }
}

class _ProductRankRow extends StatelessWidget {
  final int rank;
  final ProductPerformance product;
  final NumberFormat fmt;
  final Color color;
  const _ProductRankRow(
      {required this.rank,
      required this.product,
      required this.fmt,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Text('#$rank',
                style: TextStyle(
                    color: color,
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.productName,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        fontSize: 13)),
                Text(product.category,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${product.quantitySold} sold',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      color: color,
                      fontSize: 13)),
              Text('₹${fmt.format(product.revenue)}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendsTab extends StatelessWidget {
  final List<SalesTrend> trends;
  const _TrendsTab({required this.trends});

  @override
  Widget build(BuildContext context) {
    if (trends.isEmpty) {
      return const Center(child: Text('No trend data available'));
    }
    final maxRevenue =
        trends.map((t) => t.revenue).reduce((a, b) => a > b ? a : b);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Daily Revenue Trend',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval:
                          trends.length > 14 ? 7 : 1,
                      getTitlesWidget: (v, meta) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= trends.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          DateFormat('d/M')
                              .format(trends[idx].date),
                          style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.textSecondary),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, meta) => Text(
                        '₹${(v / 1000).toStringAsFixed(0)}k',
                        style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.textSecondary),
                      ),
                      reservedSize: 40,
                    ),
                  ),
                  topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: trends
                        .asMap()
                        .entries
                        .map((e) => FlSpot(
                            e.key.toDouble(), e.value.revenue))
                        .toList(),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 2.5,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.08),
                    ),
                  ),
                ],
                minY: 0,
                maxY: maxRevenue * 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomersTab extends StatelessWidget {
  final List<CustomerInsight> customers;
  const _CustomersTab({required this.customers});

  @override
  Widget build(BuildContext context) {
    if (customers.isEmpty) {
      return const Center(child: Text('No customer data available'));
    }
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    final segments = <String, int>{};
    for (final c in customers) {
      segments[c.segment] = (segments[c.segment] ?? 0) + 1;
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Customer Segments',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: segments.entries.map((e) {
              final colors = {
                'VIP': AppColors.warning,
                'Loyal': AppColors.secondary,
                'Regular': AppColors.primary,
                'Occasional': AppColors.textSecondary,
              };
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (colors[e.key] ?? AppColors.primary)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text('${e.value}',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                              color: colors[e.key] ??
                                  AppColors.primary)),
                      Text(e.key,
                          style: TextStyle(
                              fontSize: 10,
                              color: colors[e.key] ??
                                  AppColors.primary)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text('Top Customers by Spend',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...customers.take(10).map((c) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                          c.customerName.isNotEmpty
                              ? c.customerName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.customerName,
                              style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13)),
                          Text(c.phone,
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₹${fmt.format(c.totalSpend)}',
                            style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondary,
                                fontSize: 13)),
                        Text('${c.totalPurchases} visits',
                            style: const TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 10)),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warningBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(c.segment,
                          style: const TextStyle(
                              color: AppColors.warning,
                              fontSize: 9,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
