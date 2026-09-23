import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/store_header_widget.dart';
import '../../config/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/store_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../services/supplier_service.dart';
import '../../models/supplier_model.dart';

/// Modern Enterprise Damaged Products & Shrinkage Screen.
/// Follows the market-ready retail design system.
class DamagedProductsScreen extends StatefulWidget {
  const DamagedProductsScreen({super.key});

  @override
  State<DamagedProductsScreen> createState() => _DamagedProductsScreenState();
}

class _DamagedProductsScreenState extends State<DamagedProductsScreen> {
  final SupplierService _service = SupplierService();
  String _statusFilter = 'All'; // 'All', 'Pending', 'Approved', 'Rejected'

  @override
  Widget build(BuildContext context) {
    final storeId = context.watch<StoreProvider>().selectedStore?.id ?? '';
    final invProvider = context.watch<InventoryProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showReportSheet(),
        icon: const Icon(Icons.add_photo_alternate_rounded, size: 20),
        label: const Text(
          'Report Incident',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
        ),
        backgroundColor: const Color(0xFFEF4444),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: SafeArea(
        child: StreamBuilder<List<DamagedProduct>>(
          stream: invProvider.watchDamageReports(storeId),
          builder: (context, snap) {
            final allReports = snap.data ?? [];
            final pendingReports =
                allReports.where((r) => r.status == 'pending').toList();
            final totalLoss = allReports.fold<double>(
                0.0, (acc, r) => acc + r.estimatedLoss);

            final filteredReports = allReports.where((r) {
              if (_statusFilter == 'Pending') return r.status == 'pending';
              if (_statusFilter == 'Approved') return r.status == 'approved';
              if (_statusFilter == 'Rejected') return r.status == 'rejected';
              return true;
            }).toList();

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Top Enterprise Store Header
                  const StoreHeaderWidget(
                    title: 'Damage & Shrinkage',
                    subtitle: 'AUDIT & WRITE-OFF APPROVALS • Downtown Hub',
                  ),

                  // 1b. Damage Control Banner
                  _buildDamageBanner(
                    pendingCount: pendingReports.length,
                    totalLoss: totalLoss,
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 2. Summary KPI Metrics
                        _buildDamageKPIRow(
                          totalLoss: totalLoss,
                          pendingCount: pendingReports.length,
                          totalReports: allReports.length,
                        ),
                        const SizedBox(height: 16),

                        // 3. Filter Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip('All (${allReports.length})', 'All'),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                  'Pending (${pendingReports.length})', 'Pending'),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                  'Approved (${allReports.where((r) => r.status == "approved").length})',
                                  'Approved'),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                  'Rejected (${allReports.where((r) => r.status == "rejected").length})',
                                  'Rejected'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 4. Incident Log Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'INCIDENT LOG & WRITE-OFFS',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.5,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: pendingReports.isNotEmpty
                                    ? const Color(0xFFFEE2E2)
                                    : const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                pendingReports.isNotEmpty
                                    ? '${pendingReports.length} Pending Sign-off'
                                    : 'All Signed Off ✓',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: pendingReports.isNotEmpty
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFF166534),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // 5. Incidents Stream or Fallback Feed
                        if (filteredReports.isNotEmpty)
                          Column(
                            children: filteredReports
                                .map((item) =>
                                    _LiveDamagedIncidentCard(item: item))
                                .toList(),
                          )
                        else if (allReports.isEmpty)
                          // Realistic Demo Incidents if database is fresh
                          Column(
                            children: [
                              _buildDemoIncidentCard(
                                id: 'DM-0492',
                                productName: 'Alfonso Mango Pulp 850g',
                                sku: 'SKU: AMP-102',
                                quantity: 3,
                                lossAmount: '₹420.00',
                                reason: 'Broken Packaging / Seal Leak',
                                supplierName: 'Fresh Agro Farm Supplies',
                                timeAgo: 'Today, 11:20 AM',
                                cashierName: 'Alex Cashier',
                                photoCount: 2,
                              ),
                              const SizedBox(height: 12),
                              _buildDemoIncidentCard(
                                id: 'DM-0488',
                                productName: 'Organic Almond Milk 1L',
                                sku: 'SKU: OAM-104',
                                quantity: 2,
                                lossAmount: '₹480.00',
                                reason: 'Expired / Fermented',
                                supplierName: 'ITC Hub Direct',
                                timeAgo: 'Yesterday, 3:45 PM',
                                cashierName: 'Sarah Jenkins',
                                photoCount: 1,
                              ),
                            ],
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            alignment: Alignment.center,
                            child: Column(
                              children: [
                                const Icon(Icons.check_circle_outline_rounded,
                                    size: 40, color: Color(0xFF10B981)),
                                const SizedBox(height: 10),
                                Text(
                                  'No $_statusFilter damage reports found.',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return InkWell(
      onTap: () => setState(() => _statusFilter = value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFDC2626) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFDC2626) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  // ── Gradient Damage & Loss Control Banner ──
  Widget _buildDamageBanner({required int pendingCount, required double totalLoss}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7F1D1D), Color(0xFFB91C1C), Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDC2626).withValues(alpha: 0.28),
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
                child: const Icon(Icons.shield_outlined, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Damage & Loss Control',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Shrinkage Tracking • Downtown Hub',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10.5,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _showReportSheet(),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 13, color: Color(0xFF7F1D1D)),
                      SizedBox(width: 4),
                      Text(
                        'Report',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF7F1D1D),
                        ),
                      ),
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
                _damageBannerStat('Pending', '$pendingCount Items', Icons.pending_actions_rounded, const Color(0xFFFDE68A)),
                Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.2)),
                _damageBannerStat('Total Loss', '₹${totalLoss.toStringAsFixed(0)}', Icons.currency_rupee_rounded, const Color(0xFFFCA5A5)),
                Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.2)),
                _damageBannerStat('Approval', pendingCount == 0 ? '100%' : 'Needs Review', Icons.trending_down_rounded, const Color(0xFF86EFAC)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _damageBannerStat(String label, String value, IconData icon, Color color) {
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

  // ── KPI Summary Row ──
  Widget _buildDamageKPIRow({
    required double totalLoss,
    required int pendingCount,
    required int totalReports,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildKPICard(
            title: 'RECORDED LOSS',
            value: '₹${totalLoss.toStringAsFixed(0)}',
            badgeText: '$totalReports reports',
            badgeColor: const Color(0xFFEF4444),
            badgeBg: const Color(0xFFFEE2E2),
            icon: Icons.broken_image_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildKPICard(
            title: 'PENDING SIGN-OFF',
            value: '$pendingCount items',
            badgeText: pendingCount > 0 ? 'Action req.' : 'All clear',
            badgeColor: pendingCount > 0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
            badgeBg: pendingCount > 0 ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
            icon: Icons.pending_actions_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildKPICard(
            title: 'INCIDENTS',
            value: '$totalReports logged',
            badgeText: 'Live audit log',
            badgeColor: const Color(0xFF2563EB),
            badgeBg: const Color(0xFFEFF6FF),
            icon: Icons.verified_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required String badgeText,
    required Color badgeColor,
    required Color badgeBg,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
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
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.4,
                ),
              ),
              Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: badgeColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoIncidentCard({
    required String id,
    required String productName,
    required String sku,
    required int quantity,
    required String lossAmount,
    required String reason,
    required String supplierName,
    required String timeAgo,
    required String cashierName,
    required int photoCount,
  }) {
    return _InteractiveDamageCard(
      id: id,
      productName: productName,
      sku: sku,
      quantity: quantity,
      lossAmount: lossAmount,
      reason: reason,
      supplierName: supplierName,
      timeAgo: timeAgo,
      cashierName: cashierName,
      photoCount: photoCount,
    );
  }

  void _showReportSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ReportDamageSheet(service: _service),
    );
  }
}

class _InteractiveDamageCard extends StatefulWidget {
  final String id;
  final String productName;
  final String sku;
  final int quantity;
  final String lossAmount;
  final String reason;
  final String supplierName;
  final String timeAgo;
  final String cashierName;
  final int photoCount;

  const _InteractiveDamageCard({
    required this.id,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.lossAmount,
    required this.reason,
    required this.supplierName,
    required this.timeAgo,
    required this.cashierName,
    required this.photoCount,
  });

  @override
  State<_InteractiveDamageCard> createState() => _InteractiveDamageCardState();
}

class _InteractiveDamageCardState extends State<_InteractiveDamageCard> {
  bool _approved = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _approved
              ? const Color(0xFF10B981).withValues(alpha: 0.4)
              : const Color(0xFFE2E8F0),
        ),
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
          // Row 1: ID & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.id,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.timeAgo,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _approved ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _approved ? 'APPROVED' : 'AWAITING AUDIT',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: _approved ? const Color(0xFF166534) : const Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Product & Loss Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.broken_image_rounded,
                  color: Color(0xFFEF4444),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.productName,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.sku}  •  ${widget.supplierName}',
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
                    '-${widget.lossAmount}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                  Text(
                    '${widget.quantity} units',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Reason Pill & Details
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.reason} • Reported by ${widget.cashierName}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
                Text(
                  '📷 ${widget.photoCount} Photos',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Actions
          if (!_approved)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Vendor replacement credit claim filed with ${widget.supplierName}.'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: const Color(0xFF2563EB),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Claim from Vendor',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => _approved = true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✓ Incident ${widget.id} approved. ₹${widget.lossAmount} written off to shrinkage.'),
                          backgroundColor: const Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Approve Write-off',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  '✓ Approved & Reconciled with Shrinkage Ledger',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF059669),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LiveDamagedIncidentCard extends StatefulWidget {
  final DamagedProduct item;
  const _LiveDamagedIncidentCard({required this.item});

  @override
  State<_LiveDamagedIncidentCard> createState() => _LiveDamagedIncidentCardState();
}

class _LiveDamagedIncidentCardState extends State<_LiveDamagedIncidentCard> {
  bool _updating = false;

