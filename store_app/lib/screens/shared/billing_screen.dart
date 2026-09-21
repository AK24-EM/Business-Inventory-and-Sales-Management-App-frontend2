import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../providers/store_provider.dart';
import '../../services/billing_service.dart';
import '../../models/sale_model.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final BillingService _billingService = BillingService();
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  List<SaleModel> _sales = [];
  bool _isLoading = false;
  String? _selectedPeriod = 'Last 7 Days';

  final List<String> _periods = [
    'Today',
    'Yesterday',
    'Last 7 Days',
    'This Month',
    'Last Month',
    'Custom Range',
  ];

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    setState(() => _isLoading = true);
    try {
      final storeId = context.read<StoreProvider>().selectedStore?.id;
      final sales = await _billingService.getSalesByDateRange(
        startDate: _startDate,
        endDate: _endDate,
        storeId: storeId,
      );
      setState(() {
        _sales = sales;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load sales: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _onPeriodChanged(String? period) {
    if (period == null) return;

    setState(() => _selectedPeriod = period);

    final now = DateTime.now();
    switch (period) {
      case 'Today':
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'Yesterday':
        final yesterday = now.subtract(const Duration(days: 1));
        _startDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
        _endDate =
            DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
        break;
      case 'Last 7 Days':
        _startDate = now.subtract(const Duration(days: 7));
        _endDate = now;
        break;
      case 'This Month':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
        break;
      case 'Last Month':
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        _startDate = lastMonth;
        _endDate = DateTime(now.year, now.month, 0, 23, 59, 59);
        break;
      case 'Custom Range':
        _showDateRangePicker();
        return;
    }
    _loadSales();
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadSales();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Billing & Invoices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _sales.isEmpty ? null : _exportInvoices,
            tooltip: 'Export',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          _buildSummaryCards(),
          Expanded(child: _buildInvoiceList()),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Period',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedPeriod,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down),
                items: _periods.map((period) {
                  return DropdownMenuItem(
                    value: period,
                    child: Text(period),
                  );
                }).toList(),
                onChanged: _onPeriodChanged,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final totalSales = _sales.length;
    final totalRevenue =
        _sales.fold<double>(0, (sum, sale) => sum + sale.totalAmount);
    final cashSales =
        _sales.where((s) => s.paymentMode == PaymentMode.cash).length;
    final upiSales =
        _sales.where((s) => s.paymentMode == PaymentMode.upi).length;
    final cardSales =
        _sales.where((s) => s.paymentMode == PaymentMode.card).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Sales',
                  totalSales.toString(),
                  Icons.receipt_long,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Revenue',
                  '₹${totalRevenue.toStringAsFixed(0)}',
                  Icons.currency_rupee,
                  AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPaymentModeCard('Cash', cashSales, AppColors.info),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPaymentModeCard('UPI', upiSales, AppColors.warning),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPaymentModeCard('Card', cardSales, AppColors.error),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentModeCard(String mode, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: color,
            ),
          ),
          Text(
            mode,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_sales.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppColors.textTertiary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No sales found',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try selecting a different date range',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _sales.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final sale = _sales[index];
        return _InvoiceCard(
          sale: sale,
          onTap: () => _showInvoiceDetails(sale),
        );
      },
    );
  }

  void _showInvoiceDetails(SaleModel sale) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InvoiceDetailSheet(
        saleId: sale.id,
        billingService: _billingService,
      ),
    );
  }

  Future<void> _exportInvoices() async {
    try {
      final storeId = context.read<StoreProvider>().selectedStore?.id;
      final invoices = await _billingService.exportInvoiceList(
        startDate: _startDate,
        endDate: _endDate,
        storeId: storeId,
      );

      // Convert to CSV format
      final csv = StringBuffer();
      csv.writeln(
          'Invoice,Date,Time,Customer,Phone,Items,Amount,Payment,Employee');
      for (final inv in invoices) {
        csv.writeln(
            '${inv['invoiceNumber']},${inv['date']},${inv['time']},${inv['customerName']},${inv['customerPhone']},${inv['items']},${inv['amount']},${inv['paymentMode']},${inv['employeeName']}');
      }

      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: csv.toString()));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice data copied to clipboard'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      _showError('Failed to export: $e');
    }
  }
}

class _InvoiceCard extends StatelessWidget {
  final SaleModel sale;
  final VoidCallback onTap;

