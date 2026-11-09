import 'package:flutter/foundation.dart';
import '../models/donation_model.dart';
import '../models/inventory_model.dart';
import '../models/distribution_model.dart';
import '../services/database_service.dart';

class MonthlyMetric {
  final String monthLabel;
  final double donationQuantity;
  final double distributionQuantity;

  MonthlyMetric({
    required this.monthLabel,
    required this.donationQuantity,
    required this.distributionQuantity,
  });
}

class CategoryMetric {
  final String category;
  final double totalQuantity;
  final int itemCount;

  CategoryMetric({
    required this.category,
    required this.totalQuantity,
    required this.itemCount,
  });
}

/// Provider orchestrating real-time summary calculations, charts, and activity feeds.
class DashboardProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService.instance;

  bool _isLoading = false;
  int _totalFoodItems = 0;
  double _totalAvailableStock = 0.0;
  int _totalDonationsCount = 0;
  double _totalDonationsQuantity = 0.0;
  int _totalDistributionsCount = 0;
  double _totalFoodDistributedQuantity = 0.0;
  int _expiringSoonCount = 0;
  int _lowStockCount = 0;
  int _expiredCount = 0;

  List<DonationModel> _recentDonations = [];
  List<DistributionModel> _recentDistributions = [];
  List<MonthlyMetric> _monthlyMetrics = [];
  List<CategoryMetric> _categoryMetrics = [];

  bool get isLoading => _isLoading;
  int get totalFoodItems => _totalFoodItems;
  double get totalAvailableStock => _totalAvailableStock;
  int get totalDonationsCount => _totalDonationsCount;
  double get totalDonationsQuantity => _totalDonationsQuantity;
  int get totalDistributionsCount => _totalDistributionsCount;
  double get totalFoodDistributedQuantity => _totalFoodDistributedQuantity;
  int get expiringSoonCount => _expiringSoonCount;
  int get lowStockCount => _lowStockCount;
  int get expiredCount => _expiredCount;

  List<DonationModel> get recentDonations => _recentDonations;
  List<DistributionModel> get recentDistributions => _recentDistributions;
  List<MonthlyMetric> get monthlyMetrics => _monthlyMetrics;
  List<CategoryMetric> get categoryMetrics => _categoryMetrics;

  Future<void> refreshDashboard() async {
    _isLoading = true;
    notifyListeners();

    try {
      final inventory = await _dbService.getAllInventory();
      final donations = await _dbService.getAllDonations();
      final distributions = await _dbService.getAllDistributions();

      // 1. Calculate Summary Cards
      _totalFoodItems = inventory.length;

      _totalAvailableStock = inventory.fold<double>(
        0.0,
        (sum, item) => sum + item.availableQuantity,
      );

      _totalDonationsCount = donations.length;
      _totalDonationsQuantity = donations.fold<double>(
        0.0,
        (sum, don) => sum + don.quantity,
      );

      _totalDistributionsCount = distributions.length;
      _totalFoodDistributedQuantity = distributions.fold<double>(
        0.0,
        (sum, dist) => sum + dist.quantityDistributed,
      );

      _expiringSoonCount = inventory.where((i) => i.isExpiringSoon).length;
      _lowStockCount = inventory.where((i) => i.isLowStock || i.isOutOfStock).length;
      _expiredCount = inventory.where((i) => i.isExpired).length;

      // 2. Recent Activities (limit 5)
      _recentDonations = donations.take(5).toList();
      _recentDistributions = distributions.take(5).toList();

      // 3. Category Metrics for Inventory Breakdown
      final Map<String, CategoryMetric> catMap = {};
      for (final item in inventory) {
        if (!catMap.containsKey(item.category)) {
          catMap[item.category] = CategoryMetric(
            category: item.category,
            totalQuantity: item.availableQuantity,
            itemCount: 1,
          );
        } else {
          final existing = catMap[item.category]!;
          catMap[item.category] = CategoryMetric(
            category: item.category,
            totalQuantity: existing.totalQuantity + item.availableQuantity,
            itemCount: existing.itemCount + 1,
          );
        }
      }
      _categoryMetrics = catMap.values.toList();
      _categoryMetrics.sort((a, b) => b.totalQuantity.compareTo(a.totalQuantity));

      // 4. Monthly Metrics for past 6 months
      final now = DateTime.now();
      final List<MonthlyMetric> mMetrics = [];
      const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

      for (int i = 5; i >= 0; i--) {
        final targetMonthDate = DateTime(now.year, now.month - i, 1);
        final m = targetMonthDate.month;
        final y = targetMonthDate.year;
        final label = '${monthNames[m - 1]} ${y.toString().substring(2)}';

        final donSum = donations
            .where((d) => d.donationDate.year == y && d.donationDate.month == m)
            .fold<double>(0.0, (sum, d) => sum + d.quantity);

        final distSum = distributions
            .where((dist) => dist.distributionDate.year == y && dist.distributionDate.month == m)
            .fold<double>(0.0, (sum, dist) => sum + dist.quantityDistributed);

        mMetrics.add(MonthlyMetric(
          monthLabel: label,
          donationQuantity: donSum,
          distributionQuantity: distSum,
        ));
      }
      _monthlyMetrics = mMetrics;
    } catch (e) {
      debugPrint('Error updating dashboard metrics: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

