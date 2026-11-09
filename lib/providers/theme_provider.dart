import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

/// Provider managing application theme mode (light/dark) with persistent storage.
class ThemeProvider extends ChangeNotifier {
  final PreferencesService _prefs;
  late bool _isDarkMode;

  ThemeProvider(this._prefs) {
    _isDarkMode = _prefs.isDarkMode;
  }

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> toggleTheme(bool value) async {
    _isDarkMode = value;
    await _prefs.setDarkMode(value);
    notifyListeners();
  }
}

