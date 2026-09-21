import '../models/analytics_model.dart';
import '../models/sale_model.dart';
import '../models/customer_model.dart';

/// AI-assisted advisory recommendations.
/// All outputs are strictly advisory — no automatic actions are taken.
class AIService {
  // ── Customer Package Suggestions ──────────────────────────────────────────

  List<AIInsight> generateCustomerPackageSuggestions(
    List<CustomerInsight> insights,
    List<ProductAssociation> associations,
  ) {
    final List<AIInsight> results = [];

    // Segment-based package suggestions
    final vipCustomers = insights.where((c) => c.segment == 'VIP').toList();
    final loyalCustomers =
        insights.where((c) => c.segment == 'Loyal').toList();

    if (vipCustomers.isNotEmpty) {
      results.add(AIInsight(
        id: 'pkg_vip_${DateTime.now().millisecondsSinceEpoch}',
        type: AIInsightType.customerPackage,
        title: 'VIP Customer Package Opportunity',
        description:
            'You have ${vipCustomers.length} VIP customers. Consider offering a '
            'premium bundle of their frequently purchased products with a 5–10% discount '
            'to increase transaction size and loyalty.',
        data: {
          'customerCount': vipCustomers.length,
          'topCategories': _getTopCategories(vipCustomers),
          'avgSpend': vipCustomers.fold(0.0, (s, c) => s + c.totalSpend) /
              vipCustomers.length,
        },
        confidence: 0.85,
        generatedAt: DateTime.now(),
      ));
    }

    // Association-based suggestions
    for (final assoc in associations.take(3)) {
      if (assoc.lift > 2.0) {
        results.add(AIInsight(
          id: 'assoc_${assoc.product1Id}_${assoc.product2Id}',
          type: AIInsightType.crossSellOpportunity,
          title: 'Cross-sell Opportunity',
          description:
              'Customers who buy "${assoc.product1Name}" are ${(assoc.lift * 100).round()}% '
              'more likely to also buy "${assoc.product2Name}". '
              'Consider placing these products near each other or bundling them.',
          data: {
            'product1': assoc.product1Name,
            'product2': assoc.product2Name,
            'lift': assoc.lift,
            'confidence': assoc.confidence,
            'occurrences': assoc.coOccurrenceCount,
          },
          confidence: assoc.confidence,
          generatedAt: DateTime.now(),
        ));
      }
    }

    // At-risk customers
    final atRisk = insights.where((c) {
      final daysSincePurchase =
          DateTime.now().difference(c.lastPurchaseDate).inDays;
      return c.totalPurchases >= 3 && daysSincePurchase > 45;
    }).toList();

    if (atRisk.isNotEmpty) {
      results.add(AIInsight(
        id: 'atrisk_${DateTime.now().millisecondsSinceEpoch}',
        type: AIInsightType.customerSegment,
        title: 'At-Risk Customer Segment',
        description:
            '${atRisk.length} previously regular customers haven\'t purchased in '
            'over 45 days. These customers spent an average of '
            '₹${(atRisk.fold(0.0, (s, c) => s + c.averageOrderValue) / atRisk.length).toStringAsFixed(0)} '
            'per visit. Consider a targeted loyalty offer to re-engage them.',
        data: {
          'customerCount': atRisk.length,
          'avgOrderValue':
              atRisk.fold(0.0, (s, c) => s + c.averageOrderValue) /
                  atRisk.length,
        },
        confidence: 0.75,
        generatedAt: DateTime.now(),
      ));
    }

    if (loyalCustomers.isNotEmpty) {
      final topCats = _getTopCategories(loyalCustomers);
      results.add(AIInsight(
        id: 'loyal_${DateTime.now().millisecondsSinceEpoch}',
        type: AIInsightType.customerSegment,
        title: 'Loyal Customer Preferences',
        description:
            '${loyalCustomers.length} loyal customers primarily purchase from '
            '${topCats.take(2).join(" and ")}. Ensuring consistent stock in these '
            'categories will retain their business.',
        data: {
          'customerCount': loyalCustomers.length,
          'topCategories': topCats,
        },
        confidence: 0.80,
        generatedAt: DateTime.now(),
      ));
    }

    return results;
  }

  // ── Restocking Insights ───────────────────────────────────────────────────

