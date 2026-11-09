import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/theme_provider.dart';
import 'providers/donation_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/distribution_provider.dart';
import 'providers/dashboard_provider.dart';
import 'services/preferences_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize persistent preferences
  final prefsService = await PreferencesService.getInstance();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(prefsService),
        ),
        ChangeNotifierProvider<DonationProvider>(
          create: (_) => DonationProvider(),
        ),
        ChangeNotifierProvider<InventoryProvider>(
          create: (_) => InventoryProvider(),
        ),
        ChangeNotifierProvider<DistributionProvider>(
          create: (_) => DistributionProvider(),
        ),
        ChangeNotifierProvider<DashboardProvider>(
          create: (_) => DashboardProvider(),
        ),
      ],
      child: const FoodBridgeApp(),
    ),
  );
}

