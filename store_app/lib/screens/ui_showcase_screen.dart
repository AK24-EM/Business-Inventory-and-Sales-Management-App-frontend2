import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../widgets/widgets.dart';
import '../models/product_model.dart';
import '../models/inventory_model.dart';

/// UI Showcase Screen - Demonstrates all available UI components
/// Navigate to this screen to see all widgets in action
class UIShowcaseScreen extends StatelessWidget {
  const UIShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('UI Component Showcase'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const _InfoDialog(),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            context,
            'Greeting Cards',
            [
              const GreetingCard(
                userName: 'John Doe',
                role: 'Owner',
                subtitle: 'Managing 3 stores across Mumbai',
              ),
              const SizedBox(height: 10),
              const GreetingCard(
                userName: 'Sarah Manager',
                role: 'Manager',
              ),
              const SizedBox(height: 10),
              const GreetingCard(
                userName: 'Mike Employee',
                role: 'Employee',
              ),
            ],
          ),
          _buildSection(
            context,
            'Status Badges',
            [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  StatusBadge(
                    label: 'IN STOCK',
                    color: AppColors.success,
                    icon: Icons.check_circle,
                  ),
                  StatusBadge(
                    label: 'LOW STOCK',
                    color: AppColors.warning,
                    icon: Icons.warning_amber,
                  ),
                  StatusBadge(
                    label: 'OUT OF STOCK',
                    color: AppColors.error,
                    icon: Icons.error,
                  ),
                  StatusBadge(
                    label: 'ACTIVE',
                    color: AppColors.info,
                    icon: Icons.check_circle,
                  ),
                  StatusBadge(
                    label: 'PENDING',
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
          _buildSection(
            context,
            'Action Chips',
            [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    icon: Icons.edit,
                    label: 'Edit',
                    color: AppColors.primary,
                    onTap: () {},
                  ),
                  ActionChip(
                    icon: Icons.delete,
                    label: 'Delete',
                    color: AppColors.error,
                    onTap: () {},
                  ),
                  ActionChip(
                    icon: Icons.visibility,
                    label: 'View',
                    color: AppColors.secondary,
                    onTap: () {},
                  ),
                  ActionChip(
                    icon: Icons.share,
                    label: 'Share',
                    color: AppColors.info,
                    onTap: () {},
                    isCompact: true,
                  ),
                ],
              ),
            ],
          ),
          _buildSection(
            context,
            'Metric Cards',
            [
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
            ],
          ),
          _buildSection(
            context,
            'Quick Action Tiles',
            [
              GridView.count(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  QuickActionTile(
                    icon: Icons.point_of_sale,
                    label: 'New Sale',
                    color: AppColors.primary,
                    onTap: () {},
                  ),
                  QuickActionTile(
                    icon: Icons.inventory_2,
                    label: 'Inventory',
                    color: AppColors.secondary,
                    onTap: () {},
                    badge: 5,
                  ),
                  QuickActionTile(
                    icon: Icons.analytics,
                    label: 'Analytics',
                    color: AppColors.info,
                    onTap: () {},
                  ),
                  QuickActionTile(
                    icon: Icons.settings,
                    label: 'Settings',
                    color: AppColors.textSecondary,
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
          _buildSection(
            context,
            'Info Banners',
            [
              InfoBanner(
                message: '5 products are running low on stock',
                icon: Icons.warning_amber_rounded,
                color: AppColors.warning,
                onTap: () {},
              ),
              const SizedBox(height: 10),
              InfoBanner(
                message: 'New sale recorded successfully',
                icon: Icons.check_circle,
                color: AppColors.success,
                onDismiss: () {},
              ),
              const SizedBox(height: 10),
              InfoBanner(
                message: 'Failed to sync data. Tap to retry',
                icon: Icons.error,
                color: AppColors.error,
                onTap: () {},
              ),
              const SizedBox(height: 10),
              InfoBanner(
                message: 'System maintenance scheduled for tonight',
                icon: Icons.info,
                color: AppColors.info,
                onTap: () {},
              ),
            ],
          ),
          _buildSection(
            context,
            'Product Images',
            [
              const Text(
                'Category-based placeholders (no image URL)',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  ProductThumbnail(category: 'Electronics', size: 60),
                  ProductThumbnail(category: 'Food', size: 60),
                  ProductThumbnail(category: 'Clothing', size: 60),
                  ProductThumbnail(category: 'Books', size: 60),
                  ProductThumbnail(category: 'Toys', size: 60),
                  ProductThumbnail(category: 'Sports', size: 60),
                  ProductThumbnail(category: 'Home', size: 60),
                  ProductThumbnail(category: 'Beauty', size: 60),
                ],
              ),
            ],
          ),
          _buildSection(
            context,
            'Product Cards',
            [
              _buildExampleProductCard(),
              const SizedBox(height: 10),
              _buildCompactProductCard(),
            ],
          ),
          _buildSection(
            context,
            'Product Grid Cards',
            [
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 0.75,
                children: [
                  _buildGridProductCard('Electronics'),
                  _buildGridProductCard('Grocery'),
                ],
              ),
            ],
          ),
          _buildSection(
            context,
            'Inventory Cards',
            [
              _buildExampleInventoryCard(isLow: false),
              const SizedBox(height: 10),
              _buildExampleInventoryCard(isLow: true),
            ],
          ),
          _buildSection(
            context,
            'Chart Cards',
            [
              ChartCard(
                title: 'Sales Trend',
                subtitle: 'Last 7 days performance',
                actions: [
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {},
                  ),
                ],
                child: Container(
                  height: 200,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withValues(alpha: 0.1),
                        AppColors.secondary.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '📊 Chart Component\n(Use fl_chart package)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          _buildSection(
            context,
            'Stat Comparison',
            [
              ModernCard(
                padding: const EdgeInsets.all(16),
                child: const StatComparisonRow(
                  label1: 'This Week',
                  value1: '₹45,200',
                  color1: AppColors.primary,
                  label2: 'Last Week',
                  value2: '₹38,500',
                  color2: AppColors.secondary,
                ),
              ),
            ],
          ),
          _buildSection(
            context,
            'Empty States',
            [
              EmptyStateWidget(
                icon: Icons.inventory_2,
                title: 'No products found',
                subtitle: 'Add your first product to get started',
                action: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Add Product'),
                ),
              ),
            ],
          ),
          _buildSection(
            context,
            'Loading States',
            [
              const ShimmerCard(height: 80),
              const SizedBox(height: 10),
              Row(
                children: const [
                  Expanded(child: ShimmerCard(height: 100)),
                  SizedBox(width: 10),
                  Expanded(child: ShimmerCard(height: 100)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildExampleProductCard() {
    final product = ProductModel(
      id: '1',
      name: 'Premium Wireless Headphones',
      category: 'Electronics',
      description: 'High-quality wireless headphones',
      purchasePrice: 1500,
      sellingPrice: 2499,
      unit: 'pcs',
      barcode: '1234567890',
      imageUrl: null,
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
          icon: Icons.delete_outline,
          label: 'Delete',
          color: AppColors.error,
          onTap: () {},
        ),
      ],
      trailing: const StatusBadge(
        label: 'ACTIVE',
        color: AppColors.success,
      ),
    );
  }

  Widget _buildCompactProductCard() {
    final product = ProductModel(
      id: '2',
      name: 'Organic Green Tea - Premium Quality',
      category: 'Grocery',
      description: 'Premium organic green tea',
      purchasePrice: 120,
      sellingPrice: 199,
      unit: 'box',
      imageUrl: null,
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

  Widget _buildGridProductCard(String category) {
    final product = ProductModel(
      id: '3',
      name: '$category Product Example',
      category: category,
      description: 'Sample product',
      purchasePrice: 100,
      sellingPrice: 150,
      unit: 'pcs',
      imageUrl: null,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return ProductGridCard(
      product: product,
      onTap: () {},
      onAddToCart: () {},
    );
  }

  Widget _buildExampleInventoryCard({required bool isLow}) {
    final inventory = InventoryModel(
      id: '1',
      storeId: 'store1',
      productId: 'prod1',
      productName: isLow
          ? 'Product Running Low'
          : 'Well Stocked Product',
      category: 'Electronics',
      currentStock: isLow ? 8 : 45,
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
    );
  }
}

class _InfoDialog extends StatelessWidget {
  const _InfoDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('UI Showcase'),
      content: const SingleChildScrollView(
        child: Text(
          'This screen demonstrates all available UI components in the StoreIQ app.\n\n'
          'Components include:\n'
          '• Greeting Cards\n'
          '• Status Badges\n'
          '• Action Chips\n'
          '• Metric Cards\n'
          '• Quick Action Tiles\n'
          '• Info Banners\n'
          '• Product Images\n'
          '• Product Cards\n'
          '• Inventory Cards\n'
          '• Chart Cards\n'
          '• Empty States\n'
          '• Loading States\n\n'
          'See UI_REDESIGN_GUIDE.md for detailed documentation.',
          style: TextStyle(fontSize: 13),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
