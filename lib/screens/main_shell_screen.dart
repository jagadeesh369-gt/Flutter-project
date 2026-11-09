import 'package:flutter/material.dart';
import '../widgets/bottom_navigation.dart';
import 'dashboard_screen.dart';
import 'donation_screen.dart';
import 'inventory_screen.dart';
import 'distribution_screen.dart';
import 'reports_screen.dart';

/// Main scaffold containing the modern 5-tab BottomNavigationBar.
class MainShellScreen extends StatefulWidget {
  final int initialIndex;
  const MainShellScreen({super.key, this.initialIndex = 0});

  @override
  State<MainShellScreen> createState() => MainShellScreenState();
}

class MainShellScreenState extends State<MainShellScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void switchTab(int index) {
    if (index >= 0 && index < 5) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      DashboardScreen(onNavigateTab: switchTab),
      const DonationScreen(),
      const InventoryScreen(),
      const DistributionScreen(),
      const ReportsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: FoodBridgeBottomNavigation(
        currentIndex: _currentIndex,
        onTabSelected: switchTab,
      ),
    );
  }
}

