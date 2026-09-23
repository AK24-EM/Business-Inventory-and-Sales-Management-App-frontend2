import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/app_theme.dart';
import '../../providers/loyalty_provider.dart';
import '../../providers/store_provider.dart';
import '../../services/loyalty_service.dart';
import '../../services/customer_service.dart';
import '../../models/customer_model.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Customer Analytics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard_outlined, size: 20)),
            Tab(text: 'Loyalty', icon: Icon(Icons.stars, size: 20)),
            Tab(text: 'Top Customers', icon: Icon(Icons.leaderboard, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildLoyaltyTab(),
          _buildTopCustomersTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final storeId = context.read<StoreProvider>().selectedStore?.id;

    return FutureBuilder<Map<String, dynamic>>(
      future: _loadOverviewData(storeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final data = snapshot.data!;
        final customerCount = data['customerCount'] as int;
        final activeCustomers = data['activeCustomers'] as int;
        final newThisMonth = data['newThisMonth'] as int;
        final avgPurchases = data['avgPurchases'] as double;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Total Customers',
                      customerCount.toString(),
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
              _buildGrowthChart(data['growthData'] as List<MapEntry<String, int>>),
              const SizedBox(height: 20),
              // Recent Registrations
              _buildSectionHeader('Recent Registrations'),
              const SizedBox(height: 12),
              _buildRecentCustomers(data['recentCustomers'] as List<CustomerModel>),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoyaltyTab() {
    final storeId = context.read<StoreProvider>().selectedStore?.id;

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

  Future<Map<String, dynamic>> _loadOverviewData(String? storeId) async {
    final customers = storeId != null
        ? await _customerService.getStoreCustomers(storeId)
        : [];

    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final newThisMonth =
        customers.where((c) => !c.registeredAt.isBefore(thisMonth)).length;

    // Generate mock growth data for last 6 months
    final growthData = <MapEntry<String, int>>[];
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      final monthStr = DateFormat('MMM').format(month);
      final count =
          customers.where((c) => !c.registeredAt.isAfter(month)).length;
      growthData.add(MapEntry(monthStr, count));
    }

    return {
      'customerCount': customers.length,
      'activeCustomers':
          customers.where((c) => c.isActive).length,
      'newThisMonth': newThisMonth,
      'avgPurchases': 0.0, // Would need sales data
      'growthData': growthData,
      'recentCustomers': customers
        ..sort((a, b) => b.registeredAt.compareTo(a.registeredAt)),
    };
  }
}
