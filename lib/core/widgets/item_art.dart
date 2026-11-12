import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Category-aware artwork used by the admin catalogue and the collector shop.
/// Shows an uploaded photo when one exists and a branded icon tile otherwise.
class ItemArt extends StatelessWidget {
  const ItemArt({
    super.key,
    required this.category,
    this.imageUrl,
    this.height = 110,
    this.radius = 12,
  });

  final String category;
  final String? imageUrl;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final tint = itemColor(category);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        height: height,
        width: double.infinity,
        color: tint.withValues(alpha: 0.13),
        child: imageUrl == null || imageUrl!.isEmpty
            ? _fallback(tint)
            : Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallback(tint),
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : _fallback(tint),
              ),
      ),
    );
  }

  Widget _fallback(Color tint) {
    return Center(
      child: Container(
        width: height * 0.52,
        height: height * 0.52,
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: Icon(itemIcon(category), color: tint, size: height * 0.3),
      ),
    );
  }
}

IconData itemIcon(String category) => switch (category) {
  'Stationery' => Icons.edit_outlined,
  'Books' => Icons.menu_book_outlined,
  'Bags' => Icons.backpack_outlined,
  'Maths' => Icons.calculate_outlined,
  'Art' => Icons.palette_outlined,
  'Lunch' => Icons.lunch_dining_outlined,
  _ => Icons.redeem_outlined,
};

Color itemColor(String category) => switch (category) {
  'Stationery' => AppColors.leaf,
  'Books' => AppColors.sky,
  'Bags' => AppColors.forest,
  'Maths' => const Color(0xFF7A4F00),
  'Art' => const Color(0xFF9A3E8F),
  'Lunch' => const Color(0xFFB45309),
  _ => AppColors.muted,
};

const itemCategories = [
  'Stationery',
  'Books',
  'Bags',
  'Maths',
  'Art',
  'Lunch',
  'Other',
];
