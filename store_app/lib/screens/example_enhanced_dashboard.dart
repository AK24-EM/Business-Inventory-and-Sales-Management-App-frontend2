import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../widgets/modern_card.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/product_card.dart';
import '../widgets/inventory_card.dart';
import '../models/product_model.dart';
import '../models/inventory_model.dart';

/// This is an EXAMPLE showing how to use the new modern components
/// Copy patterns from here to update existing dashboards
class ExampleEnhancedDashboard extends StatelessWidget {
  const ExampleEnhancedDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Enhanced Dashboard Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modern greeting card
              const GreetingCard(
                userName: 'John Doe',
                role: 'Owner',
                subtitle: 'Managing 3 stores across Mumbai',
              ),
              const SizedBox(height: 20),

              // Quick Actions Grid
              const SectionHeader(
                title: 'Quick Actions',
                subtitle: 'Common tasks and shortcuts',
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  QuickActionTile(
                    icon: Icons.point_of_sale_rounded,
                    label: 'New Sale',
                    color: AppColors.primary,
                    onTap: () {},
                  ),
                  QuickActionTile(
                    icon: Icons.inventory_2_outlined,
                    label: 'Inventory',
                    color: AppColors.secondary,
                    onTap: () {},
                    badge: 5,
                  ),
                  QuickActionTile(
                    icon: Icons.analytics_outlined,
                    label: 'Analytics',
                    color: AppColors.info,
                    onTap: () {},
                  ),
                  QuickActionTile(
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    color: AppColors.textSecondary,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Info Banner Example
              InfoBanner(
                message: '5 products are running low on stock',
                icon: Icons.warning_amber_rounded,
                color: AppColors.warning,
                onTap: () {},
              ),
              const SizedBox(height: 20),

              // Metrics Grid
              const SectionHeader(
                title: "Today's Performance",
                subtitle: 'Real-time store metrics',
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.5,
                children: [
                  MetricCard(
                    label: 'Total Revenue',
                    value: '₹${NumberFormat('#,##,##0').format(125000)}',
                    icon: Icons.currency_rupee,
                    color: AppColors.success,
                    subtitle: '+12% from yesterday',
                    trailing: const LiveIndicator(),
                  ),
                  MetricCard(
                    label: 'Transactions',
                    value: '248',
                    icon: Icons.receipt_long_outlined,
                    color: AppColors.primary,
                    subtitle: 'Avg ₹504 per bill',
                    trailing: const LiveIndicator(),
                  ),
                  MetricCard(
                    label: 'Items Sold',
                    value: '1,247',
                    icon: Icons.shopping_bag_outlined,
                    color: AppColors.info,
                    subtitle: 'Across all categories',
                  ),
                  MetricCard(
                    label: 'Low Stock',
                    value: '15',
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    subtitle: 'Needs attention',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Product Card Examples
              SectionHeader(
                title: 'Top Selling Products',
                subtitle: 'This week\'s best performers',
                onSeeAll: () {},
              ),
              const SizedBox(height: 12),
              _buildExampleProductCard(),
              const SizedBox(height: 10),
              _buildExampleProductCard2(),
              const SizedBox(height: 20),

              // Inventory Card Example
              SectionHeader(
                title: 'Low Stock Items',
                subtitle: 'Requires restocking',
                onSeeAll: () {},
              ),
              const SizedBox(height: 12),
              _buildExampleInventoryCard(),
              const SizedBox(height: 20),

              // Chart Card Example
              ChartCard(
                title: 'Sales Trend',
                subtitle: 'Last 7 days',
                actions: [
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {},
                  ),
                ],
                child: const SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(
                      'Chart goes here\n(Use fl_chart package)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Comparison Stats
              ModernCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Store Comparison',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    StatComparisonRow(
                      label1: 'Store A Revenue',
                      value1: '₹45,200',
                      color1: AppColors.primary,
                      label2: 'Store B Revenue',
                      value2: '₹38,500',
                      color2: AppColors.secondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExampleProductCard() {
    final product = ProductModel(
      id: '1',
      name: 'Premium Wireless Headphones',
      category: 'Electronics',
      description: 'High-quality wireless headphones with noise cancellation',
      purchasePrice: 1500,
      sellingPrice: 2499,
      unit: 'pcs',
      barcode: '1234567890',
      imageUrl: 'https://example.com/headphones.jpg', // Will show placeholder
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return ProductCard(
      product: product,
      onTap: () {},
      actions: [
        ActionChip(
          icon: Icons.edit_outlined,
          label: 'Edit',
          color: AppColors.primary,
          onTap: () {},
        ),
        ActionChip(
          icon: Icons.visibility_outlined,
          label: 'View',
          color: AppColors.secondary,
          onTap: () {},
        ),
      ],
      trailing: StatusBadge(
        label: 'ACTIVE',
        color: AppColors.success,
      ),
    );
  }

  Widget _buildExampleProductCard2() {
    final product = ProductModel(
      id: '2',
      name: 'Organic Green Tea',
      category: 'Grocery',
      description: 'Premium organic green tea leaves',
      purchasePrice: 120,
      sellingPrice: 199,
      unit: 'box',
      imageUrl: null, // Will show category-based placeholder
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return ProductCard(
      product: product,
      onTap: () {},
      isCompact: true,
    );
  }

  Widget _buildExampleInventoryCard() {
    final inventory = InventoryModel(
      id: '1',
      storeId: 'store1',
      productId: 'prod1',
      productName: 'Premium Wireless Headphones',
      category: 'Electronics',
      currentStock: 8,
      minimumStockLevel: 15,
      maximumStockLevel: 50,
      imageUrl: null,
      lastUpdated: DateTime.now(),
    );

    return InventoryCard(
      item: inventory,
      isManager: true,
      onReceive: () {},
      onAdjust: () {},
      onHistory: () {},
      onTap: () {},
    );
  }
}
