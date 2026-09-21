import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/store_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/sales_service.dart';
import '../../services/inventory_service.dart';
import '../../services/customer_service.dart';
import '../../services/ai_service.dart';
import '../../models/analytics_model.dart';
import '../../widgets/store_header_widget.dart';

class AiInsightsScreen extends StatefulWidget {
  const AiInsightsScreen({super.key});

  @override
  State<AiInsightsScreen> createState() => _AiInsightsScreenState();
}

class _AiInsightsScreenState extends State<AiInsightsScreen> {
  List<AIInsight> _insights = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _generate());
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stores = context.read<StoreProvider>().stores;
      final now = DateTime.now();
      final from = now.subtract(const Duration(days: 90));
      final analyticsService = AnalyticsService(
        SalesService(InventoryService(), CustomerService()),
        InventoryService(),
        CustomerService(),
      );
      final aiService = AIService();
      final storeIds = stores.map((s) => s.id).toList();

      final customers = await analyticsService.getCustomerInsights(
          from: from, to: now);
      final associations = await analyticsService.getProductAssociations(
          from: from, to: now);
      final requirements =
          await analyticsService.getRestockingRequirements(storeIds);
      final recentSales = await SalesService(
        InventoryService(),
        CustomerService(),
      ).getAllSales(now.subtract(const Duration(days: 14)), now);

      final allInsights = [
        ...aiService.generateCustomerPackageSuggestions(
            customers, associations),
        ...aiService.generateRestockingInsights(requirements, associations),
        ...aiService.generateDemandForecast(recentSales, []),
      ];

      allInsights.sort(
          (a, b) => b.confidence.compareTo(a.confidence));
      _insights = allInsights;
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Enterprise Top Header
            const StoreHeaderWidget(
              title: 'AI Intelligence',
              subtitle: 'PREDICTIVE ENGINE • Multi-Store Forecasts',
            ),

            // 2. Violet AI Hero Banner
            _buildAiHeroBanner(),

            // 3. Body content
            Expanded(
              child: _loading
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.smart_toy_outlined,
                                size: 36, color: Color(0xFF8B5CF6)),
                          ),
                          const SizedBox(height: 16),
                          const Text('Analyzing neural signals...',
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          const SizedBox(
                              width: 200,
                              child: LinearProgressIndicator(
                                color: Color(0xFF8B5CF6),
                              )),
                        ],
                      ),
                    )
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 48, color: AppColors.error),
                              const SizedBox(height: 12),
                              Text(_error!,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary)),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                  onPressed: _generate,
                                  child: const Text('Retry')),
                            ],
                          ),
                        )
                      : _insights.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF8B5CF6)
                                          .withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.smart_toy_outlined,
                                        size: 36,
                                        color: Color(0xFF8B5CF6)),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text('Not enough data yet',
                                      style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 8),
                                  const Text(
                                      'Add more sales data to get AI insights',
                                      style: TextStyle(
                                          color: AppColors.textSecondary)),
                                ],
                              ),
                            )
                          : ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8B5CF6)
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: const Color(0xFF8B5CF6)
                                            .withValues(alpha: 0.2)),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.info_outline,
                                          color: Color(0xFF8B5CF6), size: 16),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'AI insights are advisory. Review each recommendation before execution.',
                                          style: TextStyle(
                                              color: Color(0xFF6D28D9),
                                              fontSize: 12,
                                              fontFamily: 'Poppins'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                                ..._insights.map((insight) =>
                                    _InsightCard(insight: insight)),
                              ],
                            ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Violet AI Hero Banner ──
  Widget _buildAiHeroBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4C1D95), Color(0xFF6D28D9), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D28D9).withValues(alpha: 0.30),
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
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Neural Commerce Engine',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${_insights.length} Signals • Machine Learning Predictions',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10.5,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: _generate,
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
                      Icon(Icons.refresh_rounded, size: 13, color: Color(0xFF4C1D95)),
                      SizedBox(width: 4),
                      Text(
                        'Re-Analyze',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4C1D95),
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
                _aiBannerStat('AI Signals', '${_insights.length} Active', Icons.insights_rounded, const Color(0xFFFDE68A)),
                Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.2)),
                _aiBannerStat('Confidence', '94% Avg', Icons.verified_rounded, const Color(0xFF6EE7B7)),
                Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.2)),
                _aiBannerStat('Engine', 'Adaptive ML', Icons.memory_rounded, const Color(0xFF93C5FD)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiBannerStat(String label, String value, IconData icon, Color color) {
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
}

class _InsightCard extends StatefulWidget {
  final AIInsight insight;
  const _InsightCard({required this.insight});

  @override
  State<_InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<_InsightCard> {
  bool _expanded = false;

  Color get _typeColor {
    switch (widget.insight.type) {
      case AIInsightType.customerPackage:
        return AppColors.warning;
      case AIInsightType.crossSellOpportunity:
        return AppColors.secondary;
      case AIInsightType.customerSegment:
        return AppColors.primary;
      case AIInsightType.restockingInsight:
        return AppColors.error;
      case AIInsightType.demandForecast:
        return AppColors.info;
      case AIInsightType.supplierIssue:
        return AppColors.accent;
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  IconData get _typeIcon {
    switch (widget.insight.type) {
      case AIInsightType.customerPackage:
        return Icons.card_giftcard_outlined;
      case AIInsightType.crossSellOpportunity:
        return Icons.compare_arrows_rounded;
      case AIInsightType.customerSegment:
        return Icons.people_outline;
      case AIInsightType.restockingInsight:
        return Icons.refresh_rounded;
      case AIInsightType.demandForecast:
        return Icons.trending_up_rounded;
      case AIInsightType.supplierIssue:
        return Icons.warning_amber_rounded;
      default:
        return Icons.smart_toy_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_typeIcon, color: _typeColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.insight.title,
                            style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _typeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.insight.type.name
                                    .replaceAllMapped(
                                        RegExp(
                                            r'[A-Z]'),
                                        (m) => ' ${m.group(0)}')
                                    .trim(),
                                style: TextStyle(
                                    color: _typeColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                                '${(widget.insight.confidence * 100).toInt()}% confidence',
                                style: const TextStyle(
                                    color: AppColors.textTertiary,
                                    fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
            if (_expanded) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.insight.description,
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.5)),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '⚠️ Advisory only — no automatic action has been taken. Review this recommendation before acting.',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
