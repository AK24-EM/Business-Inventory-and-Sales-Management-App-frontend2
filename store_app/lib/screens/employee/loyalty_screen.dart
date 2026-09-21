import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../config/app_constants.dart';
import '../../services/customer_service.dart';
import '../../models/customer_model.dart';

class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  final CustomerService _service = CustomerService();
  final _phoneCtrl = TextEditingController();
  bool _searching = false;
  CustomerModel? _customer;
  LoyaltyAccount? _account;
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length != 10) {
      setState(() => _error = 'Enter a valid 10-digit number');
      return;
    }
    setState(() {
      _searching = true;
      _error = null;
      _customer = null;
      _account = null;
    });
    final customer = await _service.findByPhone(phone);
    final account = await _service.getLoyaltyAccount(phone);
    setState(() {
      _customer = customer;
      _account = account;
      _searching = false;
      if (customer == null && account == null) {
        _error = 'No customer found with this number';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Loyalty Program')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lookup card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.stars, color: Colors.white, size: 22),
                      SizedBox(width: 8),
                      Text('Loyalty Lookup',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                      '1 point per ₹1 spent • ₹0.10 per point',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontFamily: 'Poppins')),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(fontFamily: 'Poppins'),
                          decoration: InputDecoration(
                            hintText: 'Enter mobile number',
                            hintStyle: const TextStyle(
                                color: Colors.white54),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.2),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(Icons.phone_outlined,
                                color: Colors.white70),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.warning,
                          ),
                          onPressed: _searching ? null : _lookup,
                          child: _searching
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                              AppColors.warning)))
                              : const Text('Search'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(8)),
                child: Text(_error!,
                    style: const TextStyle(
                        color: AppColors.error, fontSize: 13)),
              ),
            ],

            if (_account != null) ...[
              const SizedBox(height: 20),
              _LoyaltyAccountCard(
                  account: _account!, customer: _customer),
              const SizedBox(height: 20),
              _LoyaltyHistorySection(phone: _account!.phone),
            ],

            const SizedBox(height: 24),
            _HowItWorksSection(),
          ],
        ),
      ),
    );
  }
}

class _LoyaltyAccountCard extends StatelessWidget {
  final LoyaltyAccount account;
  final CustomerModel? customer;
  const _LoyaltyAccountCard(
      {required this.account, required this.customer});

  @override
  Widget build(BuildContext context) {
    final rupeeValue = account.availablePoints *
        AppConstants.pointsToRupeeValue;
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.warning.withOpacity(0.15),
                child: Text(
                  customer?.name.isNotEmpty == true
                      ? customer!.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: AppColors.warning,
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer?.name ?? 'Loyalty Member',
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                    ),
                    Text(account.phone,
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _PointsStat(
                  label: 'Available',
                  value: account.availablePoints.toString(),
                  color: AppColors.success),
              const SizedBox(width: 12),
              _PointsStat(
                  label: 'Total Earned',
                  value: account.totalPoints.toString(),
                  color: AppColors.primary),
              const SizedBox(width: 12),
              _PointsStat(
                  label: 'Redeemed',
                  value: account.redeemedPoints.toString(),
                  color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.currency_rupee,
                    color: AppColors.success, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Worth ₹${fmt.format(rupeeValue)} in discounts',
                  style: const TextStyle(
                      color: AppColors.success,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PointsStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _PointsStat(
      {required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: color)),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _LoyaltyHistorySection extends StatelessWidget {
  final String phone;
  final CustomerService _service = CustomerService();
  _LoyaltyHistorySection({required this.phone});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Transaction History',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        StreamBuilder<List<LoyaltyTransaction>>(
          stream: _service.getLoyaltyHistoryStream(phone),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final txns = snap.data ?? [];
            if (txns.isEmpty) {
              return const Center(
                  child: Text('No transactions yet',
                      style: TextStyle(
                          color: AppColors.textSecondary)));
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: txns.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) => _TxnRow(txn: txns[i]),
            );
          },
        ),
      ],
    );
  }
}

class _TxnRow extends StatelessWidget {
  final LoyaltyTransaction txn;
  const _TxnRow({required this.txn});

  @override
  Widget build(BuildContext context) {
    final isEarn = txn.type == LoyaltyTransactionType.earn;
    return ListTile(
      dense: true,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isEarn ? AppColors.successBg : AppColors.errorBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isEarn ? Icons.add : Icons.remove,
          color: isEarn ? AppColors.success : AppColors.error,
          size: 18,
        ),
      ),
      title: Text(
          isEarn ? 'Points Earned' : 'Points Redeemed',
          style:
              const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
      subtitle: Text(
          '${txn.storeName} · ${DateFormat('dd MMM, hh:mm a').format(txn.timestamp)}',
          style: const TextStyle(fontSize: 11)),
      trailing: Text(
        isEarn ? '+${txn.points}' : '-${txn.points}',
        style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: isEarn ? AppColors.success : AppColors.error),
      ),
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.info, size: 18),
              SizedBox(width: 6),
              Text('How It Works',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      color: AppColors.info)),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow('Earn', 'Get 1 point for every ₹1 spent'),
          _infoRow(
              'Redeem', 'Min ${AppConstants.pointsRedemptionThreshold} points to redeem'),
          _infoRow('Value', '₹${AppConstants.pointsToRupeeValue} per point'),
          _infoRow('Limit',
              'Max ${AppConstants.maxRedemptionPercentage}% of bill can be paid with points'),
          _infoRow('Shared', 'Same number can be used by family members'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(label,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: AppColors.info)),
          ),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary))),
        ],
      ),
    );
  }
}
