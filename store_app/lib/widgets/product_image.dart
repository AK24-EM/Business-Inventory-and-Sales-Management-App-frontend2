import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_theme.dart';

/// Product image widget with fallback placeholder and loading states
class ProductImage extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final double borderRadius;
  final BoxFit fit;
  final String? category;

  const ProductImage({
    super.key,
    this.imageUrl,
    this.size = 80,
    this.borderRadius = 12,
    this.fit = BoxFit.cover,
    this.category,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: size,
          height: size,
          fit: fit,
          placeholder: (context, url) => _buildPlaceholder(),
          errorWidget: (context, url, error) => _buildPlaceholder(),
        ),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    final icon = _getCategoryIcon(category);
    final color = _getCategoryColor(category);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Icon(
        icon,
        size: size * 0.45,
        color: color.withValues(alpha: 0.7),
      ),
    );
  }

  IconData _getCategoryIcon(String? category) {
    if (category == null) return Icons.inventory_2_rounded;

    final cat = category.toLowerCase();
    if (cat.contains('electronic')) return Icons.devices_rounded;
    if (cat.contains('food') || cat.contains('grocery')) {
      return Icons.restaurant_rounded;
    }
    if (cat.contains('cloth') || cat.contains('fashion')) {
      return Icons.checkroom_rounded;
    }
    if (cat.contains('book')) return Icons.menu_book_rounded;
    if (cat.contains('toy')) return Icons.toys_rounded;
    if (cat.contains('sport')) return Icons.sports_soccer_rounded;
    if (cat.contains('home')) return Icons.home_rounded;
    if (cat.contains('beauty') || cat.contains('cosmetic')) {
      return Icons.face_rounded;
    }
    if (cat.contains('health') || cat.contains('medical')) {
      return Icons.medical_services_rounded;
    }
    if (cat.contains('auto') || cat.contains('car')) {
      return Icons.directions_car_rounded;
    }
    if (cat.contains('garden')) return Icons.yard_rounded;
    if (cat.contains('pet')) return Icons.pets_rounded;
    if (cat.contains('stationery')) return Icons.edit_note_rounded;

    return Icons.inventory_2_rounded;
  }

  Color _getCategoryColor(String? category) {
    if (category == null) return AppColors.primary;

    final cat = category.toLowerCase();
    if (cat.contains('electronic')) return const Color(0xFF3B82F6);
    if (cat.contains('food') || cat.contains('grocery')) {
      return const Color(0xFF10B981);
    }
    if (cat.contains('cloth') || cat.contains('fashion')) {
      return const Color(0xFFEC4899);
    }
    if (cat.contains('book')) return const Color(0xFF8B5CF6);
    if (cat.contains('toy')) return const Color(0xFFF59E0B);
    if (cat.contains('sport')) return const Color(0xFF06B6D4);
    if (cat.contains('home')) return const Color(0xFF0D9488);
    if (cat.contains('beauty') || cat.contains('cosmetic')) {
      return const Color(0xFFF43F5E);
    }
    if (cat.contains('health') || cat.contains('medical')) {
      return const Color(0xFF14B8A6);
    }
    if (cat.contains('auto') || cat.contains('car')) {
      return const Color(0xFF6366F1);
    }
    if (cat.contains('garden')) return const Color(0xFF22C55E);
    if (cat.contains('pet')) return const Color(0xFFA855F7);
    if (cat.contains('stationery')) return const Color(0xFF64748B);

    return AppColors.primary;
  }
}

/// Small product thumbnail for lists
class ProductThumbnail extends StatelessWidget {
  final String? imageUrl;
  final String? category;
  final double size;

  const ProductThumbnail({
    super.key,
    this.imageUrl,
    this.category,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return ProductImage(
      imageUrl: imageUrl,
      category: category,
      size: size,
      borderRadius: 10,
    );
  }
}

/// Large product image for details
class ProductHeroImage extends StatelessWidget {
  final String? imageUrl;
  final String? category;
  final double height;

  const ProductHeroImage({
    super.key,
    this.imageUrl,
    this.category,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceVariant,
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ProductImage(
        imageUrl: imageUrl,
        category: category,
        size: height,
        borderRadius: 16,
        fit: BoxFit.contain,
      ),
    );
  }
}