  const _InvoiceCard({required this.sale, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final paymentColor = sale.paymentMode == PaymentMode.cash
        ? AppColors.info
        : sale.paymentMode == PaymentMode.upi
            ? AppColors.warning
            : AppColors.error;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.receipt,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sale.invoiceNumber ?? 'INV-${sale.id.substring(0, 8)}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy, hh:mm a')
                            .format(sale.timestamp),
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${sale.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(
                  Icons.shopping_bag_outlined,
                  '${sale.itemCount} items',
                  AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  Icons.payment,
                  sale.paymentMode.displayName,
                  paymentColor,
                ),
                const SizedBox(width: 8),
                if (sale.customerName != null)
                  Expanded(
                    child: _buildInfoChip(
                      Icons.person_outline,
                      sale.customerName!,
                      AppColors.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 12, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  'By ${sale.employeeName}',
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios,
                    size: 12, color: AppColors.textTertiary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceDetailSheet extends StatelessWidget {
  final String saleId;
  final BillingService billingService;

  const _InvoiceDetailSheet({
    required this.saleId,
    required this.billingService,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: FutureBuilder<Map<String, dynamic>>(
            future: billingService.generateInvoiceData(saleId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              final invoiceData = snapshot.data!;
              return _buildInvoiceContent(
                  context, scrollController, invoiceData);
            },
          ),
        );
      },
    );
  }

  Widget _buildInvoiceContent(BuildContext context,
      ScrollController scrollController, Map<String, dynamic> data) {
    final sale = data['sale'] as SaleModel;
    final storeInfo = data['storeInfo'] as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;

    return Column(
      children: [
        // Handle
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            children: [
              const Icon(Icons.receipt_long, color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Invoice Details',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      data['invoiceNumber'] as String,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _copyInvoiceText(context, data),
                icon: const Icon(Icons.copy_outlined),
                tooltip: 'Copy Invoice',
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Content
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              // Store Info
              _buildSection('Store Information', [
                _buildRow('Name', storeInfo['name'] as String),
                if (storeInfo['address'] != null)
                  _buildRow('Address', storeInfo['address'] as String),
                if (storeInfo['phone'] != null)
                  _buildRow('Phone', storeInfo['phone'] as String),
                if (storeInfo['gstin'] != null)
                  _buildRow('GSTIN', storeInfo['gstin'] as String),
              ]),
              const SizedBox(height: 16),
              // Invoice Info
              _buildSection('Invoice Information', [
                _buildRow('Invoice No.', data['invoiceNumber'] as String),
                _buildRow('Date', data['formattedDate'] as String),
                _buildRow('Time', data['formattedTime'] as String),
                _buildRow('Payment Mode', data['paymentMode'] as String),
                _buildRow('Employee', data['employeeName'] as String),
              ]),
              const SizedBox(height: 16),
              // Customer Info
              if (sale.customerName != null) ...[
                _buildSection('Customer Information', [
                  _buildRow('Name', data['customerName'] as String? ?? '-'),
                  _buildRow('Phone', data['customerPhone'] as String? ?? '-'),
                ]),
                const SizedBox(height: 16),
              ],
              // Items
              _buildSection(
                'Items (${data['totalItems']})',
                items.map((item) {
                  return _buildItemRow(
                    item['name'] as String,
                    item['quantity'] as int,
                    item['unitPrice'] as double,
                    item['totalPrice'] as double,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Totals
              _buildTotalsSection(data),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
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
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(
      String name, int quantity, double unitPrice, double totalPrice) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              name,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              'x$quantity',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              '₹${unitPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              '₹${totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsSection(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if ((data['discount'] as double) > 0) ...[
            _buildTotalRow('Subtotal', data['subtotal'] as double),
            _buildTotalRow('Discount', -(data['discount'] as double)),
          ],
          if ((data['loyaltyRedeemed'] as double) > 0)
            _buildTotalRow(
                'Loyalty Redeemed', -(data['loyaltyRedeemed'] as double)),
          const Divider(color: Colors.white30, height: 20),
          _buildTotalRow('TOTAL', data['total'] as double, isTotal: true),
          if ((data['loyaltyPointsEarned'] as int) > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.stars, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${data['loyaltyPointsEarned']} Loyalty Points Earned',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: isTotal ? 16 : 13,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Text(
            '₹${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: isTotal ? 20 : 13,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyInvoiceText(
      BuildContext context, Map<String, dynamic> data) async {
    final invoiceText = await billingService.generateInvoiceText(saleId);
    await Clipboard.setData(ClipboardData(text: invoiceText));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invoice copied to clipboard'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
