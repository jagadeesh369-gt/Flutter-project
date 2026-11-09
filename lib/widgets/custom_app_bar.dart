import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import '../screens/expiry_screen.dart';
import '../screens/history_screen.dart';
import '../screens/settings_screen.dart';
import '../utils/app_colors.dart';

/// Reusable top AppBar with branding, badges, and quick shortcut actions.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool showActions;
  final List<Widget>? customActions;

  const CustomAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showActions = true,
    this.customActions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 1),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
              ),
            ),
          ],
        ],
      ),
      actions: customActions ??
          (showActions
              ? [
                  // Expiry Alert Icon with badge
                  Consumer<DashboardProvider>(
                    builder: (context, dash, child) {
                      final count = dash.expiringSoonCount + dash.expiredCount;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_active_outlined),
                            color: count > 0 ? AppColors.warning : AppColors.primary,
                            tooltip: 'Expiry Alerts',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ExpiryScreen()),
                              );
                            },
                          ),
                          if (count > 0)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.danger,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$count',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                  // Transaction History Icon
                  IconButton(
                    icon: const Icon(Icons.receipt_long_outlined),
                    color: AppColors.primary,
                    tooltip: 'Transaction History',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HistoryScreen()),
                      );
                    },
                  ),

                  // Settings Icon
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    color: AppColors.primary,
                    tooltip: 'Settings',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                ]
              : null),
    );
  }
}

