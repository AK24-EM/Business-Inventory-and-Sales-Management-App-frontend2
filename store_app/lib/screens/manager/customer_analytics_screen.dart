import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/app_theme.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/loyalty_provider.dart';
import '../../providers/store_provider.dart';
import '../../services/loyalty_service.dart';
import '../../services/customer_service.dart';
import '../../models/analytics_model.dart';
import '../../models/customer_model.dart';
import '../../models/sale_model.dart';

class CustomerAnalyticsScreen extends StatefulWidget {
  const CustomerAnalyticsScreen({super.key});

  @override
  State<CustomerAnalyticsScreen> createState() =>
      _CustomerAnalyticsScreenState();
}

class _CustomerAnalyticsScreenState extends State<CustomerAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LoyaltyService _loyaltyService = LoyaltyService();
  final CustomerService _customerService = CustomerService();
  DateTime? _lastUpdateTime;
  
  String _selectedPeriod = 'Last 30 Days';
  final List<String> _periodOptions = const [
    'Today',
    'Last 7 Days',
    'Last 30 Days',
    'Last 3 Months',
    'All Time',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _lastUpdateTime = DateTime.now();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  DateTimeRange _getRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Today':
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: now,
        );
      case 'Last 7 Days':
        return DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );
      case 'Last 3 Months':
        return DateTimeRange(
          start: now.subtract(const Duration(days: 90)),
          end: now,
        );
      case 'All Time':
        return DateTimeRange(
          start: DateTime(2020, 1, 1),
          end: now,
        );
      default: // Last 30 Days
        return DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeId = context.watch<StoreProvider>().selectedStore?.id;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Customer Analytics'),
            if (_lastUpdateTime != null)
              Text(
                'Live • Last sync: ${DateFormat('HH:mm:ss').format(_lastUpdateTime!)}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: AppColors.success,
                ),
              ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard_outlined, size: 20)),
            Tab(text: 'Segments', icon: Icon(Icons.pie_chart_outline, size: 20)),
            Tab(text: 'Loyalty', icon: Icon(Icons.stars, size: 20)),
            Tab(text: 'Top Customers', icon: Icon(Icons.leaderboard, size: 20)),
          ],
        ),
        actions: [
          // Live sync indicator
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.date_range_outlined),
            initialValue: _selectedPeriod,
            onSelected: (v) {
              setState(() => _selectedPeriod = v);
            },
            itemBuilder: (_) => _periodOptions
                .map((p) => PopupMenuItem(value: p, child: Text(p)))
                .toList(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Force Refresh',
            onPressed: () {
              setState(() {
                _lastUpdateTime = DateTime.now();
              });
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(storeId),
          _buildSegmentsTab(storeId),
          _buildLoyaltyTab(storeId),
          _buildTopCustomersTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(String? storeId) {
    if (storeId == null || storeId.isEmpty) {
      return const Center(
        child: Text(
          'No store selected',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final analyticsProvider = context.read<AnalyticsProvider>();
    final range = _getRange();

    return StreamBuilder<List<CustomerModel>>(
      stream: _customerService.getStoreCustomersStream(storeId),
      builder: (context, customersSnapshot) {
        // Use the shared AnalyticsProvider stream — avoids duplicate listeners.
        return StreamBuilder<AnalyticsBundle>(
          stream: analyticsProvider.watchBundle(
            storeId: storeId,
            range: range,
          ),
          builder: (context, bundleSnapshot) {
            if (customersSnapshot.hasData || bundleSnapshot.hasData) {
              _lastUpdateTime = DateTime.now();
            }

            if (customersSnapshot.connectionState == ConnectionState.waiting &&
                !customersSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (customersSnapshot.hasError) {
              return Center(
                child: Text('Error: ${customersSnapshot.error}'),
              );
            }

            final customers = customersSnapshot.data ?? [];
            final sales = bundleSnapshot.data?.sales ?? [];

            // Calculate metrics
            final now = DateTime.now();
            final thisMonth = DateTime(now.year, now.month);
            final activeCustomers = _getActiveCustomers(customers, sales);
            final newThisMonth = customers
                .where((c) => !c.registeredAt.isBefore(thisMonth))
                .length;

            // Calculate average purchases from sales
            final customerPurchaseCounts = <String, int>{};
            for (final sale in sales) {
              if (sale.customerPhone != null) {
                customerPurchaseCounts[sale.customerPhone!] =
                    (customerPurchaseCounts[sale.customerPhone!] ?? 0) + 1;
              }
            }
            final avgPurchases = customerPurchaseCounts.isEmpty
                ? 0.0
                : customerPurchaseCounts.values.reduce((a, b) => a + b) /
                    customerPurchaseCounts.length;

            // Generate growth data
            final growthData = _calculateGrowthData(customers);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Real-time badge
                  _buildRealTimeBadge(),
                  const SizedBox(height: 16),

                  // Summary Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          'Total Customers',
                          customers.length.toString(),
                          Icons.people,
                          AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          'Active',
                          activeCustomers.toString(),
                          Icons.person_outline,
                          AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          'New This Month',
                          newThisMonth.toString(),
                          Icons.person_add,
                          AppColors.info,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          'Avg Purchases',
                          avgPurchases.toStringAsFixed(1),
                          Icons.shopping_bag,
                          AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Customer Growth Chart
                  _buildSectionHeader('Customer Growth'),
                  const SizedBox(height: 12),
                  _buildGrowthChart(growthData),
                  const SizedBox(height: 20),

                  // Recent Registrations
                  _buildSectionHeader('Recent Registrations'),
                  const SizedBox(height: 12),
                  _buildRecentCustomers(customers),

                  const SizedBox(height: 20),

                  // Purchase Frequency Distribution
                  _buildSectionHeader('Purchase Frequency'),
                  const SizedBox(height: 12),
                  _buildPurchaseFrequency(customerPurchaseCounts),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSegmentsTab(String? storeId) {
    if (storeId == null || storeId.isEmpty) {
      return const Center(
        child: Text(
          'No store selected',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final analyticsProvider = context.read<AnalyticsProvider>();
    final range = _getRange();

    return StreamBuilder<List<CustomerModel>>(
      stream: _customerService.getStoreCustomersStream(storeId),
      builder: (context, customersSnapshot) {
        // Reuse the same shared stream — no new Firestore listener opened.
        return StreamBuilder<AnalyticsBundle>(
          stream: analyticsProvider.watchBundle(
            storeId: storeId,
            range: range,
          ),
          builder: (context, bundleSnapshot) {
            if (customersSnapshot.connectionState == ConnectionState.waiting &&
                !customersSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final customers = customersSnapshot.data ?? [];
            final sales = bundleSnapshot.data?.sales ?? [];

            // Calculate customer segments
            final segments = _calculateCustomerSegments(customers, sales);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRealTimeBadge(),
                  const SizedBox(height: 16),

                  _buildSectionHeader('Customer Segmentation'),
                  const SizedBox(height: 12),

                  // VIP Customers
                  _buildSegmentCard(
                    'VIP Customers',
                    segments['vip']!.length,
                    const Color(0xFFD97706),
                    Icons.diamond_outlined,
                    '20+ orders or ₹10K+ spend',
                  ),
                  const SizedBox(height: 12),

                  // Loyal Customers
                  _buildSegmentCard(
                    'Loyal Customers',
                    segments['loyal']!.length,
                    AppColors.secondary,
                    Icons.favorite_border,
                    '10+ orders',
                  ),
                  const SizedBox(height: 12),

                  // Regular Customers
                  _buildSegmentCard(
                    'Regular Customers',
                    segments['regular']!.length,
                    AppColors.info,
                    Icons.person_outline,
                    '5-9 orders',
                  ),
                  const SizedBox(height: 12),

                  // Occasional Customers
                  _buildSegmentCard(
                    'Occasional Customers',
                    segments['occasional']!.length,
                    AppColors.textTertiary,
                    Icons.schedule,
                    '1-4 orders',
                  ),
                  const SizedBox(height: 12),

                  // At-Risk Customers (no orders in 60 days)
                  _buildSegmentCard(
                    'At-Risk Customers',
                    segments['atRisk']!.length,
                    AppColors.error,
                    Icons.warning_amber,
                    'No orders in 60+ days',
                  ),

                  const SizedBox(height: 24),
                  _buildSectionHeader('Top Spending Customers'),
                  const SizedBox(height: 12),
                  _buildTopSpenders(segments['vip']!, sales),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLoyaltyTab(String? storeId) {
    if (storeId == null || storeId.isEmpty) {
      return const Center(
        child: Text(
          'No store selected',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: _loyaltyService.getLoyaltyStats(storeId: storeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final stats = snapshot.data!;
        final totalAccounts = stats['totalAccounts'] as int;
        final activeAccounts = stats['activeAccounts'] as int;
        final totalIssued = stats['totalPointsIssued'] as int;
        final totalRedeemed = stats['totalPointsRedeemed'] as int;
        final redemptionRate = stats['redemptionRate'] as double;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Loyalty Stats
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Total Accounts',
                      totalAccounts.toString(),
                      Icons.card_giftcard,
                      AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'Active',
                      activeAccounts.toString(),
                      Icons.stars,
                      AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Points Issued',
                      NumberFormat.compact().format(totalIssued),
                      Icons.add_circle,
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'Points Redeemed',
                      NumberFormat.compact().format(totalRedeemed),
                      Icons.remove_circle,
                      AppColors.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Redemption Rate
              _buildSectionHeader('Redemption Rate'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.warning, Color(0xFFFFA726)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.warning.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.percent,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Redemption Rate',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${(redemptionRate * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 32,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '$totalRedeemed of $totalIssued points redeemed',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Transaction Breakdown
              _buildSectionHeader('Transaction Breakdown'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Earn Transactions',
                      stats['earnTransactions'].toString(),
                      AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Redeem Transactions',
                      stats['redeemTransactions'].toString(),
                      AppColors.error,
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

  Widget _buildTopCustomersTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: context.read<LoyaltyProvider>().getTopCustomers(limit: 50),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final customers = snapshot.data ?? [];

        if (customers.isEmpty) {
          return const Center(
            child: Text(
              'No customer data available',
              style: TextStyle(color: AppColors.textTertiary),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: customers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, index) {
            final data = customers[index];
            return _buildTopCustomerCard(index + 1, data);
          },
        );
      },
    );
  }

  Widget _buildMetricCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 28,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
    );
  }

  Widget _buildGrowthChart(List<MapEntry<String, int>> growthData) {
    if (growthData.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          'No data available',
          style: TextStyle(color: AppColors.textTertiary),
        ),
      );
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < growthData.length) {
                    return Text(
                      growthData[index].key,
                      style: const TextStyle(fontSize: 10),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: growthData
                  .asMap()
                  .entries
                  .map((e) =>
                      FlSpot(e.key.toDouble(), e.value.value.toDouble()))
                  .toList(),
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentCustomers(List<CustomerModel> customers) {
    if (customers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text(
            'No recent registrations',
            style: TextStyle(color: AppColors.textTertiary),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: customers.take(5).map((customer) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                customer.name[0].toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            title: Text(
              customer.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              customer.phone,
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Text(
              DateFormat('dd MMM').format(customer.registeredAt),
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 11,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopCustomerCard(int rank, Map<String, dynamic> data) {
    final name = data['name'] as String;
    final phone = data['phone'] as String;
    final totalPoints = data['totalPoints'] as int;
    final availablePoints = data['availablePoints'] as int;
    final redeemedPoints = data['redeemedPoints'] as int;

    Color rankColor;
    if (rank == 1) {
      rankColor = const Color(0xFFFFD700);
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0);
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32);
    } else {
      rankColor = AppColors.textTertiary;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: rankColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  phone,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildPointBadge('Total', totalPoints, AppColors.primary),
                    const SizedBox(width: 8),
                    _buildPointBadge(
                        'Available', availablePoints, AppColors.success),
                    const SizedBox(width: 8),
                    _buildPointBadge(
                        'Redeemed', redeemedPoints, AppColors.error),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointBadge(String label, int points, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            points.toString(),
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // _loadOverviewData removed — data flows through AnalyticsProvider streams.

  // ═══════════════════════════════════════════════════════════════════════════
  // Helper Methods for Real-Time Analytics
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildRealTimeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.successBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.bolt_rounded, color: AppColors.success, size: 16),
          const SizedBox(width: 4),
          Text(
            'Real-time Analytics • $_selectedPeriod',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  int _getActiveCustomers(List<CustomerModel> customers, List<SaleModel> sales) {
    final activePhones = <String>{};
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    
    for (final sale in sales) {
      if (sale.timestamp.isAfter(thirtyDaysAgo) && sale.customerPhone != null) {
        activePhones.add(sale.customerPhone!);
      }
    }
    
    return activePhones.length;
  }

  List<MapEntry<String, int>> _calculateGrowthData(List<CustomerModel> customers) {
    final now = DateTime.now();
    final growthData = <MapEntry<String, int>>[];
    
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      final monthStr = DateFormat('MMM').format(month);
      final count = customers.where((c) => 
        c.registeredAt.year < month.year ||
        (c.registeredAt.year == month.year && c.registeredAt.month <= month.month)
      ).length;
      growthData.add(MapEntry(monthStr, count));
    }
    
    return growthData;
  }

  Map<String, List<CustomerModel>> _calculateCustomerSegments(
    List<CustomerModel> customers,
    List<SaleModel> sales,
  ) {
    final customerPurchases = <String, int>{};
    final customerSpend = <String, double>{};
    final lastPurchase = <String, DateTime>{};
    
    for (final sale in sales) {
      if (sale.customerPhone != null) {
        final phone = sale.customerPhone!;
        customerPurchases[phone] = (customerPurchases[phone] ?? 0) + 1;
        customerSpend[phone] = (customerSpend[phone] ?? 0.0) + sale.totalAmount;
        
        if (lastPurchase[phone] == null || sale.timestamp.isAfter(lastPurchase[phone]!)) {
          lastPurchase[phone] = sale.timestamp;
        }
      }
    }
    
    final vip = <CustomerModel>[];
    final loyal = <CustomerModel>[];
    final regular = <CustomerModel>[];
    final occasional = <CustomerModel>[];
    final atRisk = <CustomerModel>[];
    
    final sixtyDaysAgo = DateTime.now().subtract(const Duration(days: 60));
    
    for (final customer in customers) {
      final purchases = customerPurchases[customer.phone] ?? 0;
      final spend = customerSpend[customer.phone] ?? 0.0;
      final last = lastPurchase[customer.phone];
      
      if (last != null && last.isBefore(sixtyDaysAgo) && purchases > 0) {
        atRisk.add(customer);
      } else if (purchases >= 20 || spend >= 10000) {
        vip.add(customer);
      } else if (purchases >= 10) {
        loyal.add(customer);
      } else if (purchases >= 5) {
        regular.add(customer);
      } else {
        occasional.add(customer);
      }
    }
    
    return {
      'vip': vip,
      'loyal': loyal,
      'regular': regular,
      'occasional': occasional,
      'atRisk': atRisk,
    };
  }

  Widget _buildSegmentCard(
    String title,
    int count,
    Color color,
    IconData icon,
    String description,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSpenders(List<CustomerModel> vipCustomers, List<SaleModel> sales) {
    // Calculate spending per VIP customer
    final spendMap = <String, double>{};
    
    for (final sale in sales) {
      if (sale.customerPhone != null) {
        spendMap[sale.customerPhone!] = 
          (spendMap[sale.customerPhone!] ?? 0.0) + sale.totalAmount;
      }
    }
    
    final vipWithSpend = vipCustomers.map((c) => {
      'customer': c,
      'spend': spendMap[c.phone] ?? 0.0,
    }).toList()
      ..sort((a, b) => (b['spend'] as double).compareTo(a['spend'] as double));
    
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: vipWithSpend.take(5).map((data) {
          final customer = data['customer'] as CustomerModel;
          final spend = data['spend'] as double;
          
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFD97706).withValues(alpha: 0.2),
              child: Icon(
                Icons.diamond,
                color: const Color(0xFFD97706),
                size: 20,
              ),
            ),
            title: Text(
              customer.name,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            subtitle: Text(
              customer.phone,
              style: const TextStyle(fontSize: 11),
            ),
            trailing: Text(
              '₹${fmt.format(spend)}',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.success,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPurchaseFrequency(Map<String, int> purchaseCounts) {
    final frequency = <String, int>{
      '1-2 orders': 0,
      '3-5 orders': 0,
      '6-10 orders': 0,
      '11-20 orders': 0,
      '20+ orders': 0,
    };
    
    for (final count in purchaseCounts.values) {
      if (count <= 2) {
        frequency['1-2 orders'] = frequency['1-2 orders']! + 1;
      } else if (count <= 5) {
        frequency['3-5 orders'] = frequency['3-5 orders']! + 1;
      } else if (count <= 10) {
        frequency['6-10 orders'] = frequency['6-10 orders']! + 1;
      } else if (count <= 20) {
        frequency['11-20 orders'] = frequency['11-20 orders']! + 1;
      } else {
        frequency['20+ orders'] = frequency['20+ orders']! + 1;
      }
    }
    
    final total = purchaseCounts.length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: frequency.entries.map((e) {
          final pct = total > 0 ? e.value / total : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      e.key,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${e.value} customers (${(pct * 100).toStringAsFixed(0)}%)',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
