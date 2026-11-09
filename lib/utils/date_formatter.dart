import 'package:intl/intl.dart';

/// Utilities for standard date and numerical display throughout FoodBridge.
class DateFormatter {
  static final DateFormat _displayDateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _displayDateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _isoDateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _monthYearFormat = DateFormat('MMM yyyy');

  /// Formats DateTime to readable string e.g. "12 Oct 2026"
  static String format(DateTime? date) {
    if (date == null) return 'N/A';
    return _displayDateFormat.format(date);
  }

  /// Formats DateTime to readable string with time e.g. "12 Oct 2026, 03:30 PM"
  static String formatWithTime(DateTime? date) {
    if (date == null) return 'N/A';
    return _displayDateTimeFormat.format(date);
  }

  /// Formats DateTime to ISO-8601 string e.g. "2026-10-12"
  static String toIso(DateTime date) {
    return _isoDateFormat.format(date);
  }

  /// Parses ISO date or returns null on failure
  static DateTime? parseIso(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  /// Formats month and year e.g. "Oct 2026"
  static String formatMonthYear(DateTime date) {
    return _monthYearFormat.format(date);
  }

  /// Formats decimal quantity cleanly e.g. 150 or 45.5
  static String formatQuantity(double quantity) {
    if (quantity == quantity.roundToDouble()) {
      return quantity.toInt().toString();
    }
    return quantity.toStringAsFixed(1);
  }

  /// Calculates days remaining until target date (negative if past)
  static int daysRemaining(DateTime targetDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(targetDate.year, targetDate.month, targetDate.day);
    return target.difference(today).inDays;
  }
}

