import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../widgets/store_header_widget.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _activeTab = 'Stock & Audits'; // Stock & Audits | Transfers (3) | Damaged Log
  String _activeFilter = 'All Stock'; // All Stock | Low Stock | Out of Stock
  bool _inboundConfirmed = false;

  final List<String> _tabs = const ['Stock & Audits', 'Transfers (3)', 'Damaged Log'];

  // Demo inventory feed items matching the exact reference in screenshot 2
  final List<Map<String, dynamic>> _feedItems = const [
    {
      'id': 'inv_01',
      'name': 'Basmati Royal Rice 5kg',
      'sku': 'SKU: BRR-501',
      'minSafe': 15,
      'stock': 6,
      'status': 'LOW (6 LEFT)',
      'statusColor': Color(0xFFEF4444),
      'statusBg': Color(0xFFFEE2E2),
      'badgeType': 'low',
      'badgeText': '5kg',
      'image': 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=500',
      'footerType': 'transfer',
      'footerText': 'Store 2 (Westend): 42 bags avail...',
      'footerAction': 'Request Transfer',
    },
    {
      'id': 'inv_02',
      'name': 'Alfonso Mango Pulp 850g',
      'sku': 'SKU: AMP-102',
      'minSafe': 12,
      'stock': 4,
      'status': 'LOW (4 LEFT)',
      'statusColor': Color(0xFFEF4444),
      'statusBg': Color(0xFFFEE2E2),
      'badgeType': 'low',
      'badgeText': '850g',
      'image': 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=500',
      'footerType': 'transfer',
      'footerText': 'Store 3 (Metro): 28 cans avail...',
      'footerAction': 'Request Transfer',
    },
    {
      'id': 'inv_03',
      'name': 'Organic Green Tea 100 ct',
      'sku': 'SKU: OGT-884',
      'minSafe': 10,
      'stock': 34,
      'status': 'IN STOCK (34)',
      'statusColor': Color(0xFF166534),
      'statusBg': Color(0xFFDCFCE7),
      'badgeType': 'in_stock',
      'badgeText': '100 ct',
      'image': 'https://images.unsplash.com/photo-1564890369478-c89ca6d9cde9?w=500',
      'footerType': 'audit',
      'footerText': '✓ Audited yesterday by Mgr S. Rao',
      'footerAction': null,
    },
    {
      'id': 'inv_04',
      'name': 'Aashirvaad Whole Wheat 10kg',
      'sku': 'SKU: AWW-202',
      'minSafe': 20,
      'stock': 18,
      'status': 'REORDER (18 LEFT)',
      'statusColor': Color(0xFF4338CA),
      'statusBg': Color(0xFFEEF2FF),
      'badgeType': 'reorder',
      'badgeText': '10kg',
      'image': 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=500',
      'footerType': 'vendor',
      'footerText': 'Supplier: ITC Hub direct',
      'footerAction': 'Add to Vendor PO',
    },
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top Store & Shift Header
              const StoreHeaderWidget(
                title: 'Inventory Stock',
                subtitle: 'ACTIVE SHIFT • Till #02',
              ),

              const SizedBox(height: 8),

              // 2. 3 Key Metrics KPI Cards Row
              _buildKpiMetricsRow(),

              const SizedBox(height: 12),

              // 3. Quick Action Buttons Row (+ Transfer, Log Damage, Stock Scan)
              _buildQuickActionsRow(),

              const SizedBox(height: 14),

              // 4. Inbound Delivery Card
              if (!_inboundConfirmed) ...[
                _buildInboundDeliveryCard(),
                const SizedBox(height: 14),
              ],

              // 5. Segmented Filter Tabs (Stock & Audits, Transfers, Damaged Log)
              _buildSegmentedTabs(),

              const SizedBox(height: 12),

              // 6. Search Bar + Barcode Scan Icon
              _buildSearchBar(),

              const SizedBox(height: 10),

              // 7. Filter Chips (All Stock, Low Stock, Out of Stock)
              _buildFilterChips(),

              const SizedBox(height: 14),

              // 8. Store Inventory Feed
              _buildInventoryFeed(),

              const SizedBox(height: 16),

              // 9. Recent Damage Incident Card
              _buildRecentDamageCard(),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 1. 3 KPI Summary Cards
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildKpiMetricsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Card 1: ACTIVE SKUS
          Expanded(
            child: _buildMetricCard(
              title: 'ACTIVE SKUS',
              icon: Icons.inventory_2_outlined,
              iconColor: const Color(0xFF2563EB),
              value: '1,248',
              badge: const Row(
                children: [
                  Icon(Icons.trending_up_rounded,
                      size: 13, color: Color(0xFF10B981)),
                  SizedBox(width: 2),
                  Text(
                    '98.4% live',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Card 2: LOW STOCK
          Expanded(
            child: _buildMetricCard(
              title: 'LOW STOCK',
              icon: Icons.warning_amber_rounded,
              iconColor: const Color(0xFFEF4444),
              value: '14',
              valueColor: const Color(0xFFDC2626),
              badge: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Action req.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB91C1C),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Card 3: TRANSFERS
          Expanded(
            child: _buildMetricCard(
              title: 'TRANSFERS',
              icon: Icons.local_shipping_outlined,
              iconColor: const Color(0xFF2563EB),
              value: '3 runs',
              badge: const Text(
                '2 in • 1 out',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String value,
    Color? valueColor,
    required Widget badge,
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
            blurRadius: 6,
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
                  letterSpacing: 0.3,
                  color: Color(0xFF64748B),
                ),
              ),
              Icon(icon, size: 16, color: iconColor),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: valueColor ?? const Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          badge,
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. Quick Action Buttons Row (+ Transfer, Log Damage, Stock Scan)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildQuickActionsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Button 1: + Transfer (Vibrant solid blue)
          Expanded(
            flex: 4,
            child: ElevatedButton(
              onPressed: () => _showTransferModal(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 1,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swap_horiz_rounded, size: 16, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    '+ Transfer',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Button 2: Log Damage (Clean white with red icon)
          Expanded(
            flex: 4,
            child: OutlinedButton(
              onPressed: () => _showDamageModal(),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1E293B),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_late_outlined,
                      size: 15, color: Color(0xFFEF4444)),
                  SizedBox(width: 4),
                  Text(
                    'Log Damage',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Button 3: Stock Scan (Clean white with blue barcode icon)
          Expanded(
            flex: 4,
            child: OutlinedButton(
              onPressed: () => _showStockScanModal(),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1E293B),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_scanner_rounded,
                      size: 15, color: Color(0xFF2563EB)),
                  SizedBox(width: 4),
                  Text(
                    'Stock Scan',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. Inbound Delivery Card
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildInboundDeliveryCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF), // Ice blue tint
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBAE6FD)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Pill Badge + ETA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'INBOUND DELIVERY TR-8842',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.access_time_rounded,
                      size: 13, color: Color(0xFF64748B)),
                  SizedBox(width: 3),
                  Text(
                    'ETA ~15m',
                    style: TextStyle(
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

          // Content Row: Thumbnail + Product & Route
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: CachedNetworkImage(
                    imageUrl:
                        'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=500',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cold Pressed Olive Oil (1L)',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '20 Units • Westend (Store 2) → Downtown',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFE0F2FE)),
          const SizedBox(height: 8),

          // Footer: Driver + Confirm & Add button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Driver: CargoVan #04',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() => _inboundConfirmed = true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Received 20 units into Downtown stock!'),
                      backgroundColor: Color(0xFF047857),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF047857), // Forest green
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_rounded,
                          size: 13, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Confirm & Add',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4. Segmented Filter Tabs
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSegmentedTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: _tabs.map((tab) {
          final isSelected = _activeTab == tab;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _activeTab = tab),
              borderRadius: BorderRadius.circular(9),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF0F172A)
                                .withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    tab,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 5. Search Bar
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            const Icon(
              Icons.search_rounded,
              color: Color(0xFF64748B),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.5,
                  color: Color(0xFF0F172A),
                ),
                decoration: const InputDecoration(
                  hintText: 'Search SKU, Barcode, or Brand...',
                  hintStyle: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (v) => setState(() {}),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.qr_code_scanner_rounded,
                color: Color(0xFF2563EB),
                size: 20,
              ),
              onPressed: () => _showStockScanModal(),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 6. Filter Chips Row
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildFilterChips() {
    final chips = [
      'All Stock (1,248)',
      'Low Stock (≤ min) • 14',
      'Out of Stock',
    ];

    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final chip = chips[i];
          final isSelected =
              (chip.startsWith('All') && _activeFilter == 'All Stock') ||
              (chip.startsWith('Low') && _activeFilter == 'Low Stock') ||
              (chip.startsWith('Out') && _activeFilter == 'Out of Stock');

          return InkWell(
            onTap: () {
              setState(() {
                if (chip.startsWith('All')) _activeFilter = 'All Stock';
                if (chip.startsWith('Low')) _activeFilter = 'Low Stock';
                if (chip.startsWith('Out')) _activeFilter = 'Out of Stock';
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Center(
                child: Text(
                  chip,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 7. Store Inventory Feed (Sorted by: Urgency)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildInventoryFeed() {
    final q = _searchCtrl.text.toLowerCase().trim();
    final items = _feedItems.where((item) {
      if (_activeFilter == 'Low Stock' && item['badgeType'] != 'low') {
        return false;
      }
      if (_activeFilter == 'Out of Stock') {
        return false; // None are completely 0 in this preview
      }
      if (q.isNotEmpty) {
        return item['name'].toString().toLowerCase().contains(q) ||
            item['sku'].toString().toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Section Header
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Store Inventory Feed',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                'Sorted by: Urgency',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Items List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final item = items[i];
              return _buildFeedCard(item);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeedCard(Map<String, dynamic> item) {
    final int stock = item['stock'] as int;
    final int minSafe = item['minSafe'] as int;
    final double progress = (stock / minSafe).clamp(0.0, 1.0);

    final bool isLow = item['badgeType'] == 'low';
    final Color barColor = isLow
        ? const Color(0xFFDC2626)
        : item['badgeType'] == 'reorder'
            ? const Color(0xFF818CF8)
            : const Color(0xFF10B981);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Thumbnail + Details + Status Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail with text badge
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 52,
                      height: 52,
                      child: CachedNetworkImage(
                        imageUrl: item['image'],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    left: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item['badgeText'],
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 10),

              // Title, SKU & Min safe
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'],
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item['sku']} • Min Safe: $minSafe',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Urgency / Status Pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: item['statusBg'],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item['status'],
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: item['statusColor'],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Stock Level Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 4.5,
              width: double.infinity,
              color: const Color(0xFFF1F5F9),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(color: barColor),
              ),
            ),
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 8),

          // Footer Action Row
          if (item['footerType'] == 'transfer') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.storefront_outlined,
                        size: 14, color: Color(0xFF2563EB)),
                    const SizedBox(width: 4),
                    Text(
                      item['footerText'],
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => _showRequestTransferModal(item['name']),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Request Transfer',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (item['footerType'] == 'audit') ...[
            Text(
              item['footerText'],
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF059669),
              ),
            ),
          ] else if (item['footerType'] == 'vendor') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item['footerText'],
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Color(0xFF475569),
                  ),
                ),
                InkWell(
                  onTap: () => _showVendorPoModal(item['name']),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFC7D2FE)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.post_add_rounded,
                            size: 12, color: Color(0xFF4338CA)),
                        SizedBox(width: 3),
                        Text(
                          'Add to Vendor PO',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4338CA),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 8. Recent Damage Incident Card
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildRecentDamageCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + Title + Timestamp
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.heart_broken_rounded,
                      size: 16, color: Color(0xFFEF4444)),
                  SizedBox(width: 6),
                  Text(
                    'Recent Damage Incident',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Text(
                'Today, 11:20 AM',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Details Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail with 3 DAMAGED overlay
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 54,
                      height: 54,
                      child: CachedNetworkImage(
                        imageUrl:
                            'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=500',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    left: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        '3 DAMAGED',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 7.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 10),

              // Vendor info & write-off
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tomato Puree 400g Glass Jars',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Vendor: FreshFoods Ltd • Reason: In-trans...',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.photo_camera_outlined,
                            size: 12, color: Color(0xFF2563EB)),
                        SizedBox(width: 3),
                        Text(
                          '2 Photos',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '•  -\$14.50 write-off',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Modals & Action Dialogs
  // ─────────────────────────────────────────────────────────────────────────
  void _showTransferModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Initiate Store Transfer',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Select Destination Store & Items to Transfer:',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: 'Westend (Store 2)',
              decoration: const InputDecoration(labelText: 'Destination Store'),
              items: const [
                DropdownMenuItem(
                    value: 'Westend (Store 2)',
                    child: Text('Store 2: Westend')),
                DropdownMenuItem(
                    value: 'Metro (Store 3)',
                    child: Text('Store 3: Metro Hub')),
              ],
              onChanged: (_) {},
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transfer run TR-8843 scheduled!'),
                  ),
                );
              },
              child: const Text('Confirm Transfer Order',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDamageModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Log Damaged / Spoiled Stock',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                labelText: 'SKU or Barcode',
                hintText: 'e.g. BRR-501',
              ),
            ),
            const SizedBox(height: 10),
            const TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Damaged Quantity',
                hintText: 'e.g. 2',
              ),
            ),
            const SizedBox(height: 10),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Reason for Write-off',
                hintText: 'e.g. In-transit breakage / expired',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Damage report logged for approval.'),
                  ),
                );
              },
              child: const Text('Submit Damage Report',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showStockScanModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text('Stock Scanner', style: TextStyle(fontFamily: 'Poppins')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.qr_code_2_rounded,
                    color: Colors.white70, size: 60),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Point camera at item barcode for instant stock audit.',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Stock verified: Basmati Royal Rice 5kg (6 units)'),
                ),
              );
            },
            child: const Text('Simulate Scan'),
          ),
        ],
      ),
    );
  }

  void _showRequestTransferModal(String productName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Request Transfer: $productName',
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 14)),
        content: const Text(
          'Request 10 units from Westend Store to Downtown Central?\nDriver pickup will be dispatched today.',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Transfer requested for "$productName"'),
                ),
              );
            },
            child: const Text('Send Request', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showVendorPoModal(String productName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add to Vendor Purchase Order',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 14)),
        content: Text(
          'Add 25 units of "$productName" to pending PO with supplier ITC Hub direct?',
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4338CA)),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Added "$productName" to Vendor PO draft.'),
                ),
              );
            },
            child: const Text('Add to PO', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
