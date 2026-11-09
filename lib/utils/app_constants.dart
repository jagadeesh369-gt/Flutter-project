/// Constants, enumerations, and metadata used across FoodBridge.
class AppConstants {
  static const String appName = 'FoodBridge';
  static const String appTagline = 'Rescue Food. Reduce Waste. Feed Lives.';
  static const String appVersion = '1.0.0';

  // Categories matching specifications
  static const List<String> foodCategories = [
    'Rice and Grains',
    'Vegetables',
    'Fruits',
    'Dairy Products',
    'Packaged Food',
    'Pulses',
    'Other',
  ];

  // Measurement Units
  static const List<String> measurementUnits = [
    'kg',
    'litres',
    'packets',
    'pieces',
  ];

  // Food Conditions for Donations
  static const List<String> foodConditions = [
    'Fresh',
    'Good',
    'Needs Attention',
  ];

  // Stock Thresholds
  static const double lowStockThreshold = 20.0;
  static const int expiringSoonDays = 7;
  static const int expiringWithinMonthDays = 30;

  // SDG Justifications
  static const String sdgGoal2Title = 'SDG 2: Zero Hunger';
  static const String sdgGoal2Description =
      'FoodBridge supports SDG 2 (Zero Hunger) by improving food donation '
      'management and ensuring food reaches people in need. It also reduces '
      'food wastage through inventory monitoring, expiry tracking, and efficient food distribution.';

  static const String sdgGoal12Title = 'SDG 12: Responsible Consumption and Production';
  static const String sdgGoal12Description =
      'FoodBridge directly contributes to target 12.3: halving per capita global food '
      'waste at the retail and consumer levels and reducing food losses along '
      'production and supply chains through proactive expiry tracking and prompt food redistribution.';
}

