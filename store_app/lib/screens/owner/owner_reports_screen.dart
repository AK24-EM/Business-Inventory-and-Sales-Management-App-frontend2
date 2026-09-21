import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../providers/store_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/sales_service.dart';
import '../../services/inventory_service.dart';
import '../../services/customer_service.dart';
import '../../models/analytics_model.dart';

class OwnerReportsScreen extends StatefulWidget {
  const OwnerReportsScreen({super.key});

  @override
  State<OwnerReportsScreen> createState() => _OwnerReportsScreenState();
}

class _OwnerReportsScreenState extends State<OwnerReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  SalesSummary? _summary;
  List<ProductPerformance> _products = [];
  List<CustomerInsight> _customers = [];
  bool _loading = true;
  String _period = 'Last 30 Days';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
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
      case 'This Week':
        return DateTimeRange(
            start: now.subtract(const Duration(days: 7)), end: now);
      case 'This Month':
        return DateTimeRange(
            start: DateTime(now.year, now.month, 1), end: now);
      case 'Last Month':
        final lm = DateTime(now.year, now.month - 1, 1);
        return DateTimeRange(
            start: lm,
            end: DateTime(now.year, now.month, 1)
                .subtract(const Duration(days: 1)));
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
    _products = await svc.getProductPerformance(
        from: range.start, to: range.end, limit: 30);
    _customers = await svc.getCustomerInsights(
        from: range.start, to: range.end);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reports'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Sales Report'),
            Tab(text: 'Product Report'),
            Tab(text: 'Customer Report'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.date_range_outlined),
            initialValue: _period,
            onSelected: (v) {
              setState(() => _period = v);
              _load();
            },
            itemBuilder: (_) => [
              'Today', 'This Week', 'This Month',
              'Last Month', 'Last 30 Days', 'Last 3 Months'
            ].map((p) => PopupMenuItem(value: p, child: Text(p))).toList(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                _SalesReportTab(summary: _summary, period: _period),
                _ProductReportTab(products: _products),
                _CustomerReportTab(customers: _customers),
              ],
            ),
    );
  }
}

class _SalesReportTab extends StatelessWidget {
  final SalesSummary? summary;
  final String period;
  const _SalesReportTab(
      {required this.summary, required this.period});

  @override
  Widget build(BuildContext context) {
    if (summary == null) {
      return const Center(child: Text('No data available'));
    }
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(period,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontFamily: 'Poppins',
                        fontSize: 12)),
                const SizedBox(height: 4),
                Text('₹${fmt.format(summary!.totalRevenue)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontSize: 32,
                        fontWeight: FontWeight.w700)),
                const Text('Total Revenue',
                    style: TextStyle(
                        color: Colors.white70,
                        fontFamily: 'Poppins',
                        fontSize: 12)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _MiniStat(
                        label: 'Transactions',
                        value: '${summary!.totalTransactions}'),
                    _MiniStat(
                        label: 'Avg Ticket',
                        value:
                            '₹${fmt.format(summary!.averageTransactionValue)}'),
                    _MiniStat(
                        label: 'Items Sold',
                        value: '${summary!.totalItemsSold}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Store-wise Breakdown',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...summary!.revenueByStore.entries.map((e) {
            final pct = summary!.totalRevenue > 0
                ? e.value / summary!.totalRevenue
                : 0.0;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key,
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                              fontSize: 13)),
                      Text('₹${fmt.format(e.value)}',
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
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
                      ),
                      const SizedBox(width: 8),
                      Text('${(pct * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11)),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),
          const Text('Payment Mode Split',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: summary!.revenueByPaymentMode.entries
                  .map((e) => ListTile(
                        dense: true,
                        leading: Icon(
                          e.key == 'Cash'
                              ? Icons.money
                              : e.key == 'UPI'
                                  ? Icons.qr_code
                                  : Icons.credit_card,
                          color: AppColors.primary,
                        ),
                        title: Text(e.key,
                            style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13)),
                        trailing: Text('₹${fmt.format(e.value)}',
                            style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600)),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
          Text(label,
              style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                  fontFamily: 'Poppins')),
        ],
      ),
    );
  }
}

class _ProductReportTab extends StatelessWidget {
  final List<ProductPerformance> products;
  const _ProductReportTab({required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Center(child: Text('No product data'));
    }
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (_, i) {
        final p = products[i];
        final isFast = i < 5;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                alignment: Alignment.center,
                child: Text('#${i + 1}',
                    style: TextStyle(
                        color: isFast
                            ? AppColors.secondary
                            : AppColors.textTertiary,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(p.productName,
                              style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13)),
                        ),
                        if (isFast)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.successBg,
                              borderRadius:
                                  BorderRadius.circular(6),
                            ),
                            child: const Text('FAST',
                                style: TextStyle(
                                    color: AppColors.success,
                                    fontSize: 8,
                                    fontWeight:
                                        FontWeight.w700)),
                          ),
                      ],
                    ),
                    Text(p.category,
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${p.quantitySold} sold',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          color: isFast
                              ? AppColors.secondary
                              : AppColors.textSecondary,
                          fontSize: 13)),
                  Text('₹${fmt.format(p.revenue)}',
                      style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 11)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CustomerReportTab extends StatelessWidget {
  final List<CustomerInsight> customers;
  const _CustomerReportTab({required this.customers});

  @override
  Widget build(BuildContext context) {
    if (customers.isEmpty) {
      return const Center(child: Text('No customer data'));
    }
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: customers.length,
      itemBuilder: (_, i) {
        final c = customers[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    AppColors.primary.withOpacity(0.1),
                child: Text(
                    c.customerName.isNotEmpty
                        ? c.customerName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
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
                  Text('${c.totalPurchases} orders',
                      style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 10)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
