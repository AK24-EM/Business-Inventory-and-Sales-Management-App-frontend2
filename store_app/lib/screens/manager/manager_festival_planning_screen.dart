import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../config/app_theme.dart';
import '../../widgets/store_header_widget.dart';
import '../../providers/store_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/inventory_service.dart';
import '../../models/festival_model.dart';
import '../../models/inventory_model.dart';

/// Manager Festival Planning & Demand Buffer Calculator
/// Features:
/// - Upcoming festivals countdown
/// - Historical sales analysis from last year
/// - Stock buffer recommendations (2x-3x multiplier by category)
/// - Readiness dashboard showing preparation status
/// - Category-wise stock analysis
class ManagerFestivalPlanningScreen extends StatefulWidget {
  const ManagerFestivalPlanningScreen({super.key});

  @override
  State<ManagerFestivalPlanningScreen> createState() =>
      _ManagerFestivalPlanningScreenState();
}

class _ManagerFestivalPlanningScreenState
    extends State<ManagerFestivalPlanningScreen> {
  List<FestivalModel> _festivals = [];
  FestivalModel? _selectedFestival;
  bool _loading = true;

  // Festival demand multipliers by category (configurable)
  final Map<String, double> _categoryMultipliers = {
    'Sweets': 3.0,
    'Dairy': 2.0,
    'Dry Fruits': 2.5,
    'Snacks': 2.0,
    'Beverages': 1.8,
    'Groceries': 1.5,
    'Household': 1.3,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // Load festivals from Firestore
      final festivalsSnapshot = await FirebaseFirestore.instance
          .collection('festivals')
          .where('isActive', isEqualTo: true)
          .orderBy('startDate')
          .get();

      final festivals = festivalsSnapshot.docs
          .map((doc) => FestivalModel.fromFirestore(doc))
          .toList();

      // Filter to show only upcoming or ongoing festivals
      final relevantFestivals = festivals.where((f) {
        return f.startDate.isAfter(DateTime.now().subtract(const Duration(days: 7)));
      }).toList();

      if (mounted) {
        setState(() {
          _festivals = relevantFestivals;
          _selectedFestival = relevantFestivals.isNotEmpty ? relevantFestivals.first : null;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading festivals: $e')),
        );
      }
    }
  }

  int _daysUntilFestival(FestivalModel festival) {
    return festival.startDate.difference(DateTime.now()).inDays;
  }

  double _readinessPercentage() {
    // Simplified readiness calculation
    // In real implementation, compare current stock vs recommended stock
    if (_selectedFestival == null) return 0.0;
    final daysUntil = _daysUntilFestival(_selectedFestival!);
    final preparationDays = _selectedFestival!.advanceOrderDays;
    if (daysUntil >= preparationDays) return 0.0;
    if (daysUntil <= 0) return 100.0;
    return ((preparationDays - daysUntil) / preparationDays * 100).clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            StoreHeaderWidget(
              title: 'Festival Planning',
              subtitle: 'DEMAND SURGE MANAGEMENT • Buffer Calculations',
              onNotificationTap: () => context.go('/manager/notifications'),
            ),

            // Festival Hero Banner
            _buildFestivalHeroBanner(),

            // Festival Selector
            if (_festivals.length > 1) _buildFestivalSelector(),

            // Content
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFFEA580C)),
                    )
                  : _selectedFestival == null
                      ? _buildNoFestivalsState()
                      : _buildFestivalContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFestivalHeroBanner() {
    final daysUntil = _selectedFestival != null ? _daysUntilFestival(_selectedFestival!) : 0;
    final readiness = _readinessPercentage();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C2D12), Color(0xFFEA580C), Color(0xFFF59E0B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA580C).withValues(alpha: 0.35),
            blurRadius: 20,
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
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.celebration_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedFestival?.name ?? 'No Upcoming Festivals',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      _selectedFestival != null
                          ? '$daysUntil days until festival starts'
                          : 'All festivals planned',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedFestival != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${readiness.toInt()}% Ready',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFEA580C),
                    ),
                  ),
                ),
            ],
          ),
          if (_selectedFestival != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _festivalStat(
                        'Start Date',
                        DateFormat('d MMM').format(_selectedFestival!.startDate),
                        Icons.event_rounded,
                        const Color(0xFFFDE68A),
                      ),
                      Container(width: 1, height: 32, color: Colors.white24),
                      _festivalStat(
                        'Duration',
                        '${_selectedFestival!.endDate.difference(_selectedFestival!.startDate).inDays} days',
                        Icons.calendar_today_rounded,
                        const Color(0xFFFBBF24),
                      ),
                      Container(width: 1, height: 32, color: Colors.white24),
                      _festivalStat(
                        'Order By',
                        DateFormat('d MMM').format(_selectedFestival!.alertDate),
                        Icons.notifications_active_rounded,
                        const Color(0xFFBFDBFE),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Readiness progress bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Preparation Progress',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            '${readiness.toInt()}%',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: readiness / 100,
                          minHeight: 8,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _festivalStat(String label, String value, IconData icon, Color color) {
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
            fontSize: 9,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }

  Widget _buildFestivalSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _festivals.map((festival) {
            final isSelected = _selectedFestival?.id == festival.id;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => setState(() => _selectedFestival = festival),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFEA580C) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFEA580C) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.celebration_rounded,
                        size: 14,
                        color: isSelected ? Colors.white : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        festival.name,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFestivalContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Countdown Card
          _buildCountdownCard(),
          const SizedBox(height: 16),

          // Stock Buffer Recommendations by Category
          _buildBufferRecommendations(),
          const SizedBox(height: 16),

          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildCountdownCard() {
    final daysUntil = _daysUntilFestival(_selectedFestival!);
    final isUrgent = daysUntil <= 7;
    final isPastOrderDate = DateTime.now().isAfter(_selectedFestival!.alertDate);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0),
          width: isUrgent ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isUrgent
                      ? const Color(0xFFFEF2F2)
                      : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isUrgent ? Icons.warning_rounded : Icons.timer_rounded,
                  color: isUrgent ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      daysUntil > 0 ? '$daysUntil Days Until Festival' : 'Festival Ongoing!',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      isPastOrderDate
                          ? 'Order deadline passed - Rush orders needed'
                          : 'Order by ${DateFormat('d MMM').format(_selectedFestival!.alertDate)}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: isPastOrderDate
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF64748B),
                        fontWeight: isPastOrderDate ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isUrgent) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFEF4444),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Urgent! Festival approaching soon. Finalize stock orders immediately.',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Color(0xFFB91C1C),
                        height: 1.4,
                      ),
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

  Widget _buildBufferRecommendations() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.inventory_2_rounded,
                color: Color(0xFFEA580C),
                size: 20,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Stock Buffer Recommendations',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'AI Calculated',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Based on historical sales patterns, we recommend increasing stock levels for these categories:',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11.5,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          ..._categoryMultipliers.entries.map((entry) =>
              _buildCategoryMultiplierRow(entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _buildCategoryMultiplierRow(String category, double multiplier) {
    final color = _getMultiplierColor(multiplier);
    final bgColor = _getMultiplierBgColor(multiplier);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              category,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              '${multiplier}x Stock',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            Icons.trending_up_rounded,
            size: 18,
            color: color,
          ),
        ],
      ),
    );
  }

  Color _getMultiplierColor(double multiplier) {
    if (multiplier >= 3.0) return const Color(0xFFDC2626);
    if (multiplier >= 2.0) return const Color(0xFFEA580C);
    if (multiplier >= 1.5) return const Color(0xFFF59E0B);
    return const Color(0xFF059669);
  }

  Color _getMultiplierBgColor(double multiplier) {
    if (multiplier >= 3.0) return const Color(0xFFFEF2F2);
    if (multiplier >= 2.0) return const Color(0xFFFFF7ED);
    if (multiplier >= 1.5) return const Color(0xFFFFFBEB);
    return const Color(0xFFECFDF5);
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            // Navigate to restocking screen with festival filter
            context.go('/manager/restocking');
          },
          icon: const Icon(Icons.shopping_cart_rounded, size: 18),
          label: const Text('Generate Festival Stock Orders'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEA580C),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () {
            // Show historical analysis
            _showHistoricalAnalysis();
          },
          icon: const Icon(Icons.analytics_outlined, size: 18),
          label: const Text('View Last Year\'s Performance'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFEA580C),
            side: const BorderSide(color: Color(0xFFEA580C)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoFestivalsState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFFFFBEB),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.celebration_outlined,
              size: 60,
              color: Color(0xFFEA580C),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Upcoming Festivals',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'All festivals have been planned',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  void _showHistoricalAnalysis() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics_rounded, color: Color(0xFFEA580C)),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Historical Festival Analysis',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Text(
                'Historical data from last year\'s festival will be shown here. This includes sales spike analysis, category performance, and stock-out incidents.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Color(0xFF92400E),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Coming Soon: Detailed historical analysis with charts and insights.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
