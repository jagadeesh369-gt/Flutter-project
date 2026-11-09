import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/donation_provider.dart';
import '../providers/distribution_provider.dart';
import '../providers/dashboard_provider.dart';
import '../services/database_service.dart';
import '../services/preferences_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';

/// Screen 9: Settings
/// Handles user preferences, theme toggling, database maintenance,
/// app credentials, and SDG 2 & SDG 12 declarations.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _expiryAlerts = true;
  bool _lowStockAlerts = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await PreferencesService.getInstance();
    setState(() {
      _expiryAlerts = prefs.expiryAlertsEnabled;
      _lowStockAlerts = prefs.lowStockAlertsEnabled;
    });
  }

  void _confirmResetDemoData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Demo Data?'),
        content: const Text(
          'This action will clear all current records and restore realistic default '
          'food items, donations, and distribution transactions.\n\n'
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              Navigator.pop(ctx);
              await DatabaseService.instance.resetToDemoData();
              if (mounted) {
                await Future.wait([
                  context.read<InventoryProvider>().loadInventory(),
                  context.read<DonationProvider>().loadDonations(),
                  context.read<DistributionProvider>().loadDistributions(),
                  context.read<DashboardProvider>().refreshDashboard(),
                ]);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Demo data reloaded successfully!'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            },
            child: const Text('Reset Data', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmClearAllData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Database Records?'),
        content: const Text(
          'Warning: This will permanently delete all donations, inventory items, '
          'and distribution logs. The application will start completely empty.\n\n'
          'This action cannot be undone.',
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
              await DatabaseService.instance.clearAllData();
              if (mounted) {
                await Future.wait([
                  context.read<InventoryProvider>().loadInventory(),
                  context.read<DonationProvider>().loadDonations(),
                  context.read<DistributionProvider>().loadDistributions(),
                  context.read<DashboardProvider>().refreshDashboard(),
                ]);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All database records cleared.'),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.volunteer_activism, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 10),
            const Text(AppConstants.appName),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Version ${AppConstants.appVersion} (Practical Lab Demo Build)',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 12),
              const Text(
                'FoodBridge is an automated Food Bank Inventory and Donation Tracker '
                'engineered with Flutter, Provider, ChangeNotifier, and SQLite.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              const Text(
                AppConstants.sdgGoal2Title,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.primary),
              ),
              const SizedBox(height: 4),
              const Text(
                AppConstants.sdgGoal2Description,
                style: TextStyle(fontSize: 12, height: 1.35),
              ),
              const SizedBox(height: 12),
              const Text(
                AppConstants.sdgGoal12Title,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFFD97706)),
              ),
              const SizedBox(height: 4),
              const Text(
                AppConstants.sdgGoal12Description,
                style: TextStyle(fontSize: 12, height: 1.35),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Info'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. Profile Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2822) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF2E3D35) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary,
                  child: const Text(
                    'FB',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Food Bank Coordinator',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Admin Operations • Local Node',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Verified',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. Appearance & Preferences Section
          const Text(
            'Appearance & System Preferences',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2822) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF2E3D35) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Switch between light and dark UI themes'),
                  secondary: const Icon(Icons.dark_mode_outlined, color: AppColors.primary),
                  value: isDark,
                  onChanged: (val) => themeProvider.toggleTheme(val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Expiry Alert Notifications', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Highlight items expiring within 7 days'),
                  secondary: const Icon(Icons.notifications_active_outlined, color: AppColors.warning),
                  value: _expiryAlerts,
                  onChanged: (val) async {
                    final prefs = await PreferencesService.getInstance();
                    await prefs.setExpiryAlertsEnabled(val);
                    setState(() => _expiryAlerts = val);
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Low Stock Alerts', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Warn when available quantity drops below 20 units'),
                  secondary: const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
                  value: _lowStockAlerts,
                  onChanged: (val) async {
                    final prefs = await PreferencesService.getInstance();
                    await prefs.setLowStockAlertsEnabled(val);
                    setState(() => _lowStockAlerts = val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3. Database & Data Maintenance Section
          const Text(
            'Database & Demo Data',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2822) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF2E3D35) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.restart_alt_rounded, color: AppColors.primary),
                  title: const Text('Reset to Sample Demo Data', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Reload pre-populated realistic inventory, donors & relief items'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _confirmResetDemoData,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever_outlined, color: AppColors.danger),
                  title: const Text('Clear All Records', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.danger)),
                  subtitle: const Text('Wipe all SQLite database tables clean'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _confirmClearAllData,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 4. About & SDG Justification
          const Text(
            'Information & Sustainable Goals',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2822) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF2E3D35) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline, color: AppColors.info),
                  title: const Text('About FoodBridge & SDG Justification', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('UN SDG 2 (Zero Hunger) & SDG 12 compliance'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showAboutDialog,
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.code_rounded, color: AppColors.primary),
                  title: Text('Architecture & Tech Stack', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Flutter • Provider • ChangeNotifier • SQLite'),
                  trailing: Text('v1.0.0', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }
}

