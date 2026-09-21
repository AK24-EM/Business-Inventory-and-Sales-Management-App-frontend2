import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/inventory_model.dart';
import 'product_image.dart';
import 'modern_card.dart';

/// Enhanced inventory card with image, stock visualization, and actions
class InventoryCard extends StatelessWidget {
  final InventoryModel item;
  final bool isManager;
  final VoidCallback? onReceive;
  final VoidCallback? onAdjust;
  final VoidCallback? onHistory;
  final VoidCallback? onTap;

  const InventoryCard({
    super.key,
    required this.item,
    required this.isManager,
    this.onReceive,
    this.onAdjust,
    this.onHistory,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOut = item.isOutOfStock;
    final isLow = item.isLowStock && !isOut;
    final statusColor = isOut
        ? AppColors.error
        : isLow
            ? AppColors.warning
            : AppColors.secondary;
    final statusBg = isOut
        ? AppColors.errorBg
        : isLow
            ? AppColors.warningBg
            : AppColors.successBg.withValues(alpha: 0.6);
    final statusLabel = isOut
        ? 'OUT OF STOCK'
        : isLow
            ? 'LOW STOCK'
            : 'IN STOCK';

    final fraction = item.minimumStockLevel > 0
        ? (item.currentStock / (item.minimumStockLevel * 3)).clamp(0.0, 1.0)
        : item.currentStock > 0
            ? 1.0
            : 0.0;

    return ModernCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      showBorder: true,
      customShadow: isOut || isLow
          ? [
              BoxShadow(
                color: statusColor.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ]
          : AppColors.subtleShadow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row with image and info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              ProductThumbnail(
                imageUrl: item.imageUrl,
                category: item.category,
                size: 72,
              ),
              const SizedBox(width: 12),

              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.category,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    StatusBadge(
                      label: statusLabel,
                      color: statusColor,
                      backgroundColor: statusBg,
                      icon: isOut
                          ? Icons.error_outline
                          : isLow
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle_outline,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Stock visualization
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 8,
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
                const SizedBox(height: 10),

                // Stock numbers
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StockStat(
                      label: 'Current Stock',
                      value: '${item.currentStock}',
                      color: statusColor,
                      isLarge: true,
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: AppColors.border,
                    ),
                    _StockStat(
                      label: 'Min Level',
                      value: '${item.minimumStockLevel}',
                      color: AppColors.textSecondary,
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: AppColors.border,
                    ),
                    _StockStat(
                      label: 'Max Level',
                      value: '${item.maximumStockLevel}',
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Manager actions
          if (isManager) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                if (onReceive != null)
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.add_box_outlined,
                      label: 'Receive',
                      color: AppColors.secondary,
                      onTap: onReceive!,
                    ),
                  ),
                if (onReceive != null && onAdjust != null)
                  const SizedBox(width: 8),
                if (onAdjust != null)
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.tune_rounded,
                      label: 'Adjust',
                      color: AppColors.warning,
                      onTap: onAdjust!,
                    ),
                  ),
                if (onAdjust != null && onHistory != null)
                  const SizedBox(width: 8),
                if (onHistory != null)
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.history_rounded,
                      label: 'History',
                      color: AppColors.primary,
                      onTap: onHistory!,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StockStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isLarge;

  const _StockStat({
    required this.label,
    required this.value,
    required this.color,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: isLarge ? 20 : 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact inventory item for quick scanning
class InventoryListItem extends StatelessWidget {
  final InventoryModel item;
  final VoidCallback? onTap;

  const InventoryListItem({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOut = item.isOutOfStock;
    final isLow = item.isLowStock && !isOut;
    final statusColor = isOut
        ? AppColors.error
        : isLow
            ? AppColors.warning
            : AppColors.success;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Image
            ProductThumbnail(
              imageUrl: item.imageUrl,
              category: item.category,
              size: 44,
            ),
            const SizedBox(width: 10),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.category,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Stock indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${item.currentStock}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
