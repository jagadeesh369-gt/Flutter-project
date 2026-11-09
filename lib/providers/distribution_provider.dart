import 'package:flutter/foundation.dart';
import '../models/distribution_model.dart';
import '../services/database_service.dart';

/// Provider handling food distributions to beneficiaries, validating stock levels,
/// and executing atomic inventory deductions.
class DistributionProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService.instance;

  List<DistributionModel> _distributions = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<DistributionModel> get distributions => _distributions;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  List<DistributionModel> get filteredDistributions {
    if (_searchQuery.isEmpty) return _distributions;
    final q = _searchQuery.toLowerCase();
    return _distributions.where((d) {
      return d.recipientName.toLowerCase().contains(q) ||
          d.foodItemName.toLowerCase().contains(q) ||
          d.phoneNumber.contains(q) ||
          d.purpose.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> loadDistributions() async {
    _isLoading = true;
    notifyListeners();

    try {
      _distributions = await _dbService.getAllDistributions();
    } catch (e) {
      debugPrint('Error loading distributions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Validates stock sufficiency and item eligibility before distribution
  Future<String?> validateStock(String foodItemId, double requestedQuantity) async {
    final item = await _dbService.getInventoryItemById(foodItemId);
    if (item == null) {
      return 'The chosen food item is not found in the inventory.';
    }
    if (item.isExpired) {
      return 'Safety Alert: "${item.foodName}" has expired on ${item.expiryDate.toString().split(' ')[0]} and cannot be distributed.';
    }
    if (item.availableQuantity < requestedQuantity) {
      return 'Insufficient stock for "${item.foodName}". Available: ${item.availableQuantity} ${item.unit}, requested: $requestedQuantity ${item.unit}.';
    }
    return null; // Valid
  }

  Future<void> addDistribution(DistributionModel distribution) async {
    await _dbService.recordDistributionTransaction(distribution);
    await loadDistributions();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
}

