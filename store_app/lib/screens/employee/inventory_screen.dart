import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../../config/app_constants.dart';
import '../../models/inventory_model.dart';
import '../../models/store_model.dart';
import '../../models/supplier_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/store_provider.dart';
import '../../widgets/store_header_widget.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  int _activeTabIndex = 0; // 0: Stock & Audits, 1: Transfers, 2: Damaged Log
  String _activeFilter = 'All Stock'; // All Stock | Low Stock | Out of Stock

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storeId = context.watch<StoreProvider>().selectedStore?.id ?? '';
    final invProvider = context.watch<InventoryProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: _activeTabIndex == 2
          ? FloatingActionButton.extended(
              onPressed: () => _showDamageModal(context),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'Log Damaged Stock',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 4,
            )
          : _activeTabIndex == 1
              ? FloatingActionButton.extended(
                  onPressed: () => _showTransferModal(context),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                  label: const Text(
                    'Initiate Transfer',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 4,
                )
              : null,
      body: SafeArea(
        child: StreamBuilder<List<InventoryModel>>(
          stream: invProvider.watchInventory(storeId),
          builder: (context, invSnap) {
            final inventory = invSnap.data ?? [];
            final lowStockCount = inventory.where((i) => i.isLowStock).length;
            final outOfStockCount = inventory.where((i) => i.isOutOfStock).length;

            return StreamBuilder<List<StockTransfer>>(
              stream: invProvider.watchAllTransfers(storeId),
              builder: (context, transferSnap) {
                final allTransfers = transferSnap.data ?? [];
                final inboundPending = allTransfers
                    .where((t) =>
                        t.destinationStoreId == storeId &&
                        t.status == TransferStatus.pending)
                    .toList();

                return StreamBuilder<List<DamagedProduct>>(
                  stream: invProvider.watchDamageReports(storeId),
                  builder: (context, damageSnap) {
                    final allDamage = damageSnap.data ?? [];
                    final pendingDamageCount =
                        allDamage.where((d) => d.status == 'pending').length;

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 80),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Top Store & Shift Header
                          const StoreHeaderWidget(
                            title: 'Inventory Stock',
                            subtitle: 'REAL-TIME STORE INVENTORY • Live Sync',
                          ),

                          const SizedBox(height: 8),

                          // 2. Summary KPI Metric Cards
                          _buildKpiMetricsRow(
                            totalSkus: inventory.length,
                            lowStockCount: lowStockCount,
                            inboundPendingCount: inboundPending.length,
                          ),

                          const SizedBox(height: 12),

                          // 3. Quick Action Buttons Row (+ Transfer, Log Damage, Stock Scan)
                          _buildQuickActionsRow(context),

                          const SizedBox(height: 14),

                          // 4. Inbound Delivery Alert Banner if any transfer is incoming
                          if (inboundPending.isNotEmpty) ...[
                            _buildInboundAlertCard(context, inboundPending.first),
                            const SizedBox(height: 14),
                          ],

                          // 5. Segmented Filter Tabs
                          _buildSegmentedTabs(
                            transferBadgeCount: inboundPending.length,
                            damageBadgeCount: pendingDamageCount,
                          ),

                          const SizedBox(height: 14),

                          // Tab Body Content
                          if (_activeTabIndex == 0) ...[
                            // Stock & Audits Tab
                            _buildSearchBar(),
                            const SizedBox(height: 10),
                            _buildFilterChips(
                              totalCount: inventory.length,
                              lowCount: lowStockCount,
                              outCount: outOfStockCount,
                            ),
                            const SizedBox(height: 14),
                            _buildInventoryFeed(inventory),
                          ] else if (_activeTabIndex == 1) ...[
                            // Transfers Tab
                            _buildTransfersTab(context, allTransfers, storeId),
                          ] else ...[
                            // Damaged Log Tab
                            _buildDamagedLogTab(context, allDamage),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 1. KPI Metric Row
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildKpiMetricsRow({
    required int totalSkus,
    required int lowStockCount,
    required int inboundPendingCount,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Card 1: ACTIVE SKUS
          Expanded(
            child: _buildMetricCard(
              title: 'STORE SKUS',
              icon: Icons.inventory_2_outlined,
              iconColor: const Color(0xFF2563EB),
              value: '$totalSkus',
              badge: Row(
                children: [
                  const Icon(Icons.sync_rounded, size: 12, color: Color(0xFF10B981)),
                  const SizedBox(width: 3),
                  Text(
                    'Live Firestore',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 9.5,
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
              value: '$lowStockCount',
              valueColor: lowStockCount > 0 ? const Color(0xFFEF4444) : const Color(0xFF0F172A),
              badge: Text(
                lowStockCount > 0 ? 'Restock needed' : 'Optimal level',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: lowStockCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF10B981),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Card 3: INBOUND TRANSFERS
          Expanded(
            child: _buildMetricCard(
              title: 'INBOUND',
              icon: Icons.local_shipping_outlined,
              iconColor: const Color(0xFF2563EB),
              value: '$inboundPendingCount',
              valueColor: inboundPendingCount > 0 ? const Color(0xFF2563EB) : const Color(0xFF0F172A),
              badge: Text(
                inboundPendingCount > 0 ? 'Pending receive' : 'No shipments',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: inboundPendingCount > 0 ? const Color(0xFF2563EB) : const Color(0xFF64748B),
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
  Widget _buildQuickActionsRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Button 1: + Transfer
          Expanded(
            flex: 4,
            child: ElevatedButton(
              onPressed: () => _showTransferModal(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
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

          // Button 2: Log Damage
          Expanded(
            flex: 4,
            child: OutlinedButton(
              onPressed: () => _showDamageModal(context),
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

          // Button 3: Stock Scan
          Expanded(
            flex: 4,
            child: OutlinedButton(
              onPressed: () => _showStockScanModal(context),
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
  // 3. Inbound Delivery Alert Banner
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildInboundAlertCard(BuildContext context, StockTransfer transfer) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'INBOUND SHIPMENT • ${transfer.id.length > 8 ? transfer.id.substring(0, 8).toUpperCase() : transfer.id.toUpperCase()}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF2563EB)),
                  SizedBox(width: 3),
                  Text(
                    'Arrived at Dock',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.local_shipping_rounded,
                    color: Color(0xFF2563EB), size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transfer.productName,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${transfer.quantity} Units • From ${transfer.sourceStoreId} • By ${transfer.initiatedByUserName}',
                      style: const TextStyle(
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
          if (transfer.notes != null && transfer.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Notes: ${transfer.notes}',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Color(0xFF64748B),
              ),
            ),
          ],
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFE0F2FE)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Requires Stock Sign-off',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _confirmInboundTransfer(context, transfer),
                icon: const Icon(Icons.check_rounded, size: 14),
                label: Text('Receive +${transfer.quantity} units'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmInboundTransfer(
      BuildContext context, StockTransfer transfer) async {
    final auth = context.read<AuthProvider>();
    try {
      await context.read<InventoryProvider>().confirmTransfer(
            transferId: transfer.id,
            userId: auth.currentUser?.id ?? 'emp_01',
            userName: auth.currentUser?.name ?? 'Store Employee',
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✓ Received ${transfer.quantity} units of ${transfer.productName} into live inventory!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error receiving transfer: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4. Segmented Tabs
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSegmentedTabs({
    required int transferBadgeCount,
    required int damageBadgeCount,
  }) {
    final tabs = [
      'Stock & Audits',
      transferBadgeCount > 0 ? 'Transfers ($transferBadgeCount)' : 'Transfers',
      damageBadgeCount > 0 ? 'Damaged Log ($damageBadgeCount)' : 'Damaged Log',
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _activeTabIndex == index;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _activeTabIndex = index),
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
                            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    tabs[index],
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
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
            const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
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
                  hintText: 'Search product, SKU, or category...',
                  hintStyle: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.qr_code_scanner_rounded,
                  color: Color(0xFF2563EB), size: 20),
              onPressed: () => _showStockScanModal(context),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 6. Filter Chips
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildFilterChips({
    required int totalCount,
    required int lowCount,
    required int outCount,
  }) {
    final chips = [
      'All Stock ($totalCount)',
      'Low Stock (≤ min) • $lowCount',
      'Out of Stock ($outCount)',
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
              (i == 0 && _activeFilter == 'All Stock') ||
              (i == 1 && _activeFilter == 'Low Stock') ||
              (i == 2 && _activeFilter == 'Out of Stock');

          return InkWell(
            onTap: () {
              setState(() {
                if (i == 0) _activeFilter = 'All Stock';
                if (i == 1) _activeFilter = 'Low Stock';
                if (i == 2) _activeFilter = 'Out of Stock';
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2563EB) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
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
  // 7. Store Inventory Feed (Stock & Audits)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildInventoryFeed(List<InventoryModel> allItems) {
    final query = _searchCtrl.text.toLowerCase().trim();
    final items = allItems.where((item) {
      if (_activeFilter == 'Low Stock' && !item.isLowStock) return false;
      if (_activeFilter == 'Out of Stock' && !item.isOutOfStock) return false;
      if (query.isNotEmpty) {
        return item.productName.toLowerCase().contains(query) ||
            item.category.toLowerCase().contains(query) ||
            item.productId.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Store Inventory Feed',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                '${items.length} items',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (items.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _buildLiveInventoryCard(items[i]),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.inventory_2_outlined,
                      size: 40, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 10),
                  Text(
                    allItems.isEmpty
                        ? 'No products initialized in this store yet.\nItems will appear when added in Product Management.'
                        : 'No items match the search query or filter.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLiveInventoryCard(InventoryModel item) {
    final int stock = item.currentStock;
    final int minSafe = item.minimumStockLevel > 0
        ? item.minimumStockLevel
        : AppConstants.defaultMinStockLevel;
    final double progress = (stock / minSafe).clamp(0.0, 1.0);

    final bool isOut = item.isOutOfStock;
    final bool isLow = item.isLowStock && !isOut;

    final Color statusColor = isOut
        ? const Color(0xFFDC2626)
        : isLow
            ? const Color(0xFFD97706)
            : const Color(0xFF166534);

    final Color statusBg = isOut
        ? const Color(0xFFFEE2E2)
        : isLow
            ? const Color(0xFFFEF3C7)
            : const Color(0xFFDCFCE7);

    final String statusText = isOut
        ? 'OUT OF STOCK'
        : isLow
            ? 'LOW ($stock LEFT)'
            : 'IN STOCK ($stock)';

    final Color barColor = isOut
        ? const Color(0xFFDC2626)
        : isLow
            ? const Color(0xFFF59E0B)
            : const Color(0xFF10B981);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOut
              ? const Color(0xFFFCA5A5)
              : isLow
                  ? const Color(0xFFFDE68A)
                  : const Color(0xFFE2E8F0),
        ),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product thumbnail / placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.imageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _fallbackImage(item.category),
                        )
                      : _fallbackImage(item.category),
                ),
              ),
              const SizedBox(width: 12),

              // Title, Category, and Progress
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.category} • Min Safe: $minSafe units',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Stock Level Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: AlwaysStoppedAnimation<Color>(barColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
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
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // Action Buttons: Audit Stock & Log Damage
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showStockScanModal(context, preselectedItem: item),
                  icon: const Icon(Icons.rule_rounded, size: 14),
                  label: const Text('Audit Count'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    foregroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showDamageModal(context, preselectedItem: item),
                  icon: const Icon(Icons.assignment_late_outlined, size: 14),
                  label: const Text('Log Damage'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    foregroundColor: const Color(0xFFDC2626),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _showTransferModal(context, preselectedItem: item),
                icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                tooltip: 'Transfer to another store',
                color: const Color(0xFF64748B),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF8FAFC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fallbackImage(String category) {
    return Container(
      color: const Color(0xFFEFF6FF),
      child: const Center(
        child: Icon(Icons.inventory_2_rounded, color: Color(0xFF2563EB), size: 24),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 8. Tab 1: Transfers View
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTransfersTab(
      BuildContext context, List<StockTransfer> allTransfers, String currentStoreId) {
    final inbound = allTransfers
        .where((t) => t.destinationStoreId == currentStoreId)
        .toList();
    final outbound = allTransfers
        .where((t) => t.sourceStoreId == currentStoreId)
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section 1: Inbound Shipments
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'INBOUND TRANSFERS',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '${inbound.where((t) => t.status == TransferStatus.pending).length} Pending',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (inbound.isNotEmpty)
            ...inbound.map((t) => _buildTransferItemCard(context, t, isIncoming: true))
          else
            _buildEmptyState('No inbound shipments pending or received for this store.'),

          const SizedBox(height: 20),

          // Section 2: Outbound Shipments
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'OUTBOUND DISPATCHES',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '${outbound.length} Total',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (outbound.isNotEmpty)
            ...outbound.map((t) => _buildTransferItemCard(context, t, isIncoming: false))
          else
            _buildEmptyState('No outbound transfers initiated from this store.'),
        ],
      ),
    );
  }

  Widget _buildTransferItemCard(
      BuildContext context, StockTransfer transfer, {required bool isIncoming}) {
    final isPending = transfer.status == TransferStatus.pending;
    final isConfirmed = transfer.status == TransferStatus.confirmed;

    final Color statusColor = isConfirmed
        ? const Color(0xFF10B981)
        : isPending
            ? const Color(0xFFF59E0B)
            : const Color(0xFF64748B);

    final Color statusBg = isConfirmed
        ? const Color(0xFFDCFCE7)
        : isPending
            ? const Color(0xFFFEF3C7)
            : const Color(0xFFF1F5F9);

    final String statusLabel = isConfirmed
        ? 'RECEIVED ✓'
        : isPending
            ? 'IN TRANSIT'
            : 'CANCELLED';

    final dateStr =
        '${transfer.initiatedAt.day.toString().padLeft(2, '0')}/${transfer.initiatedAt.month.toString().padLeft(2, '0')} ${transfer.initiatedAt.hour.toString().padLeft(2, '0')}:${transfer.initiatedAt.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPending ? const Color(0xFFBAE6FD) : const Color(0xFFE2E8F0),
        ),
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
                '${isIncoming ? "FROM" : "TO"}: ${isIncoming ? transfer.sourceStoreId : transfer.destinationStoreId} • $dateStr',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(10),
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
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  transfer.productName,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Text(
                '${transfer.quantity} units',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          Text(
            'Initiated by ${transfer.initiatedByUserName}',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: Color(0xFF64748B),
            ),
          ),
          if (transfer.notes != null && transfer.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Notes: ${transfer.notes}',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Color(0xFF475569),
              ),
            ),
          ],
          if (isIncoming && isPending) ...[
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _confirmInboundTransfer(context, transfer),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(double.infinity, 38),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text('Confirm & Receive (+${transfer.quantity} units)'),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 9. Tab 2: Damaged Log View
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildDamagedLogTab(BuildContext context, List<DamagedProduct> reports) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'LOGGED DAMAGE & INCIDENTS',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '${reports.length} Incidents',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFDC2626),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (reports.isNotEmpty)
            ...reports.map((report) => _buildDamageReportCard(report))
          else
            _buildEmptyState('No damage incidents reported for this store yet.\nTap "Log Damaged Stock" to report breakage, leakage, or expiry.'),
        ],
      ),
    );
  }

  Widget _buildDamageReportCard(DamagedProduct item) {
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
        ? 'APPROVED BY MANAGER'
        : isPending
            ? 'PENDING REVIEW'
            : 'REJECTED / RESTORED';

    final dateStr =
        '${item.reportedAt.day.toString().padLeft(2, '0')}/${item.reportedAt.month.toString().padLeft(2, '0')} ${item.reportedAt.hour.toString().padLeft(2, '0')}:${item.reportedAt.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPending ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
        ),
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
                'ID: ${item.id.length > 8 ? item.id.substring(0, 8).toUpperCase() : item.id.toUpperCase()} • $dateStr',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(10),
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
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.productName,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Text(
                '-₹${item.estimatedLoss.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFDC2626),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${item.quantity} units • Reason: ${item.reason}',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          Text(
            'Reported by: ${item.reportedByUserName}',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10.5,
              color: Color(0xFF64748B),
            ),
          ),
          if (item.notes != null && item.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Notes: ${item.notes}',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.inbox_rounded, size: 36, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11.5,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Modals & Bottom Sheets (Damage, Transfer, Stock Scan)
  // ─────────────────────────────────────────────────────────────────────────

  void _showDamageModal(BuildContext context, {InventoryModel? preselectedItem}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EmployeeLogDamageSheet(preselectedItem: preselectedItem),
    );
  }

  void _showTransferModal(BuildContext context, {InventoryModel? preselectedItem}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EmployeeInitiateTransferSheet(preselectedItem: preselectedItem),
    );
  }

  void _showStockScanModal(BuildContext context, {InventoryModel? preselectedItem}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _StockScanAuditSheet(preselectedItem: preselectedItem),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Employee Log Damage Bottom Sheet Form
// ─────────────────────────────────────────────────────────────────────────────
class _EmployeeLogDamageSheet extends StatefulWidget {
  final InventoryModel? preselectedItem;
  const _EmployeeLogDamageSheet({this.preselectedItem});

  @override
  State<_EmployeeLogDamageSheet> createState() => _EmployeeLogDamageSheetState();
}

class _EmployeeLogDamageSheetState extends State<_EmployeeLogDamageSheet> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedProductId;
  String? _selectedProductName;
  int _quantity = 1;
  int _availableStock = 0;
  String _reason = AppConstants.damageReasons.first;
  double _unitPrice = 50.0;
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedItem != null) {
      _selectedProductId = widget.preselectedItem!.productId;
      _selectedProductName = widget.preselectedItem!.productName;
      _availableStock = widget.preselectedItem!.currentStock;
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product')),
      );
      return;
    }
    if (_availableStock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot log damage for $_selectedProductName: Available stock is 0 units.'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }
    if (_quantity > _availableStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot log $_quantity units as damaged. Only $_availableStock units available in stock.'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final auth = context.read<AuthProvider>();
    final storeProvider = context.read<StoreProvider>();
    final storeId = storeProvider.selectedStore?.id ?? 'store_1';

    try {
      await context.read<InventoryProvider>().reportDamage(
            storeId: storeId,
            productId: _selectedProductId!,
            productName: _selectedProductName ?? 'Product',
            quantity: _quantity,
            estimatedLoss: _unitPrice * _quantity,
            reason: _reason,
            userId: auth.currentUser?.id ?? 'emp_01',
            userName: auth.currentUser?.name ?? 'Store Employee',
            notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✓ Reported $_quantity × $_selectedProductName as damaged. Updated in Manager Hub in real-time.'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $errorMsg'),
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
    final products = productProvider.products;

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
                    'Log Damaged Stock',
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
              const Text(
                'Deducts available stock and flags incident for Manager write-off approval.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 14),

              // Product Selector
              if (widget.preselectedItem != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2_rounded,
                          color: Color(0xFF2563EB), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.preselectedItem!.productName,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        'Stock: ${widget.preselectedItem!.currentStock}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Select Product *',
                    border: OutlineInputBorder(),
                  ),
                  items: products
                      .map((p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(p.name, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (val) async {
                    if (val == null) return;
                    final matched = products.firstWhere((p) => p.id == val);
                    int stock = 0;
                    try {
                      final currentStoreId =
                          context.read<StoreProvider>().selectedStore?.id ?? 'store_1';
                      final item = await context
                          .read<InventoryProvider>()
                          .getItem(currentStoreId, val);
                      stock = item?.currentStock ?? 0;
                    } catch (_) {}
                    if (mounted) {
                      setState(() {
                        _selectedProductId = val;
                        _selectedProductName = matched.name;
                        _unitPrice = matched.sellingPrice;
                        _availableStock = stock;
                      });
                    }
                  },
                ),
              if (_selectedProductId != null && widget.preselectedItem == null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Row(
                    children: [
                      Icon(
                        _availableStock > 0
                            ? Icons.check_circle_outline
                            : Icons.warning_amber_rounded,
                        size: 14,
                        color: _availableStock > 0
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Available stock: $_availableStock units',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: _availableStock > 0
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),

              // Reason
              DropdownButtonFormField<String>(
                initialValue: _reason,
                decoration: const InputDecoration(
                  labelText: 'Damage / Shrinkage Reason *',
                  border: OutlineInputBorder(),
                ),
                items: AppConstants.damageReasons
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => _reason = v ?? _reason),
              ),
              const SizedBox(height: 12),

              // Quantity & Unit Cost
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: '1',
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Damaged Qty *',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => setState(() => _quantity = int.tryParse(v) ?? 1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: _unitPrice.toStringAsFixed(2),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Estimated Cost/Unit (₹)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => setState(() => _unitPrice = double.tryParse(v) ?? 50.0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Total Loss Calculation Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Incident Loss:',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF991B1B),
                      ),
                    ),
                    Text(
                      '₹${(_quantity * _unitPrice).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Notes
              TextField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Damage Notes (e.g. dropped on floor, seal broken)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),

              // Submit Button
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  _saving ? 'Saving...' : 'Submit Incident Report to Manager',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Employee Initiate Transfer Bottom Sheet Form
// ─────────────────────────────────────────────────────────────────────────────
class _EmployeeInitiateTransferSheet extends StatefulWidget {
  final InventoryModel? preselectedItem;
  const _EmployeeInitiateTransferSheet({this.preselectedItem});

  @override
  State<_EmployeeInitiateTransferSheet> createState() =>
      _EmployeeInitiateTransferSheetState();
}

class _EmployeeInitiateTransferSheetState
    extends State<_EmployeeInitiateTransferSheet> {
  final _formKey = GlobalKey<FormState>();
  StoreModel? _destinationStore;
  String? _selectedProductId;
  String? _selectedProductName;
  int _quantity = 1;
  int _availableStock = 0;
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedItem != null) {
      _selectedProductId = widget.preselectedItem!.productId;
      _selectedProductName = widget.preselectedItem!.productName;
      _availableStock = widget.preselectedItem!.currentStock;
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_destinationStore == null || _selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select destination store and product')),
      );
      return;
    }
    if (_quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid transfer quantity')),
      );
      return;
    }

    if (_availableStock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot transfer $_selectedProductName: No stock available in this store (0 units).'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }
    if (_quantity > _availableStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot transfer $_quantity units. Only $_availableStock units available in this store.'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final auth = context.read<AuthProvider>();
    final storeProvider = context.read<StoreProvider>();
    final sourceStoreId = storeProvider.selectedStore?.id ?? 'store_1';

    try {
      await context.read<InventoryProvider>().initiateTransfer(
            sourceStoreId: sourceStoreId,
            destinationStoreId: _destinationStore!.id,
            productId: _selectedProductId!,
            productName: _selectedProductName ?? 'Product',
            quantity: _quantity,
            userId: auth.currentUser?.id ?? 'emp_01',
            userName: auth.currentUser?.name ?? 'Store Employee',
            notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✓ Dispatched $_quantity × $_selectedProductName to ${_destinationStore!.name}!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $errorMsg'),
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
    final storeProvider = context.watch<StoreProvider>();
    final currentStore = storeProvider.selectedStore;
    final otherStores =
        storeProvider.stores.where((s) => s.id != currentStore?.id).toList();
    final productProvider = context.watch<ProductProvider>();
    final products = productProvider.products;

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
                    'Initiate Stock Transfer',
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
              const Text(
                'Dispatch inventory to another store. Stock is deducted and held in-transit until received.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 14),

              // Destination Store Dropdown
              DropdownButtonFormField<StoreModel>(
                decoration: const InputDecoration(
                  labelText: 'Destination Store *',
                  border: OutlineInputBorder(),
                ),
                items: otherStores
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text('${s.name} (${s.city})'),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _destinationStore = val),
              ),
              const SizedBox(height: 12),

              // Product Selector
              if (widget.preselectedItem != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2_rounded,
                          color: Color(0xFF2563EB), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.preselectedItem!.productName,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        'Available: $_availableStock',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Product to Transfer *',
                    border: OutlineInputBorder(),
                  ),
                  items: products
                      .map((p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(p.name, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (val) async {
                    if (val == null) return;
                    final matched = products.firstWhere((p) => p.id == val);
                    int stock = 0;
                    try {
                      final currentStoreId =
                          context.read<StoreProvider>().selectedStore?.id ?? 'store_1';
                      final item = await context
                          .read<InventoryProvider>()
                          .getItem(currentStoreId, val);
                      stock = item?.currentStock ?? 0;
                    } catch (_) {}
                    if (mounted) {
                      setState(() {
                        _selectedProductId = val;
                        _selectedProductName = matched.name;
                        _availableStock = stock;
                      });
                    }
                  },
                ),
              if (_selectedProductId != null && widget.preselectedItem == null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Row(
                    children: [
                      Icon(
                        _availableStock > 0
                            ? Icons.check_circle_outline
                            : Icons.warning_amber_rounded,
                        size: 14,
                        color: _availableStock > 0
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Available in this store: $_availableStock units',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: _availableStock > 0
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),

              // Quantity Stepper
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Transfer Quantity:',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: const Color(0xFF2563EB),
                      ),
                      Text(
                        '$_quantity',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _quantity++),
                        icon: const Icon(Icons.add_circle_outline),
                        color: const Color(0xFF2563EB),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Notes
              TextField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Dispatch / Cargo Notes',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),

              // Submit Button
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  _saving ? 'Initiating Dispatch...' : 'Dispatch Transfer Order',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stock Scan & Physical Audit Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _StockScanAuditSheet extends StatefulWidget {
  final InventoryModel? preselectedItem;
  const _StockScanAuditSheet({this.preselectedItem});

  @override
  State<_StockScanAuditSheet> createState() => _StockScanAuditSheetState();
}

class _StockScanAuditSheetState extends State<_StockScanAuditSheet> {
  String? _selectedProductId;
  String? _selectedProductName;
  int _systemStock = 0;
  int _countedStock = 0;
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedItem != null) {
      _selectedProductId = widget.preselectedItem!.productId;
      _selectedProductName = widget.preselectedItem!.productName;
      _systemStock = widget.preselectedItem!.currentStock;
      _countedStock = widget.preselectedItem!.currentStock;
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitAudit() async {
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product to audit')),
      );
      return;
    }

    setState(() => _saving = true);
    final auth = context.read<AuthProvider>();
    final storeProvider = context.read<StoreProvider>();
    final storeId = storeProvider.selectedStore?.id ?? 'store_1';

    try {
      await context.read<InventoryProvider>().logStockAudit(
            storeId: storeId,
            productId: _selectedProductId!,
            productName: _selectedProductName ?? 'Product',
            countedQty: _countedStock,
            currentStock: _systemStock,
            userId: auth.currentUser?.id ?? 'emp_01',
            userName: auth.currentUser?.name ?? 'Store Employee',
            notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          );

      if (mounted) {
        Navigator.pop(context);
        final variance = _countedStock - _systemStock;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(variance == 0
                ? '✓ Stock verified: $_selectedProductName count confirmed at $_countedStock units.'
                : '✓ Stock audit saved: Adjusted $_selectedProductName by ${variance > 0 ? "+$variance" : "$variance"} units in Firestore.'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $errorMsg'),
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
    final products = productProvider.products;
    final int variance = _countedStock - _systemStock;

    final Color varianceColor = variance == 0
        ? const Color(0xFF10B981)
        : variance > 0
            ? const Color(0xFF2563EB)
            : const Color(0xFFDC2626);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 16,
        right: 16,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.qr_code_scanner_rounded,
                        color: Color(0xFF2563EB), size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Stock Scan & Physical Audit',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Text(
              'Count on-shelf physical stock and sync live inventory adjustments directly to Firestore.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 14),

            // Product Selection
            if (widget.preselectedItem != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF10B981), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.preselectedItem!.productName,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Select Product to Audit *',
                  border: OutlineInputBorder(),
                ),
                items: products
                    .map((p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(p.name, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (val) async {
                  final matched = products.firstWhere((p) => p.id == val);
                  final storeId =
                      context.read<StoreProvider>().selectedStore?.id ?? 'store_1';
                  final inv = await context
                      .read<InventoryProvider>()
                      .getItem(storeId, val!);
                  setState(() {
                    _selectedProductId = val;
                    _selectedProductName = matched.name;
                    _systemStock = inv?.currentStock ?? 0;
                    _countedStock = _systemStock;
                  });
                },
              ),
            const SizedBox(height: 16),

            // Comparison Matrix: System vs Physical Count
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  // Expected System Stock
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'SYSTEM STOCK',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_systemStock',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const Text(
                          'Recorded',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(width: 1, height: 48, color: const Color(0xFFE2E8F0)),

                  // Physical Count Stepper
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'PHYSICAL COUNT',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: _countedStock > 0
                                  ? () => setState(() => _countedStock--)
                                  : null,
                              icon: const Icon(Icons.remove_circle_outline),
                              color: const Color(0xFF2563EB),
                              iconSize: 26,
                            ),
                            Text(
                              '$_countedStock',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(() => _countedStock++),
                              icon: const Icon(Icons.add_circle_outline),
                              color: const Color(0xFF2563EB),
                              iconSize: 26,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Variance Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: varianceColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: varianceColor.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    variance == 0
                        ? 'Count matches system stock (Zero variance)'
                        : variance < 0
                            ? 'Stock Shortage Discrepancy:'
                            : 'Stock Surplus Discrepancy:',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: varianceColor,
                    ),
                  ),
                  Text(
                    variance == 0
                        ? '✓ Verified'
                        : variance > 0
                            ? '+$variance units'
                            : '$variance units',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: varianceColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Audit Note
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Audit Note / Discrepancy Reason (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),

            // Submit Button
            ElevatedButton(
              onPressed: _saving ? null : _submitAudit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                _saving
                    ? 'Reconciling Stock...'
                    : variance == 0
                        ? 'Confirm Physical Audit'
                        : 'Reconcile & Update Live Inventory in Firestore',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
