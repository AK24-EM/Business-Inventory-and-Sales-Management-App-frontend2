import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/app_constants.dart';
import '../../models/sale_model.dart';
import '../../models/product_model.dart';
import '../../providers/store_provider.dart';
import '../../services/sales_service.dart';
import '../../services/customer_service.dart';
import '../../services/inventory_service.dart';

/// Comprehensive Sales Analytics Screen with charts and insights
/// Accessible by Manager and Owner roles
class SalesAnalyticsScreen extends StatefulWidget {
  const SalesAnalyticsScreen({super.key});

  @override
  State<SalesAnalyticsScreen> createState() => _SalesAnalyticsScreenState();
}

class _SalesAnalyticsScreenState extends State<SalesAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late SalesService _salesService;

  // Period selection
  String _selectedPeriod = 'Last 7 Days';
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 6));
  DateTime _toDate = DateTime.now();

  // Data
  List<SaleModel> _sales = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _salesService = SalesService(
      context.read<InventoryService>(),
      context.read<CustomerService>(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final storeId = context.read<StoreProvider>().selectedStore?.id;
    if (storeId == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sales = await _salesService.getSalesByStore(
        storeId,
        _fromDate,
        _toDate,
      );
      if (mounted) {
        setState(() {
          _sales = sales;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _selectPeriod(String period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    setState(() {
      _selectedPeriod = period;
      switch (period) {
        case 'Today':
          _fromDate = today;
          _toDate = now;
          break;
        case 'Last 7 Days':
          _fromDate = today.subtract(const Duration(days: 6));
          _toDate = now;
          break;
        case 'Last 30 Days':
          _fromDate = today.subtract(const Duration(days: 29));
          _toDate = now;
          break;
        case 'This Month':
          _fromDate = DateTime(now.year, now.month, 1);
          _toDate = now;
          break;
        case 'Last 3 Months':
          _fromDate = DateTime(now.year, now.month - 3, 1);
          _toDate = now;
          break;
      }
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sales Analytics'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.analytics_outlined), text: 'Overview'),
            Tab(icon: Icon(Icons.trending_up), text: 'Trends'),
            Tab(icon: Icon(Icons.category_outlined), text: 'Products'),
            Tab(icon: Icon(Icons.schedule_outlined), text: 'Time Analysis'),
          ],
        ),
      ),
      body: Column(
        children: [
          _PeriodSelector(
            selected: _selectedPeriod,
            onSelect: _selectPeriod,
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _ErrorView(error: _error!, onRetry: _loadData)
                    : _sales.isEmpty
                        ? const _EmptyView()
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              _OverviewTab(sales: _sales),
                              _TrendsTab(
                                sales: _sales,
                                fromDate: _fromDate,
                                toDate: _toDate,
                              ),
                              _ProductsTab(sales: _sales),
                              _TimeAnalysisTab(sales: _sales),
                            ],
                          ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Period Selector
// ══════════════════════════════════════════════════════════════════════════════

class _PeriodSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _PeriodSelector({
    required this.selected,
    required this.onSelect,
  });

  static const _periods = [
    'Today',
    'Last 7 Days',
    'Last 30 Days',
    'This Month',
    'Last 3 Months',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      color: AppColors.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _periods.length,
        itemBuilder: (context, index) {
          final period = _periods[index];
          final isSelected = selected == period;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => onSelect(period),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  period,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Overview Tab
// ══════════════════════════════════════════════════════════════════════════════

class _OverviewTab extends StatelessWidget {
  final List<SaleModel> sales;

  const _OverviewTab({required this.sales});

  @override
  Widget build(BuildContext context) {
    final totalRevenue = sales.fold<double>(0, (sum, s) => sum + s.totalAmount);
    final totalTransactions = sales.length;
    final totalItems = sales.fold<int>(0, (sum, s) => sum + s.itemCount);
    final averageTicket = totalTransactions > 0 ? totalRevenue / totalTransactions : 0;

    // Payment breakdown
    final cashSales = sales.where((s) => s.paymentMode == PaymentMode.cash).length;
    final upiSales = sales.where((s) => s.paymentMode == PaymentMode.upi).length;
    final cardSales = sales.where((s) => s.paymentMode == PaymentMode.card).length;

    final cashRevenue = sales
        .where((s) => s.paymentMode == PaymentMode.cash)
        .fold<double>(0, (sum, s) => sum + s.totalAmount);
    final upiRevenue = sales
        .where((s) => s.paymentMode == PaymentMode.upi)
        .fold<double>(0, (sum, s) => sum + s.totalAmount);
    final cardRevenue = sales
        .where((s) => s.paymentMode == PaymentMode.card)
        .fold<double>(0, (sum, s) => sum + s.totalAmount);

    return RefreshIndicator(
      onRefresh: () async {},
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Key Metrics Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _MetricCard(
                  title: 'Total Revenue',
                  value: NumberFormat.currency(symbol: '₹', decimalDigits: 0)
                      .format(totalRevenue),
                  icon: Icons.currency_rupee,
                  color: AppColors.secondary,
                ),
                _MetricCard(
                  title: 'Transactions',
                  value: '$totalTransactions',
                  icon: Icons.receipt_long,
                  color: AppColors.primary,
                ),
                _MetricCard(
                  title: 'Items Sold',
                  value: '$totalItems',
                  icon: Icons.shopping_bag_outlined,
                  color: AppColors.accent,
                ),
                _MetricCard(
                  title: 'Avg. Ticket',
                  value: NumberFormat.currency(symbol: '₹', decimalDigits: 0)
                      .format(averageTicket),
                  icon: Icons.account_balance_wallet,
                  color: AppColors.info,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Payment Method Breakdown
            const Text(
              'Payment Methods',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _PaymentMethodChart(
              cashSales: cashSales,
              upiSales: upiSales,
              cardSales: cardSales,
              cashRevenue: cashRevenue,
              upiRevenue: upiRevenue,
              cardRevenue: cardRevenue,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Payment Method Chart
// ══════════════════════════════════════════════════════════════════════════════

class _PaymentMethodChart extends StatelessWidget {
  final int cashSales;
  final int upiSales;
  final int cardSales;
  final double cashRevenue;
  final double upiRevenue;
  final double cardRevenue;

  const _PaymentMethodChart({
    required this.cashSales,
    required this.upiSales,
    required this.cardSales,
    required this.cashRevenue,
    required this.upiRevenue,
    required this.cardRevenue,
  });

  @override
  Widget build(BuildContext context) {
    final total = cashSales + upiSales + cardSales;
    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Pie Chart
          SizedBox(
            width: 120,
            height: 120,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 35,
                sections: [
                  if (cashSales > 0)
                    PieChartSectionData(
                      value: cashSales.toDouble(),
                      title: '${((cashSales / total) * 100).toStringAsFixed(0)}%',
                      color: AppColors.secondary,
                      radius: 35,
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  if (upiSales > 0)
                    PieChartSectionData(
                      value: upiSales.toDouble(),
                      title: '${((upiSales / total) * 100).toStringAsFixed(0)}%',
                      color: AppColors.primary,
                      radius: 35,
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  if (cardSales > 0)
                    PieChartSectionData(
                      value: cardSales.toDouble(),
                      title: '${((cardSales / total) * 100).toStringAsFixed(0)}%',
                      color: AppColors.accent,
                      radius: 35,
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Legend
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cashSales > 0)
                  _LegendItem(
                    color: AppColors.secondary,
                    label: 'Cash',
                    count: cashSales,
                    amount: cashRevenue,
                  ),
                if (upiSales > 0)
                  _LegendItem(
                    color: AppColors.primary,
                    label: 'UPI',
                    count: upiSales,
                    amount: upiRevenue,
                  ),
                if (cardSales > 0)
                  _LegendItem(
                    color: AppColors.accent,
                    label: 'Card',
                    count: cardSales,
                    amount: cardRevenue,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  final double amount;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.count,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$count txns • ${fmt.format(amount)}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Trends Tab
// ══════════════════════════════════════════════════════════════════════════════

class _TrendsTab extends StatelessWidget {
  final List<SaleModel> sales;
  final DateTime fromDate;
  final DateTime toDate;

  const _TrendsTab({
    required this.sales,
    required this.fromDate,
    required this.toDate,
  });

  @override
  Widget build(BuildContext context) {
    // Group sales by date
    final Map<String, double> dailyRevenue = {};
    final Map<String, int> dailyTransactions = {};

    for (final sale in sales) {
      final dateKey = DateFormat('MMM dd').format(sale.timestamp);
      dailyRevenue[dateKey] = (dailyRevenue[dateKey] ?? 0) + sale.totalAmount;
      dailyTransactions[dateKey] = (dailyTransactions[dateKey] ?? 0) + 1;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenue Trend',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _RevenueLineChart(
            dailyRevenue: dailyRevenue,
          ),
          const SizedBox(height: 24),
          const Text(
            'Transaction Trend',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _TransactionBarChart(
            dailyTransactions: dailyTransactions,
          ),
        ],
      ),
    );
  }
}

class _RevenueLineChart extends StatelessWidget {
  final Map<String, double> dailyRevenue;

  const _RevenueLineChart({required this.dailyRevenue});

  @override
  Widget build(BuildContext context) {
    if (dailyRevenue.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text('No data available'),
        ),
      );
    }

    final sortedEntries = dailyRevenue.entries.toList();
    final maxRevenue = dailyRevenue.values.reduce((a, b) => a > b ? a : b);

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxRevenue / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppColors.border,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return Text(
                    NumberFormat.compact().format(value),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < 0 || value.toInt() >= sortedEntries.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      sortedEntries[value.toInt()].key,
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (sortedEntries.length - 1).toDouble(),
          minY: 0,
          maxY: maxRevenue * 1.2,
          lineBarsData: [
            LineChartBarData(
              spots: sortedEntries.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.value);
              }).toList(),
              isCurved: true,
              color: AppColors.secondary,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.secondary.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionBarChart extends StatelessWidget {
  final Map<String, int> dailyTransactions;

  const _TransactionBarChart({required this.dailyTransactions});

  @override
  Widget build(BuildContext context) {
    if (dailyTransactions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text('No data available'),
        ),
      );
    }

    final sortedEntries = dailyTransactions.entries.toList();
    final maxTransactions = dailyTransactions.values.reduce((a, b) => a > b ? a : b);

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: BarChart(
        BarChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxTransactions / 5).ceilToDouble(),
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppColors.border,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < 0 || value.toInt() >= sortedEntries.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      sortedEntries[value.toInt()].key,
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: sortedEntries.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.value.toDouble(),
                  color: AppColors.primary,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Products Tab
// ══════════════════════════════════════════════════════════════════════════════

class _ProductsTab extends StatelessWidget {
  final List<SaleModel> sales;

  const _ProductsTab({required this.sales});

  @override
  Widget build(BuildContext context) {
    // Aggregate product sales
    final Map<String, ProductSalesSummary> productSales = {};

    for (final sale in sales) {
      for (final item in sale.items) {
        if (productSales.containsKey(item.productId)) {
          productSales[item.productId]!.quantity += item.quantity;
          productSales[item.productId]!.revenue += item.totalPrice;
        } else {
          productSales[item.productId] = ProductSalesSummary(
            productId: item.productId,
            productName: item.productName,
            quantity: item.quantity,
            revenue: item.totalPrice,
          );
        }
      }
    }

    final sortedProducts = productSales.values.toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));

    final topProducts = sortedProducts.take(10).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Selling Products',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...topProducts.asMap().entries.map((entry) {
            final index = entry.key;
            final product = entry.value;
            return _ProductRankCard(
              rank: index + 1,
              product: product,
            );
          }),
        ],
      ),
    );
  }
}

class ProductSalesSummary {
  final String productId;
  final String productName;
  int quantity;
  double revenue;

  ProductSalesSummary({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.revenue,
  });
}

class _ProductRankCard extends StatelessWidget {
  final int rank;
  final ProductSalesSummary product;

  const _ProductRankCard({
    required this.rank,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    
    Color getRankColor() {
      if (rank == 1) return Colors.amber;
      if (rank == 2) return Colors.grey.shade400;
      if (rank == 3) return Colors.brown.shade300;
      return AppColors.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: getRankColor().withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '#$rank',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: getRankColor(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${product.quantity} units sold',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Revenue
          Text(
            fmt.format(product.revenue),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Time Analysis Tab
// ══════════════════════════════════════════════════════════════════════════════

class _TimeAnalysisTab extends StatelessWidget {
  final List<SaleModel> sales;

  const _TimeAnalysisTab({required this.sales});

  @override
  Widget build(BuildContext context) {
    // Hourly breakdown
    final Map<int, int> hourlySales = {};
    final Map<int, double> hourlyRevenue = {};

    for (final sale in sales) {
      final hour = sale.timestamp.hour;
      hourlySales[hour] = (hourlySales[hour] ?? 0) + 1;
      hourlyRevenue[hour] = (hourlyRevenue[hour] ?? 0) + sale.totalAmount;
    }

    // Find peak hour
    int peakHour = 0;
    int maxSales = 0;
    hourlySales.forEach((hour, count) {
      if (count > maxSales) {
        maxSales = count;
        peakHour = hour;
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Peak hour card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.primaryGlow,
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule, color: Colors.white, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Peak Sales Hour',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${peakHour.toString().padLeft(2, '0')}:00 - ${(peakHour + 1).toString().padLeft(2, '0')}:00',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '$maxSales transactions',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Hourly Distribution',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _HourlyBarChart(hourlySales: hourlySales),
        ],
      ),
    );
  }
}

class _HourlyBarChart extends StatelessWidget {
  final Map<int, int> hourlySales;

  const _HourlyBarChart({required this.hourlySales});

  @override
  Widget build(BuildContext context) {
    if (hourlySales.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text('No data available'),
        ),
      );
    }

    final maxSales = hourlySales.values.reduce((a, b) => a > b ? a : b);

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: BarChart(
        BarChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxSales / 5).ceilToDouble(),
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppColors.border,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 2,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${value.toInt()}h',
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(24, (index) {
            final count = hourlySales[index] ?? 0;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: count.toDouble(),
                  color: AppColors.accent,
                  width: 10,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Error and Empty States
// ══════════════════════════════════════════════════════════════════════════════

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Error loading data',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insights_outlined, size: 64, color: AppColors.textTertiary),
            SizedBox(height: 16),
            Text(
              'No Sales Data',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'No sales found for the selected period',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
