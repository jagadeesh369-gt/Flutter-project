import 'package:shared_preferences/shared_preferences.dart';

/// Wraps SharedPreferences for persistent user preferences.
class PreferencesService {
  static const String _keyDarkMode = 'is_dark_mode';
  static const String _keyExpiryAlerts = 'expiry_alerts_enabled';
  static const String _keyLowStockAlerts = 'low_stock_alerts_enabled';
  static const String _keyFirstRun = 'is_first_run';

  static PreferencesService? _instance;
  static SharedPreferences? _prefs;

  PreferencesService._();

  static Future<PreferencesService> getInstance() async {
    if (_instance == null) {
      _instance = PreferencesService._();
      _prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  bool get isDarkMode => _prefs?.getBool(_keyDarkMode) ?? false;
  Future<bool> setDarkMode(bool value) async =>
      await _prefs?.setBool(_keyDarkMode, value) ?? false;

  bool get expiryAlertsEnabled => _prefs?.getBool(_keyExpiryAlerts) ?? true;
  Future<bool> setExpiryAlertsEnabled(bool value) async =>
      await _prefs?.setBool(_keyExpiryAlerts, value) ?? false;

  bool get lowStockAlertsEnabled => _prefs?.getBool(_keyLowStockAlerts) ?? true;
  Future<bool> setLowStockAlertsEnabled(bool value) async =>
      await _prefs?.setBool(_keyLowStockAlerts, value) ?? false;

  bool get isFirstRun => _prefs?.getBool(_keyFirstRun) ?? true;
  Future<bool> setFirstRunCompleted() async =>
      await _prefs?.setBool(_keyFirstRun, false) ?? false;
}

