import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/inventory_model.dart';
import '../providers/inventory_provider.dart';
import '../providers/dashboard_provider.dart';
import '../utils/app_colors.dart';
import '../utils/date_formatter.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_badge.dart';

/// Screen 6: Expiry Management
/// Dedicated tracking center classifying inventory by expiry urgency:
/// Expired, Expiring within 7 Days, Expiring within 30 Days, and Fresh Items.
class ExpiryScreen extends StatefulWidget {
  final int initialTab;
  const ExpiryScreen({super.key, this.initialTab = 0});

  @override
  State<ExpiryScreen> createState() => _ExpiryScreenState();
}

class _ExpiryScreenState extends State<ExpiryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _disposeExpiredItem(BuildContext context, InventoryModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Expired Stock?'),
        content: Text(
          'Remove "${item.foodName}" (${DateFormatter.formatQuantity(item.availableQuantity)} ${item.unit}) '
          'from inventory to prevent accidental distribution?\n\n'
          'Item expired on ${DateFormatter.format(item.expiryDate)}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<InventoryProvider>().deleteFoodItem(item.id);
              if (mounted) {
                await context.read<DashboardProvider>().refreshDashboard();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Removed expired item "${item.foodName}" safely.'),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
            },
            child: const Text('Remove Stock', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expiry Management'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? Colors.grey[400] : const Color(0xFF64748B),
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'Expired'),
            Tab(text: 'Expiring ≤ 7 Days'),
            Tab(text: 'Expiring ≤ 30 Days'),
            Tab(text: 'Fresh (>30 Days)'),
          ],
        ),
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, child) {
          final expiredItems = provider.getExpiredItems();
          final expiring7Days = provider.getExpiringItems();
          final expiring30Days = provider.getExpiringWithin30Days();
          final freshItems = provider.getFreshItems();

          return Column(
            children: [
              // Food Safety Notification Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: const Color(0xFFFFEBEE),
                child: const Row(
                  children: [
                    Icon(Icons.gpp_bad_outlined, color: AppColors.danger, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'CRITICAL SAFETY POLICY: Never distribute food past its expiration date.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildExpiryList(
                      context,
                      items: expiredItems,
                      isDark: isDark,
                      emptyMessage: 'No expired food items in inventory. Excellent!',
                      urgencyType: BadgeType.danger,
                    ),
                    _buildExpiryList(
                      context,
                      items: expiring7Days,
                      isDark: isDark,
                      emptyMessage: 'No items expiring within the next 7 days.',
                      urgencyType: BadgeType.warning,
                    ),
                    _buildExpiryList(
                      context,
                      items: expiring30Days,
                      isDark: isDark,
                      emptyMessage: 'No items expiring within the next 30 days.',
                      urgencyType: BadgeType.info,
                    ),
                    _buildExpiryList(
                      context,
                      items: freshItems,
                      isDark: isDark,
                      emptyMessage: 'No long-shelf-life items currently recorded.',
                      urgencyType: BadgeType.success,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExpiryList(
    BuildContext context, {
    required List<InventoryModel> items,
    required bool isDark,
    required String emptyMessage,
    required BadgeType urgencyType,
  }) {
    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.verified_outlined,
        title: 'All Clear',
        message: emptyMessage,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final days = item.daysUntilExpiry;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2822) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: urgencyType == BadgeType.danger
                  ? AppColors.danger.withOpacity(0.5)
                  : urgencyType == BadgeType.warning
                      ? AppColors.warning.withOpacity(0.5)
                      : isDark
                          ? const Color(0xFF2E3D35)
                          : const Color(0xFFE2E8F0),
              width: (urgencyType == BadgeType.danger || urgencyType == BadgeType.warning) ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.foodName,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ),
                  StatusBadge(
                    label: days < 0
                        ? 'Expired ${-days}d ago'
                        : days == 0
                            ? 'Expires Today'
                            : '$days days left',
                    type: urgencyType,
                    icon: Icons.timer_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    item.category,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('•', style: TextStyle(color: Colors.grey)),
                  const SizedBox(width: 8),
                  Text(
                    'Available: ${DateFormatter.formatQuantity(item.availableQuantity)} ${item.unit}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[300] : const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Divider(
                height: 1,
                color: isDark ? const Color(0xFF2E3D35) : const Color(0xFFF1F5F9),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.event_busy_outlined, size: 15, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Text(
                        'Expiry Date: ${DateFormatter.format(item.expiryDate)}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  if (item.isExpired)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () => _disposeExpiredItem(context, item),
                      icon: const Icon(Icons.delete_outline, size: 15, color: Colors.white),
                      label: const Text(
                        'Dispose Stock',
                        style: TextStyle(fontSize: 11, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

