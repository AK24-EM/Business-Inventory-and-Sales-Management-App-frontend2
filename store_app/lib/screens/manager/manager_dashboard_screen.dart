import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../widgets/store_header_widget.dart';
import '../../providers/auth_provider.dart';
import '../../providers/store_provider.dart';
import '../../providers/sales_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../models/user_model.dart';
import '../../models/sale_model.dart';
import '../../models/inventory_model.dart';
import '../../models/purchase_order_model.dart';
import '../../services/purchase_order_service.dart';

/// Modern, enterprise-ready Store Manager Dashboard.
/// Matches the employee-side UI design: blue gradient banner, segmented tabs,
/// icon-badge KPI cards, primary action + small tile layout.
class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  String _activeTab = 'Overview';

  @override
  Widget build(BuildContext context) {
    final storeProvider = context.watch<StoreProvider>();
    final authProvider = context.watch<AuthProvider>();
    final salesProvider = context.watch<SalesProvider>();
    final inventoryProvider = context.watch<InventoryProvider>();
    final user = authProvider.currentUser;
    final store = storeProvider.selectedStore;
    final storeId = store?.id ?? '';

    if (storeId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Please select a store')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF2563EB),
          onRefresh: () async {
            await Future.wait([
              storeProvider.loadStores(),
              Future.delayed(const Duration(milliseconds: 500)),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StoreHeaderWidget(
                  title: 'Manager Hub',
                  subtitle: 'STORE MANAGER ON DUTY • Floor Supervision',
                  onNotificationTap: () => context.go('/manager/notifications'),
                  onStoreTap: () => _showStoreSwitcherModal(context, storeProvider),
                  onAvatarTap: () => _showProfileModal(context, user, authProvider),
                ),
                const SizedBox(height: 10),
                _buildSegmentedTabs(),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildManagerGreetingBanner(user?.name ?? 'Manager', store?.name),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildQuickActionStation(),
                ),
                const SizedBox(height: 14),
                
                // Real-time KPIs with Firestore data
                StreamBuilder<List<SaleModel>>(
                  stream: salesProvider.watchTodaySales(storeId),
                  builder: (context, salesSnap) {
                    final sales = salesSnap.data ?? [];
                    final todayRevenue = sales.fold<double>(0, (sum, sale) => sum + sale.totalAmount);
                    final saleCount = sales.length;
                    
                    return StreamBuilder<List<InventoryModel>>(
                      stream: inventoryProvider.watchLowStock(storeId),
                      builder: (context, invSnap) {
                        final lowStock = invSnap.data ?? [];
                        final criticalStock = lowStock.where((inv) => inv.currentStock < 5).length;
                        
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _buildInboundDeliveryCard(storeId, user),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: _buildHeroKPIGrid(
                                todayRevenue: todayRevenue,
                                saleCount: saleCount,
                                lowStockCount: lowStock.length,
                                criticalStockCount: criticalStock,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: _buildFestivalSurgeCard(),
                            ),
                            const SizedBox(height: 14),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: _buildTillsSupervisionSection(sales),
                            ),
                            const SizedBox(height: 14),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: _buildCriticalStockSection(lowStock),
                            ),
                            const SizedBox(height: 14),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: _buildPendingApprovalsSection(storeId, user),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedTabs() {
    final tabs = ['Overview', 'Products', 'Restock', 'Festivals', 'Analytics', 'Approvals', 'Stock', 'Reports'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = _activeTab == tab;
          final hasBadge = tab == 'Approvals' || tab == 'Restock';
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() => _activeTab = tab);
                if (tab == 'Stock') {
                  context.go('/manager/inventory');
                } else if (tab == 'Products') {
                  context.go('/manager/products');
                } else if (tab == 'Reports') {
                  context.go('/manager/reports');
                } else if (tab == 'Approvals') {
                  context.go('/manager/purchase-orders');
                } else if (tab == 'Restock') {
                  context.go('/manager/restocking');
                } else if (tab == 'Festivals') {
                  context.go('/manager/festivals');
                } else if (tab == 'Analytics') {
                  context.go('/manager/analytics');
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2563EB) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.22), blurRadius: 6, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasBadge) ...[
                      Container(
                        width: 6, height: 6,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      tab,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildManagerGreetingBanner(String managerName, String? storeName) {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    final dateStr = DateFormat('EEEE, d MMM').format(now);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.26), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        managerName.isNotEmpty ? managerName[0].toUpperCase() : 'M',
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 14, height: 14,
                      decoration: BoxDecoration(color: const Color(0xFF10B981), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting, $managerName',
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.2),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                          child: const Text(
                            'MANAGER ON DUTY • AUDIT ACTIVE',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 9.5, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.3),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(dateStr, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.white.withValues(alpha: 0.85))),
                      ],
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _showStoreSwitcherModal(context, context.read<StoreProvider>()),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.store_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF6EE7B7), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Floor Audit Status', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Color(0xFFE2E8F0))),
                      Text(
                        storeName != null ? '$storeName • All Tills Active' : 'Downtown Central • All Tills Active',
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => context.go('/manager/reports'),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.insights_rounded, size: 13, color: Color(0xFF1E3A8A)),
                        SizedBox(width: 4),
                        Text('Reports', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1E3A8A))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionStation() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 5,
              child: InkWell(
                onTap: () => context.go('/manager/restocking'),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF065F46), Color(0xFF059669)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF059669).withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.autorenew_rounded, color: Color(0xFF059669), size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Smart Restock', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                            Text('Auto-Order Low SKUs', style: TextStyle(fontFamily: 'Poppins', fontSize: 10.5, color: Color(0xFFA7F3D0))),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: _buildSmallActionTile(
                title: 'Products',
                subtitle: 'Manage & Add',
                icon: Icons.inventory_rounded,
                iconColor: const Color(0xFF7C3AED),
                bgColor: const Color(0xFFF5F3FF),
                borderColor: const Color(0xFFDDD6FE),
                onTap: () => context.go('/manager/products'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: _buildSmallActionTile(
                title: 'Transfer',
                subtitle: 'Move Stock',
                icon: Icons.swap_horiz_rounded,
                iconColor: const Color(0xFF2563EB),
                bgColor: const Color(0xFFEFF6FF),
                borderColor: const Color(0xFFBFDBFE),
                onTap: () => context.go('/manager/transfers'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: _buildSmallActionTile(
                title: 'Festivals',
                subtitle: 'Surge Plan',
                icon: Icons.celebration_rounded,
                iconColor: const Color(0xFFD97706),
                bgColor: const Color(0xFFFFFBEB),
                borderColor: const Color(0xFFFDE68A),
                onTap: () => context.go('/manager/festivals'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildSmallActionTile(
                title: 'Analytics Hub',
                subtitle: 'Revenue & Trends',
                icon: Icons.auto_graph_rounded,
                iconColor: const Color(0xFF7C3AED),
                bgColor: const Color(0xFFF5F3FF),
                borderColor: const Color(0xFFDDD6FE),
                onTap: () => context.go('/manager/analytics'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSmallActionTile(
                title: 'Customer RFM',
                subtitle: 'VIPs & Churn',
                icon: Icons.people_alt_rounded,
                iconColor: const Color(0xFFDB2777),
                bgColor: const Color(0xFFFDF2F8),
                borderColor: const Color(0xFFFBCFE8),
                onTap: () => context.go('/manager/customer-analytics'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSmallActionTile(
                title: 'Procure PO',
                subtitle: 'Vendor Orders',
                icon: Icons.local_shipping_rounded,
                iconColor: const Color(0xFF047857),
                bgColor: const Color(0xFFECFDF5),
                borderColor: const Color(0xFFA7F3D0),
                onTap: () => context.go('/manager/purchase-orders'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSmallActionTile(
                title: 'Damage Log',
                subtitle: 'Shrinkage',
                icon: Icons.broken_image_rounded,
                iconColor: const Color(0xFFDC2626),
                bgColor: const Color(0xFFFEF2F2),
                borderColor: const Color(0xFFFECACA),
                onTap: () => context.go('/manager/damaged'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: borderColor, width: 0.5)),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(subtitle, style: const TextStyle(fontFamily: 'Poppins', fontSize: 9, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildFestivalSurgeCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C2D12), Color(0xFFC2410C), Color(0xFFEA580C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA580C).withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 12, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      'AI FESTIVAL DEMAND RADAR',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_rounded, size: 12, color: Color(0xFFB45309)),
                    SizedBox(width: 3),
                    Text(
                      '+45% Surge Expected',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Diwali & Festive Rush Stock Buffer',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Recommended 2.0x stock multiplier for Sweets, Dairy, Snacks & Dry Fruits. Place advance orders 10 days prior.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11.5,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.go('/manager/sales-analytics'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white60),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    'View Historical Spike',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/manager/festivals'),
                  icon: const Icon(Icons.celebration_rounded, size: 15),
                  label: const Text('Prepare Buffer ›'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFC2410C),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInboundDeliveryCard(String storeId, UserModel? user) {
    return Consumer<InventoryProvider>(
      builder: (context, inventoryProvider, child) {
        return StreamBuilder<List<StockTransfer>>(
          stream: inventoryProvider.watchPendingTransfers(storeId),
      builder: (context, snapshot) {
        final pendingTransfers = snapshot.data ?? [];
        if (pendingTransfers.isEmpty) {
          return const SizedBox.shrink();
        }

        final transfer = pendingTransfers.first;
        final transferCode = transfer.id.length > 6
            ? transfer.id.substring(0, 6).toUpperCase()
            : transfer.id;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.local_shipping_rounded,
                          color: Color(0xFF2563EB),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'INBOUND IN TRANSIT • TR-$transferCode',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E40AF),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${pendingTransfers.length} PENDING',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.inventory_2_rounded,
                            color: Color(0xFF2563EB),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                transfer.productName,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${transfer.quantity} Units • Sent by ${transfer.initiatedByUserName}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11.5,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              if (transfer.notes != null && transfer.notes!.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  'Note: ${transfer.notes}',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 10.5,
                                    fontStyle: FontStyle.italic,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await inventoryProvider.confirmTransfer(
                            transferId: transfer.id,
                            userId: user?.id ?? 'manager',
                            userName: user?.name ?? 'Store Manager',
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                '✓ Inbound TR-$transferCode accepted! +${transfer.quantity} units of ${transfer.productName} added to inventory.',
                              ),
                              backgroundColor: const Color(0xFF10B981),
                              behavior: SnackBarBehavior.floating,
                            ));
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Failed to confirm transfer: $e'),
                              backgroundColor: const Color(0xFFEF4444),
                              behavior: SnackBarBehavior.floating,
                            ));
                          }
                        }
                      },
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                      label: Text('Confirm & Receive Stock (+${transfer.quantity} units)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
      },
    );
  }

  Widget _buildHeroKPIGrid({
    required double todayRevenue,
    required int saleCount,
    required int lowStockCount,
    required int criticalStockCount,
  }) {
    const avgRevenue = 106500.0; // You can calculate this from historical data
    final revenueChange = ((todayRevenue - avgRevenue) / avgRevenue * 100);
    final revenueChangeText = revenueChange >= 0 
        ? '+${revenueChange.toStringAsFixed(1)}% vs avg'
        : '${revenueChange.toStringAsFixed(1)}% vs avg';
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildMetricCard(
              title: "TODAY'S REVENUE", 
              value: '₹${NumberFormat('#,##,###').format(todayRevenue.round())}',
              badgeText: revenueChangeText, 
              badgeIcon: revenueChange >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              badgeColor: revenueChange >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444), 
              badgeBg: revenueChange >= 0 ? const Color(0xFFECFDF5) : const Color(0xFFFEE2E2),
              icon: Icons.currency_rupee_rounded, 
              iconColor: const Color(0xFF2563EB), 
              iconBg: const Color(0xFFEFF6FF),
              onTap: () => context.go('/manager/reports'),
            )),
            const SizedBox(width: 10),
            Expanded(child: _buildMetricCard(
              title: 'STOCK HEALTH', 
              value: '$lowStockCount Low',
              badgeText: '$criticalStockCount Critical SKUs', 
              badgeIcon: Icons.warning_amber_rounded,
              badgeColor: const Color(0xFFDC2626), 
              badgeBg: const Color(0xFFFEE2E2),
              icon: Icons.inventory_2_outlined, 
              iconColor: const Color(0xFFEF4444), 
              iconBg: const Color(0xFFFEF2F2),
              onTap: () => context.go('/manager/inventory'),
            )),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildMetricCard(
              title: 'SALES TODAY', 
              value: '$saleCount Orders',
              badgeText: '${(saleCount / 3).round()} per Till Avg', 
              badgeIcon: Icons.shopping_cart_rounded,
              badgeColor: const Color(0xFF059669), 
              badgeBg: const Color(0xFFECFDF5),
              icon: Icons.point_of_sale_rounded, 
              iconColor: const Color(0xFF047857), 
              iconBg: const Color(0xFFECFDF5),
              onTap: () => context.go('/manager/reports'),
            )),
            const SizedBox(width: 10),
            Expanded(child: _buildMetricCard(
              title: 'PENDING APPROVALS', 
              value: '5 Actions',
              badgeText: 'Needs sign-off', 
              badgeIcon: Icons.pending_actions_rounded,
              badgeColor: const Color(0xFF6366F1), 
              badgeBg: const Color(0xFFEEF2FF),
              icon: Icons.pending_actions_rounded, 
              iconColor: const Color(0xFF4F46E5), 
              iconBg: const Color(0xFFEEF2FF),
              onTap: () => context.go('/manager/purchase-orders'),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title, required String value,
    required String badgeText, required IconData badgeIcon,
    required Color badgeColor, required Color badgeBg,
    required IconData icon, required Color iconColor, required Color iconBg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.4), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 15, color: iconColor)),
              ],
            ),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 19, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), letterSpacing: -0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(6)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(badgeIcon, size: 11, color: badgeColor),
                  const SizedBox(width: 4),
                  Flexible(child: Text(badgeText, style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w700, color: badgeColor), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTillsSupervisionSection(List<SaleModel> sales) {
    // Group sales by employee for till analysis
    final Map<String, List<SaleModel>> salesByEmployee = {};
    for (final sale in sales) {
      final key = sale.employeeName;
      salesByEmployee.putIfAbsent(key, () => []).add(sale);
    }
    
    final tills = salesByEmployee.entries.take(3).map((entry) {
      final employeeSales = entry.value;
      final total = employeeSales.fold<double>(0, (sum, sale) => sum + sale.totalAmount);
      final cashSales = employeeSales.where((s) => s.paymentMode == PaymentMode.cash).fold<double>(0, (sum, sale) => sum + sale.totalAmount);
      final upiSales = employeeSales.where((s) => s.paymentMode == PaymentMode.upi).fold<double>(0, (sum, sale) => sum + sale.totalAmount);
      final orders = employeeSales.length;
      
      return {
        'till': 'Till #${salesByEmployee.keys.toList().indexOf(entry.key) + 1}', 
        'cashier': entry.key, 
        'total': '₹${NumberFormat('#,##,###').format(total.round())}', 
        'cash': '₹${NumberFormat('#,##,###').format(cashSales.round())}', 
        'upi': '₹${NumberFormat('#,##,###').format(upiSales.round())}', 
        'orders': orders, 
        'status': cashSales < 5000 ? 'LOW FLOAT' : 'HEALTHY', 
        'statusColor': cashSales < 5000 ? const Color(0xFFF59E0B) : const Color(0xFF10B981), 
        'statusBg': cashSales < 5000 ? const Color(0xFFFEF3C7) : const Color(0xFFECFDF5),
      };
    }).toList();
    
    if (tills.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.point_of_sale_outlined, size: 40, color: Color(0xFF94A3B8)),
              SizedBox(height: 8),
              Text('No till activity today', style: TextStyle(color: Color(0xFF64748B))),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('LIVE TILLS & FLOOR SUPERVISION', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.6)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: const Row(children: [Icon(Icons.circle, size: 6, color: Color(0xFF10B981)), SizedBox(width: 4), Text('3 Active Registers', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF047857)))]),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...tills.map((till) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0)), boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))]),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.point_of_sale_rounded, size: 18, color: Color(0xFF2563EB))),
                    const SizedBox(width: 10),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(till['till'] as String, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                      Text('Cashier: ${till['cashier']}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF64748B))),
                    ]),
                  ]),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(till['total'] as String, style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: till['statusBg'] as Color, borderRadius: BorderRadius.circular(6)),
                      child: Text(till['status'] as String, style: TextStyle(fontFamily: 'Poppins', fontSize: 9.5, fontWeight: FontWeight.w700, color: till['statusColor'] as Color)),
                    ),
                  ]),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFF1F5F9))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Cash: ${till['cash']}  •  UPI: ${till['upi']}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF475569))),
                    Text('${till['orders']} Bills Logged', style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2563EB))),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildCriticalStockSection(List<InventoryModel> lowStock) {
    final criticalItems = lowStock.take(5).map((inv) => {
      'name': inv.productName,
      'sku': 'ID: ${inv.productId.length > 8 ? inv.productId.substring(0, 8) : inv.productId}',
      'stock': inv.currentStock,
      'minSafe': inv.minimumStockLevel,
      'image': inv.imageUrl ?? 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=500',
    }).toList();
    
    if (criticalItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.check_circle_outline, size: 40, color: Color(0xFF10B981)),
              SizedBox(height: 8),
              Text('All stock levels healthy', style: TextStyle(color: Color(0xFF059669))),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('RESTOCK REQUIRED (${criticalItems.length} SKUS)', style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.6)),
            InkWell(onTap: () => context.go('/manager/restocking'), child: const Text('Smart Restock Hub ›', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)))),
          ],
        ),
        const SizedBox(height: 10),
        ...criticalItems.map((item) {
          final stock = item['stock'] as int;
          final min = item['minSafe'] as int;
          final pct = min > 0 ? (stock / min).clamp(0.0, 1.0) : 0.0;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0)), boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))]),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: item['image'] as String, width: 44, height: 44, fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(width: 44, height: 44, color: const Color(0xFFF1F5F9), child: const Icon(Icons.inventory_2, color: Color(0xFF94A3B8))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['name'] as String, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Row(children: [
                        Text(item['sku'] as String, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10.5, color: Color(0xFF64748B))),
                        const SizedBox(width: 8),
                        Text('Min safe: $min', style: const TextStyle(fontFamily: 'Poppins', fontSize: 10.5, color: Color(0xFF94A3B8))),
                      ]),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(value: pct, minHeight: 5, backgroundColor: const Color(0xFFF1F5F9), valueColor: AlwaysStoppedAnimation<Color>(pct < 0.4 ? const Color(0xFFEF4444) : const Color(0xFFF59E0B))),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(6)), child: Text('$stock LEFT', style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFDC2626)))),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () {
                        context.go('/manager/restocking');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFBFDBFE))),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add, size: 12, color: Color(0xFF2563EB)), SizedBox(width: 2), Text('+ PO', style: TextStyle(fontFamily: 'Poppins', fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)))]),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPendingApprovalsSection(String storeId, UserModel? user) {
    final purchaseOrderService = context.read<PurchaseOrderService>();
    return StreamBuilder<List<PurchaseOrderModel>>(
      stream: purchaseOrderService.watchPurchaseOrdersByStatus(storeId, POStatus.submitted),
      builder: (context, snapshot) {
        final pendingPOs = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'PENDING MANAGER APPROVALS',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.6,
                  ),
                ),
                if (pendingPOs.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${pendingPOs.length} Awaiting Sign-off',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4338CA),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (pendingPOs.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
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
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFECFDF5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'All Purchase Orders Up to Date',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'No pending PO approvals waiting for manager sign-off.',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => context.go('/manager/purchase-orders'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: const Text(
                          'View POs',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...pendingPOs.take(3).map((po) {
                final itemsSummary = po.items.map((i) => i.productName).take(2).join(', ');
                final extraCount = po.items.length > 2 ? ' +${po.items.length - 2} more' : '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${po.poNumber} • ${po.supplierName}',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF4338CA),
                              ),
                            ),
                          ),
                          Text(
                            '₹${NumberFormat('#,##,###.00').format(po.totalAmount)}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Items: $itemsSummary$extraCount',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => context.go('/manager/purchase-orders'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text(
                                'View Items',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                try {
                                  await purchaseOrderService.approvePurchaseOrder(
                                    po.id,
                                    user?.name ?? 'Store Manager',
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      content: Text(
                                        '✓ ${po.poNumber} Approved & Dispatched to ${po.supplierName}!',
                                      ),
                                      backgroundColor: const Color(0xFF10B981),
                                      behavior: SnackBarBehavior.floating,
                                    ));
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      content: Text('Failed to approve PO: $e'),
                                      backgroundColor: const Color(0xFFEF4444),
                                      behavior: SnackBarBehavior.floating,
                                    ));
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text(
                                'Approve PO',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  void _showStoreSwitcherModal(BuildContext context, StoreProvider storeProvider) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final stores = storeProvider.stores;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Switch Managed Store', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
              const SizedBox(height: 4),
              const Text('Select store to inspect inventory and supervisory floor data', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 16),
              if (stores.isEmpty)
                const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text('Downtown Central (Primary Active Store)'))
              else
                ...stores.map((s) {
                  final isSelected = s.id == storeProvider.selectedStore?.id;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.store_rounded, color: isSelected ? Colors.white : const Color(0xFF64748B), size: 20)),
                    title: Text(s.name, style: TextStyle(fontFamily: 'Poppins', fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF0F172A))),
                    trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF2563EB)) : null,
                    onTap: () { storeProvider.selectStore(s); Navigator.pop(ctx); },
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  void _showProfileModal(BuildContext context, UserModel? user, AuthProvider auth) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            CircleAvatar(radius: 30, backgroundColor: const Color(0xFF2563EB), child: Text(user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'M', style: const TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white))),
            const SizedBox(height: 12),
            Text(user?.name ?? 'Store Manager', style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            Text(user?.email ?? 'manager@storeiq.io', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () { Navigator.pop(ctx); auth.signOut(); },
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Sign Out of Manager Session'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFEE2E2), foregroundColor: const Color(0xFFDC2626), elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), textStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
