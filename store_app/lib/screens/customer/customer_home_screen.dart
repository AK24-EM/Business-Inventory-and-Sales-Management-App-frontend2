import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../config/app_constants.dart';
import '../../models/user_model.dart';
import '../../models/festival_model.dart';
import '../../models/sale_model.dart';
import '../../models/customer_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/festival_service.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _currentTabIndex = 0;
  final FestivalService _festivalService = FestivalService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final isWide = MediaQuery.of(context).size.width > 860;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, auth, user),
      body: Row(
        children: [
          if (isWide) _buildWebNavigationRail(),
          Expanded(
            child: IndexedStack(
              index: _currentTabIndex,
              children: [
                _buildOverviewTab(context, user, isWide),
                _buildFestivalsAndOffersTab(context, isWide),
                _buildPurchaseHistoryTab(context, user, isWide),
                _buildProfileTab(context, auth, user, isWide),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _currentTabIndex,
              onDestinationSelected: (i) => setState(() => _currentTabIndex = i),
              backgroundColor: AppColors.surface,
              elevation: 3,
              indicatorColor: AppColors.primarySubtle,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.primary),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.celebration_outlined),
                  selectedIcon: Icon(Icons.celebration_rounded, color: AppColors.primary),
                  label: 'Festivals',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                  label: 'Orders',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
                  label: 'Profile',
                ),
              ],
            ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, AuthProvider auth, UserModel? user) {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.surface,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                AppConstants.appName,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Live GCP Sync',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Show Member Barcode',
          icon: const Icon(Icons.qr_code_rounded, color: AppColors.primary),
          onPressed: () => _showBarcodeDialog(context, user),
        ),
        IconButton(
          tooltip: 'Sign out',
          icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
          onPressed: () => _confirmSignOut(context, auth),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildWebNavigationRail() {
    return NavigationRail(
      selectedIndex: _currentTabIndex,
      onDestinationSelected: (i) => setState(() => _currentTabIndex = i),
      labelType: NavigationRailLabelType.all,
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primarySubtle,
      selectedLabelTextStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
      unselectedLabelTextStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 11,
        color: AppColors.textSecondary,
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.primary),
          label: Text('Dashboard'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.celebration_outlined),
          selectedIcon: Icon(Icons.celebration_rounded, color: AppColors.primary),
          label: Text('Festivals'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long_rounded, color: AppColors.primary),
          label: Text('Orders'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
          label: Text('Profile'),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1: OVERVIEW DASHBOARD
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildOverviewTab(BuildContext context, UserModel? user, bool isWide) {
    final phone = user?.phone.trim() ?? '';

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 32 : 16,
        vertical: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Personalized Member Card
          _buildMemberCard(user),
          const SizedBox(height: 20),

          // 2. Real-Time Loyalty Points Card
          _buildLoyaltyPointsStreamCard(phone),
          const SizedBox(height: 24),

          // 3. Festival Alerts & Festive Highlights Section
          _buildFestivalAlertsSection(),
          const SizedBox(height: 24),

          // 4. Hot Offers & Promo Codes Section
          _buildHotOffersSection(),
          const SizedBox(height: 24),

          // 5. Recent Purchases Preview
          _buildRecentPurchasesSection(user),
        ],
      ),
    );
  }

  Widget _buildMemberCard(UserModel? user) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      (user?.name.isNotEmpty == true)
                          ? user!.name[0].toUpperCase()
                          : 'C',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Customer',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        user?.phone.isNotEmpty == true
                            ? user!.phone
                            : user?.email ?? 'Member Account',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stars_rounded, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'PREMIUM',
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
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MEMBER ID',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.6),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.id.isNotEmpty == true
                        ? user!.id.substring(0, user.id.length.clamp(0, 10)).toUpperCase()
                        : 'MEMBER-01',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showBarcodeDialog(context, user),
                icon: const Icon(Icons.qr_code, size: 16),
                label: const Text('Scan at POS'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  textStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoyaltyPointsStreamCard(String phone) {
    if (phone.isEmpty) {
      return _buildLoyaltyFallbackCard(0, 0, 0);
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection(AppConstants.loyaltyAccountsCollection)
          .doc(phone)
          .snapshots(),
      builder: (context, snapshot) {
        int availablePoints = 0;
        int totalEarned = 0;
        int redeemed = 0;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() ?? {};
          availablePoints = (data['availablePoints'] as num?)?.toInt() ?? 0;
          totalEarned = (data['totalPoints'] as num?)?.toInt() ?? 0;
          redeemed = (data['redeemedPoints'] as num?)?.toInt() ?? 0;
        }

        return _buildLoyaltyFallbackCard(availablePoints, totalEarned, redeemed);
      },
    );
  }

  Widget _buildLoyaltyFallbackCard(int availablePoints, int totalEarned, int redeemed) {
    final rupeeValue = (availablePoints * AppConstants.pointsToRupeeValue).toInt();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.military_tech_rounded,
                        color: AppColors.accent, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Loyalty Rewards',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '₹$rupeeValue Redeemable',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Available Points',
                  value: '$availablePoints',
                  icon: Icons.monetization_on_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  label: 'Total Earned',
                  value: '$totalEarned',
                  icon: Icons.trending_up_rounded,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  label: 'Redeemed',
                  value: '$redeemed',
                  icon: Icons.redeem_rounded,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Tier progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (availablePoints / 1000).clamp(0.05, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '1 pt = ₹0.25 on checkout',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
              Text(
                '${(1000 - availablePoints).clamp(0, 1000)} pts to Gold Club',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FESTIVAL ALERTS & OFFERS SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFestivalAlertsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.celebration_rounded, color: AppColors.secondary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Festival Alerts & Special Offers',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => setState(() => _currentTabIndex = 1),
              child: const Text('View All', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<FestivalModel>>(
          stream: _festivalService.getFestivalsStream(activeOnly: true),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }

            final festivals = snapshot.data ?? [];
            if (festivals.isEmpty) {
              return _buildDefaultFestiveBanner();
            }

            return Column(
              children: festivals
                  .take(2)
                  .map((festival) => _buildFestivalCard(festival))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFestivalCard(FestivalModel festival) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final startStr = dateFormat.format(festival.startDate);
    final endStr = dateFormat.format(festival.endDate);
    final isOngoing = festival.isOngoing;
    final isUpcoming = festival.isUpcoming;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOngoing
              ? AppColors.secondary.withValues(alpha: 0.5)
              : AppColors.border,
          width: isOngoing ? 1.5 : 1,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded,
                          color: AppColors.secondary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        festival.name,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOngoing ? AppColors.success : AppColors.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isOngoing
                      ? 'ACTIVE NOW'
                      : (isUpcoming
                          ? 'IN ${festival.daysUntilStart} DAYS'
                          : 'PAST'),
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
          const SizedBox(height: 12),
          Text(
            'Festival Dates: $startStr – $endStr',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPerkChip(Icons.percent_rounded, 'Up to 25% Off Sweets & Snacks'),
              _buildPerkChip(Icons.bolt_rounded, 'Double (2X) Loyalty Points'),
              _buildPerkChip(Icons.shopping_bag_rounded, 'Special Festive Packs'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultFestiveBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primarySubtle,
            AppColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.celebration_rounded,
                color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Festive Season Specials Coming Soon!',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Exclusive member discounts and bonus reward points will be unlocked during upcoming festivals.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
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

  Widget _buildPerkChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.secondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HOT OFFERS & PROMO CODES SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHotOffersSection() {
    final offers = [
      {
        'title': 'Festive Mega Savings',
        'code': 'FESTIVE25',
        'discount': '25% OFF',
        'desc': 'On Bakery, Sweets & Dry Fruits. Min bill ₹800',
        'icon': Icons.cake_rounded,
        'color': AppColors.secondary,
      },
      {
        'title': 'Weekend Mart Fresh',
        'code': 'FRESH100',
        'discount': '₹100 OFF',
        'desc': 'On Groceries & Daily Essentials. Min bill ₹1,200',
        'icon': Icons.local_grocery_store_rounded,
        'color': AppColors.success,
      },
      {
        'title': 'Double Loyalty Blast',
        'code': '2XPOINTS',
        'discount': '2X REWARD',
        'desc': 'Earn double loyalty points on all UPI & Card payments',
        'icon': Icons.stars_rounded,
        'color': AppColors.accent,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.local_offer_rounded, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text(
              'Store Offers & Promo Coupons',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: offers.map((offer) {
              return Container(
                width: 260,
                margin: const EdgeInsets.only(right: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(offer['icon'] as IconData,
                            color: offer['color'] as Color, size: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (offer['color'] as Color).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            offer['discount'] as String,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: offer['color'] as Color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      offer['title'] as String,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      offer['desc'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: () => _copyToClipboard(offer['code'] as String),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.border,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              offer['code'] as String,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                                color: AppColors.primary,
                              ),
                            ),
                            const Row(
                              children: [
                                Icon(Icons.copy_rounded, size: 14, color: AppColors.textTertiary),
                                SizedBox(width: 4),
                                Text(
                                  'Copy',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RECENT PURCHASES PREVIEW
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildRecentPurchasesSection(UserModel? user) {
    final uid = user?.id ?? '';
    final phone = user?.phone.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.history_rounded, color: AppColors.textPrimary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Recent Purchases',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => setState(() => _currentTabIndex = 2),
              child: const Text('View All Orders', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _firestore
              .collection(AppConstants.salesCollection)
              .where('customerId', isEqualTo: uid)
              .limit(3)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }

            var docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty && phone.isNotEmpty) {
              // Try fallback query by phone
              return _buildPhoneFallbackPurchases(phone);
            }

            if (docs.isEmpty) {
              return _buildEmptyPurchasesCard();
            }

            final sales = docs.map(SaleModel.fromFirestore).toList();
            return Column(
              children: sales.map((sale) => _buildSaleItemCard(sale)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPhoneFallbackPurchases(String phone) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection(AppConstants.salesCollection)
          .where('customerPhone', isEqualTo: phone)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _buildEmptyPurchasesCard();
        }
        final sales = docs.map(SaleModel.fromFirestore).toList();
        return Column(
          children: sales.map((sale) => _buildSaleItemCard(sale)).toList(),
        );
      },
    );
  }

  Widget _buildEmptyPurchasesCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.shopping_bag_outlined,
                size: 44, color: AppColors.textTertiary.withValues(alpha: 0.6)),
            const SizedBox(height: 10),
            const Text(
              'No In-Store Purchases Yet',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Share your phone number at store checkout to earn loyalty points and track your bills here in real time!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaleItemCard(SaleModel sale) {
    final dateFormat = DateFormat('MMM dd, yyyy · hh:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primarySubtle,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt_rounded,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale.storeName.isNotEmpty ? sale.storeName : 'Store Checkout',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  dateFormat.format(sale.timestamp),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${sale.itemCount} items · ${sale.paymentMode.displayName}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${sale.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              OutlinedButton(
                onPressed: () => _showReceiptSheet(sale),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: const BorderSide(color: AppColors.primary),
                ),
                child: const Text('Receipt', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 2: FESTIVALS & OFFERS DETAIL
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFestivalsAndOffersTab(BuildContext context, bool isWide) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 32 : 16,
        vertical: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Festival Seasons & Store Discounts',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Active festive promotions, seasonal discounts, and double loyalty bonus events.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          StreamBuilder<List<FestivalModel>>(
            stream: _festivalService.getFestivalsStream(activeOnly: false),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final festivals = snapshot.data ?? [];
              if (festivals.isEmpty) {
                return Column(
                  children: [
                    _buildDefaultFestiveBanner(),
                    const SizedBox(height: 20),
                    _buildHotOffersSection(),
                  ],
                );
              }

              return Column(
                children: [
                  ...festivals.map((f) => _buildFestivalDetailCard(f)),
                  const SizedBox(height: 16),
                  _buildHotOffersSection(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFestivalDetailCard(FestivalModel festival) {
    final dateFormat = DateFormat('EEEE, MMM dd, yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: festival.isOngoing ? AppColors.secondary : AppColors.border,
          width: festival.isOngoing ? 2 : 1,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                festival.name,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: festival.isOngoing
                      ? AppColors.success
                      : (festival.isUpcoming ? AppColors.secondary : AppColors.textTertiary),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  festival.isOngoing
                      ? 'ACTIVE FESTIVAL'
                      : (festival.isUpcoming
                          ? 'STARTS IN ${festival.daysUntilStart} DAYS'
                          : 'PAST SEASON'),
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
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.date_range_rounded, size: 16, color: AppColors.textTertiary),
              const SizedBox(width: 6),
              Text(
                '${dateFormat.format(festival.startDate)} to ${dateFormat.format(festival.endDate)}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Festival Category Discounts:',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildCategoryDiscountPill('Sweets', '30% OFF'),
              _buildCategoryDiscountPill('Dry Fruits', '25% OFF'),
              _buildCategoryDiscountPill('Bakery & Snacks', '20% OFF'),
              _buildCategoryDiscountPill('Beverages', '18% OFF'),
              _buildCategoryDiscountPill('Groceries', '15% OFF'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDiscountPill(String category, String discount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primarySubtle,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            category,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              discount,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 3: COMPLETE PURCHASE HISTORY
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPurchaseHistoryTab(
      BuildContext context, UserModel? user, bool isWide) {
    final uid = user?.id ?? '';
    final phone = user?.phone.trim() ?? '';

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 32 : 16,
        vertical: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Order & Invoice History',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Track your bills, digital invoices, and loyalty reward deductions.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore
                .collection(AppConstants.salesCollection)
                .where('customerId', isEqualTo: uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              var docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty && phone.isNotEmpty) {
                return _buildPhoneFallbackPurchasesTab(phone);
              }

              if (docs.isEmpty) {
                return _buildEmptyPurchasesCard();
              }

              final sales = docs.map(SaleModel.fromFirestore).toList();
              sales.sort((a, b) => b.timestamp.compareTo(a.timestamp));

              return Column(
                children: sales.map((sale) => _buildSaleItemCard(sale)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneFallbackPurchasesTab(String phone) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection(AppConstants.salesCollection)
          .where('customerPhone', isEqualTo: phone)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _buildEmptyPurchasesCard();
        }

        final sales = docs.map(SaleModel.fromFirestore).toList();
        sales.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        return Column(
          children: sales.map((sale) => _buildSaleItemCard(sale)).toList(),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 4: PROFILE & SETTINGS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildProfileTab(
      BuildContext context, AuthProvider auth, UserModel? user, bool isWide) {
    final dateFormat = DateFormat('MMMM dd, yyyy');

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 48 : 20,
        vertical: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primarySubtle,
                  child: Text(
                    (user?.name.isNotEmpty == true)
                        ? user!.name[0].toUpperCase()
                        : 'C',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  user?.name ?? 'Customer',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primarySubtle,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Verified Customer Account',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
                _buildProfileDetailRow(
                    Icons.email_outlined, 'Email Address', user?.email ?? '-'),
                const SizedBox(height: 14),
                _buildProfileDetailRow(
                    Icons.phone_outlined, 'Phone Number', user?.phone ?? '-'),
                const SizedBox(height: 14),
                _buildProfileDetailRow(
                  Icons.badge_outlined,
                  'Customer UID',
                  user?.id ?? '-',
                ),
                const SizedBox(height: 14),
                _buildProfileDetailRow(
                  Icons.calendar_month_outlined,
                  'Member Since',
                  user?.createdAt != null
                      ? dateFormat.format(user!.createdAt)
                      : 'Active',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Security & Sign out
          OutlinedButton.icon(
            onPressed: () => _confirmSignOut(context, auth),
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            label: const Text(
              'Sign Out of Account',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppColors.error),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textTertiary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MODALS & DIALOGS
  // ═══════════════════════════════════════════════════════════════════════════
  void _showBarcodeDialog(BuildContext context, UserModel? user) {
    final phone = user?.phone.isNotEmpty == true ? user!.phone : (user?.id ?? '0000000000');

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Store Member Barcode',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      // Simulated retail barcode
                      CustomPaint(
                        size: const Size(220, 70),
                        painter: BarcodePainter(),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        phone,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Present this code at any branch checkout. The cashier will scan it to link your points and purchases!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showReceiptSheet(SaleModel sale) {
    final dateFormat = DateFormat('MMM dd, yyyy · hh:mm a');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.success, size: 40),
                      const SizedBox(height: 8),
                      Text(
                        sale.storeName.isNotEmpty ? sale.storeName : 'Store Checkout',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        dateFormat.format(sale.timestamp),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                const Text(
                  'Items Purchased:',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...sale.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.productName} × ${item.quantity}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '₹${item.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                _buildReceiptRow('Subtotal', '₹${sale.subtotal.toStringAsFixed(2)}'),
                if (sale.discountAmount > 0)
                  _buildReceiptRow(
                    'Discount',
                    '-₹${sale.discountAmount.toStringAsFixed(2)}',
                    color: AppColors.success,
                  ),
                if (sale.loyaltyPointsRedeemed > 0)
                  _buildReceiptRow(
                    'Loyalty Points',
                    '-₹${sale.loyaltyPointsRedeemed.toStringAsFixed(2)}',
                    color: AppColors.success,
                  ),
                const SizedBox(height: 6),
                _buildReceiptRow(
                  'Total Paid (${sale.paymentMode.displayName})',
                  '₹${sale.totalAmount.toStringAsFixed(2)}',
                  isTotal: true,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Close Receipt',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReceiptRow(String label, String value,
      {Color? color, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: isTotal ? 15 : 12,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: isTotal ? 16 : 12,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Promo code "$code" copied to clipboard!'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.signOut();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

/// Simulated retail barcode painter for member scanning
class BarcodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2.0;

    final widths = [
      3.0, 1.5, 2.0, 4.0, 1.5, 3.0, 2.0, 1.5, 4.0, 2.0, 1.5, 3.0, 1.5, 4.0, 2.0,
      1.5, 3.0, 2.0, 4.0, 1.5, 2.0, 3.0, 1.5, 4.0, 2.0, 1.5, 3.0, 2.0, 1.5, 4.0
    ];

    double currentX = 10;
    for (int i = 0; i < widths.length && currentX < size.width - 10; i++) {
      paint.strokeWidth = widths[i];
      canvas.drawLine(
        Offset(currentX, 0),
        Offset(currentX, size.height),
        paint,
      );
      currentX += widths[i] + (i % 2 == 0 ? 3.5 : 2.0);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