  List<AIInsight> generateRestockingInsights(
    List<RestockingRequirement> requirements,
    List<ProductAssociation> associations,
  ) {
    final List<AIInsight> insights = [];

    if (requirements.isEmpty) return insights;

    // Group by category to spot patterns
    final Map<String, int> categoryDeficits = {};
    for (final req in requirements) {
      categoryDeficits[req.category] =
          (categoryDeficits[req.category] ?? 0) + 1;
    }
    final topCategory = categoryDeficits.entries.isNotEmpty
        ? (categoryDeficits.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .first
        : null;

    if (topCategory != null && topCategory.value >= 3) {
      insights.add(AIInsight(
        id: 'restock_cat_${DateTime.now().millisecondsSinceEpoch}',
        type: AIInsightType.restockingInsight,
        title: 'Category Stock Pattern: ${topCategory.key}',
        description:
            '${topCategory.value} products in the "${topCategory.key}" category '
            'are simultaneously low on stock. This may indicate a supplier delivery '
            'delay or unusually high demand. Consider a bulk order for this category.',
        data: {
          'category': topCategory.key,
          'lowStockCount': topCategory.value,
        },
        confidence: 0.78,
        generatedAt: DateTime.now(),
      ));
    }

    // High-value restocking
    final highValue = requirements
        .where((r) => r.estimatedCost > 5000)
        .toList();
    if (highValue.isNotEmpty) {
      insights.add(AIInsight(
        id: 'restock_highval_${DateTime.now().millisecondsSinceEpoch}',
        type: AIInsightType.restockingInsight,
        title: 'High-Value Restock Required',
        description:
            '${highValue.length} high-value products need restocking with an '
            'estimated total procurement cost of ₹${highValue.fold(0.0, (s, r) => s + r.estimatedCost).toStringAsFixed(0)}. '
            'Prioritize these to prevent revenue loss.',
        data: {
          'productCount': highValue.length,
          'totalCost': highValue.fold(
              0.0, (s, r) => s + r.estimatedCost),
        },
        confidence: 0.90,
        generatedAt: DateTime.now(),
      ));
    }

    return insights;
  }

  // ── Demand Forecast ───────────────────────────────────────────────────────

  List<AIInsight> generateDemandForecast(
    List<SaleModel> recentSales,
    List<SaleModel> lastYearSales,
  ) {
    final List<AIInsight> insights = [];

    if (recentSales.isEmpty) return insights;

    // Compare recent 7-day sales to prior week
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final twoWeeksAgo = now.subtract(const Duration(days: 14));

    final recentWeek = recentSales
        .where((s) => s.timestamp.isAfter(weekAgo))
        .toList();
    final priorWeek = recentSales
        .where((s) =>
            s.timestamp.isAfter(twoWeeksAgo) &&
            s.timestamp.isBefore(weekAgo))
        .toList();

    if (recentWeek.isEmpty || priorWeek.isEmpty) return insights;

    final recentRevenue =
        recentWeek.fold(0.0, (s, sale) => s + sale.totalAmount);
    final priorRevenue =
        priorWeek.fold(0.0, (s, sale) => s + sale.totalAmount);

    if (priorRevenue > 0) {
      final growth = ((recentRevenue - priorRevenue) / priorRevenue) * 100;
      if (growth > 20) {
        insights.add(AIInsight(
          id: 'demand_growth_${DateTime.now().millisecondsSinceEpoch}',
          type: AIInsightType.demandForecast,
          title: 'Sales Momentum Detected',
          description:
              'Sales in the last 7 days (₹${recentRevenue.toStringAsFixed(0)}) '
              'are ${growth.abs().toStringAsFixed(1)}% higher than the prior week. '
              'Ensure stock levels are adequate to sustain this growth.',
          data: {
            'recentRevenue': recentRevenue,
            'priorRevenue': priorRevenue,
            'growthPercent': growth,
          },
          confidence: 0.82,
          generatedAt: DateTime.now(),
        ));
      } else if (growth < -20) {
        insights.add(AIInsight(
          id: 'demand_drop_${DateTime.now().millisecondsSinceEpoch}',
          type: AIInsightType.demandForecast,
          title: 'Sales Decline Detected',
          description:
              'Sales dropped by ${growth.abs().toStringAsFixed(1)}% compared to last week. '
              'Review pricing, product availability, and competitor activity.',
          data: {
            'recentRevenue': recentRevenue,
            'priorRevenue': priorRevenue,
            'growthPercent': growth,
          },
          confidence: 0.75,
          generatedAt: DateTime.now(),
        ));
      }
    }

    return insights;
  }

  // ── Supplier Quality Insights ─────────────────────────────────────────────

  List<AIInsight> generateSupplierInsights(
    Map<String, List<dynamic>> damagedBySupplier,
  ) {
    final List<AIInsight> insights = [];

    for (final entry in damagedBySupplier.entries) {
      if (entry.value.length >= 3) {
        insights.add(AIInsight(
          id: 'supplier_quality_${entry.key}',
          type: AIInsightType.supplierIssue,
          title: 'Recurring Quality Issue: ${entry.key}',
          description:
              'Supplier "${entry.key}" has ${entry.value.length} damaged product '
              'reports. Consider raising a quality concern, requesting replacements, '
              'or evaluating alternative suppliers for affected products.',
          data: {
            'supplierName': entry.key,
            'reportCount': entry.value.length,
          },
          confidence: 0.88,
          generatedAt: DateTime.now(),
        ));
      }
    }

    return insights;
  }

  List<String> _getTopCategories(List<CustomerInsight> customers) {
    final Map<String, int> catCount = {};
    for (final c in customers) {
      for (final cat in c.frequentCategories) {
        catCount[cat] = (catCount[cat] ?? 0) + 1;
      }
    }
    final sorted = catCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) => e.key).toList();
  }
}
