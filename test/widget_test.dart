import 'package:flutter_test/flutter_test.dart';
import 'package:foodbridge/app.dart';
import 'package:foodbridge/providers/dashboard_provider.dart';
import 'package:foodbridge/providers/donation_provider.dart';
import 'package:foodbridge/providers/distribution_provider.dart';
import 'package:foodbridge/providers/inventory_provider.dart';
import 'package:foodbridge/providers/theme_provider.dart';
import 'package:foodbridge/services/preferences_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('FoodBridge App loads splash screen test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await PreferencesService.getInstance();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider(prefs)),
          ChangeNotifierProvider<DonationProvider>(create: (_) => DonationProvider()),
          ChangeNotifierProvider<InventoryProvider>(create: (_) => InventoryProvider()),
          ChangeNotifierProvider<DistributionProvider>(create: (_) => DistributionProvider()),
          ChangeNotifierProvider<DashboardProvider>(create: (_) => DashboardProvider()),
        ],
        child: const FoodBridgeApp(),
      ),
    );

    // Verify splash branding appears
    expect(find.text('FoodBridge'), findsWidgets);
  });
}