  Future<void> _handleStatusUpdate(String status) async {
    setState(() => _updating = true);
    final auth = context.read<AuthProvider>();
    final invProvider = context.read<InventoryProvider>();

    try {
      await invProvider.updateDamageReportStatus(
        reportId: widget.item.id,
        status: status,
        userId: auth.currentUser?.id ?? 'mgr_01',
        userName: auth.currentUser?.name ?? 'Store Manager',
        note: status == 'rejected' ? 'Rejected by Manager - stock restored' : 'Write-off approved',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'approved'
                ? '✓ Incident approved and written off to shrinkage.'
                : '✕ Damage report rejected. Stock has been restored.'),
            backgroundColor: status == 'approved' ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isPending = item.status == 'pending';
    final isApproved = item.status == 'approved';

    final Color statusColor = isApproved
        ? const Color(0xFF10B981)
        : isPending
            ? const Color(0xFFF59E0B)
            : const Color(0xFF64748B);

    final Color statusBg = isApproved
        ? const Color(0xFFDCFCE7)
        : isPending
            ? const Color(0xFFFEF3C7)
            : const Color(0xFFF1F5F9);

    final String statusLabel = isApproved
        ? 'APPROVED WRITE-OFF'
        : isPending
            ? 'PENDING SIGN-OFF'
            : 'REJECTED (RESTORED)';

    final dateStr =
        '${item.reportedAt.day.toString().padLeft(2, '0')}/${item.reportedAt.month.toString().padLeft(2, '0')} ${item.reportedAt.hour.toString().padLeft(2, '0')}:${item.reportedAt.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
        ),
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
          // Header: ID + Date + Status Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.id.length > 8 ? item.id.substring(0, 8).toUpperCase() : item.id.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Product Details & Loss
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Reported by ${item.reportedByUserName.isNotEmpty ? item.reportedByUserName : "Store Employee"}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
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
                    '-₹${item.estimatedLoss.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                  Text(
                    '${item.quantity} units damaged',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Reason Pill
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Reason: ${item.reason}${item.notes != null && item.notes!.isNotEmpty ? " • ${item.notes}" : ""}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Actions
          if (_updating)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (isPending)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleStatusUpdate('rejected'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Reject & Restore Stock',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleStatusUpdate('approved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Approve Write-off',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              decoration: BoxDecoration(
                color: isApproved ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isApproved ? Icons.verified_rounded : Icons.info_outline,
                    size: 14,
                    color: isApproved ? const Color(0xFF059669) : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isApproved
                        ? '✓ Signed off by ${item.approvedByUserName ?? "Manager"} • Reconciled'
                        : '✕ Rejected by ${item.approvedByUserName ?? "Manager"} • Stock Restored',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isApproved ? const Color(0xFF059669) : const Color(0xFF64748B),
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

class _ReportDamageSheet extends StatefulWidget {
  final SupplierService service;
  const _ReportDamageSheet({required this.service});

  @override
  State<_ReportDamageSheet> createState() => _ReportDamageSheetState();
}

class _ReportDamageSheetState extends State<_ReportDamageSheet> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedProductId;
  String? _selectedProductName;
  double _purchasePrice = 120.0;
  final String _selectedSupplierId = 'sup_01';
  final String _selectedSupplierName = 'ITC Hub Direct';
  int _quantity = 1;
  String _reason = AppConstants.damageReasons.first;
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _saving = true);

    final store = context.read<StoreProvider>();
    final auth = context.read<AuthProvider>();

    try {
      await context.read<InventoryProvider>().reportDamage(
        storeId: store.selectedStore?.id ?? 'store_1',
        productId: _selectedProductId ?? 'p_custom',
        productName: _selectedProductName ?? 'Damaged Item',
        supplierId: _selectedSupplierId,
        supplierName: _selectedSupplierName,
        quantity: _quantity,
        estimatedLoss: _purchasePrice * _quantity,
        reason: _reason,
        userId: auth.currentUser?.id ?? 'mgr_01',
        userName: auth.currentUser?.name ?? 'Store Manager',
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Damage incident logged in Firestore and inventory deducted.'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reporting damage: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 16,
        right: 16,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Report Damaged Incident',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Select Product *'),
                items: productProvider.products.isNotEmpty
                    ? productProvider.products
                        .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                        .toList()
                    : const [
                        DropdownMenuItem(value: 'p1', child: Text('Organic Almond Milk 1L')),
                        DropdownMenuItem(value: 'p2', child: Text('Basmati Royal Rice 5kg')),
                        DropdownMenuItem(value: 'p3', child: Text('Alfonso Mango Pulp 850g')),
                      ],
                onChanged: (v) {
                  setState(() {
                    _selectedProductId = v;
                    _selectedProductName = v == 'p1'
                        ? 'Organic Almond Milk 1L'
                        : v == 'p2'
                            ? 'Basmati Royal Rice 5kg'
                            : 'Alfonso Mango Pulp 850g';
                  });
                },
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: _reason,
                decoration: const InputDecoration(labelText: 'Damage Reason *'),
                items: AppConstants.damageReasons
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => _reason = v ?? _reason),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: '1',
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Quantity *'),
                      onChanged: (v) => _quantity = int.tryParse(v) ?? 1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: '120.00',
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Unit Cost (₹) *'),
                      onChanged: (v) => _purchasePrice = double.tryParse(v) ?? 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Notes / Damage Details'),
              ),
              const SizedBox(height: 18),

              ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  _saving ? 'Saving...' : 'Submit Incident Report',
                  style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
