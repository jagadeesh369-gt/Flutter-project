import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/donation_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/distribution_provider.dart';
import '../services/database_service.dart';
import '../services/preferences_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import 'main_shell_screen.dart';

/// Screen 1: Splash Screen
/// Displays FoodBridge branding, logo, and tagline with smooth transition.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutBack,
      ),
    );

    _animController.forward();
    _bootstrapApplication();
  }

  Future<void> _bootstrapApplication() async {
    final startTime = DateTime.now();

    // 1. Initialize Database & sample demo data on first launch
    final dbService = DatabaseService.instance;
    final prefs = await PreferencesService.getInstance();

    final isEmpty = await dbService.isDatabaseEmpty();
    if (isEmpty && prefs.isFirstRun) {
      await dbService.preloadDemoData();
      await prefs.setFirstRunCompleted();
    }

    // 2. Pre-fetch provider states
    if (mounted) {
      await Future.wait([
        context.read<InventoryProvider>().loadInventory(),
        context.read<DonationProvider>().loadDonations(),
        context.read<DistributionProvider>().loadDistributions(),
        context.read<DashboardProvider>().refreshDashboard(),
      ]);
    }

    // Ensure splash remains visible for at least 2 seconds for pleasant UX
    final elapsed = DateTime.now().difference(startTime);
    final remaining = const Duration(milliseconds: 2000) - elapsed;
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, __, ___) => const MainShellScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // FoodBridge Logo Container
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.volunteer_activism_rounded,
                      size: 60,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Brand Name
                const Text(
                  AppConstants.appName,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Food Bank Inventory & Donation Tracker',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFE8F5EC),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Tagline
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    '"${AppConstants.appTagline}"',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFFD1E7DD),
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // Loading Indicator
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

