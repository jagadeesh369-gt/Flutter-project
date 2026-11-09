import 'package:flutter/material.dart';
import '../models/inventory_model.dart';
import '../utils/app_colors.dart';
import '../utils/date_formatter.dart';
import 'status_badge.dart';

/// Professional card displaying an individual food inventory item with status indicators.
class FoodItemCard extends StatelessWidget {
  final InventoryModel item;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const FoodItemCard({
    super.key,
    required this.item,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  BadgeType _getStockBadgeType() {
    switch (item.status) {
      case StockStatus.expired:
        return BadgeType.danger;
      case StockStatus.outOfStock:
        return BadgeType.danger;
      case StockStatus.lowStock:
        return BadgeType.warning;
      case StockStatus.sufficient:
        return BadgeType.success;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Rice and Grains':
        return AppColors.catRiceGrains;
      case 'Vegetables':
        return AppColors.catVegetables;
      case 'Fruits':
        return AppColors.catFruits;
      case 'Dairy Products':
        return AppColors.catDairy;
      case 'Packaged Food':
        return AppColors.catPackaged;
      case 'Pulses':
        return AppColors.catPulses;
      default:
        return AppColors.catOther;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryColor = _getCategoryColor(item.category);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2822) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isExpired
              ? AppColors.danger.withOpacity(0.5)
              : item.isLowStock
                  ? AppColors.warning.withOpacity(0.5)
                  : isDark
                      ? const Color(0xFF2E3D35)
                      : const Color(0xFFE2E8F0),
          width: (item.isExpired || item.isLowStock) ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Category chip + Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: categoryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item.category,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: categoryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(
                      label: item.statusLabel,
                      type: _getStockBadgeType(),
                      icon: item.isExpired
                          ? Icons.warning_amber_rounded
                          : item.isLowStock
                              ? Icons.priority_high_rounded
                              : Icons.check_circle_outline,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Middle: Food Name and Available Quantity
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.foodName,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: DateFormatter.formatQuantity(item.availableQuantity),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: item.isOutOfStock
                                  ? AppColors.danger
                                  : AppColors.primary,
                            ),
                          ),
                          TextSpan(
                            text: ' ${item.unit}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Divider
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark ? const Color(0xFF2B3A31) : const Color(0xFFF1F5F9),
                ),
                const SizedBox(height: 10),

                // Bottom Row: Expiry information and Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.event_outlined,
                          size: 15,
                          color: item.isExpired
                              ? AppColors.danger
                              : isDark
                                  ? Colors.grey[400]
                                  : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Exp: ${DateFormatter.format(item.expiryDate)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: item.isExpired
                                ? AppColors.danger
                                : isDark
                                    ? Colors.grey[400]
                                    : const Color(0xFF64748B),
                          ),
                        ),
                        if (!item.isExpired) ...[
                          const SizedBox(width: 6),
                          Text(
                            '(${item.daysUntilExpiry}d left)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: item.isExpiringSoon
                                  ? AppColors.warning
                                  : AppColors.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onEdit != null)
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            color: isDark ? Colors.grey[300] : const Color(0xFF475569),
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Edit Item',
                            onPressed: onEdit,
                          ),
                        if (onDelete != null)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            color: AppColors.danger,
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Delete Item',
                            onPressed: onDelete,
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

