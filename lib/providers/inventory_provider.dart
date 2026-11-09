import 'package:flutter/foundation.dart';
import '../models/inventory_model.dart';
import '../services/database_service.dart';

/// Provider handling inventory state, stock categorization, sorting, and expiry calculations.
class InventoryProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService.instance;

  List<InventoryModel> _items = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _selectedCategory;
  String _sortBy = 'name_asc'; // 'name_asc', 'qty_desc', 'qty_asc', 'exp_asc', 'exp_desc'

  List<InventoryModel> get items => _items;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  String get sortBy => _sortBy;

  /// Returns filtered and sorted inventory items
  List<InventoryModel> get filteredItems {
    final list = _items.where((item) {
      final matchesSearch = _searchQuery.isEmpty ||
          item.foodName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.category.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory =
          _selectedCategory == null || _selectedCategory == 'All' || item.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();

    switch (_sortBy) {
      case 'qty_desc':
        list.sort((a, b) => b.availableQuantity.compareTo(a.availableQuantity));
        break;
      case 'qty_asc':
        list.sort((a, b) => a.availableQuantity.compareTo(b.availableQuantity));
        break;
      case 'exp_asc':
        list.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
        break;
      case 'exp_desc':
        list.sort((a, b) => b.expiryDate.compareTo(a.expiryDate));
        break;
      case 'name_asc':
      default:
        list.sort((a, b) => a.foodName.toLowerCase().compareTo(b.foodName.toLowerCase()));
        break;
    }

    return list;
  }

  // Filtered queries for specific dashboard and expiry views
  List<InventoryModel> getLowStockItems() {
    return _items.where((i) => i.isLowStock || i.isOutOfStock).toList();
  }

  List<InventoryModel> getExpiringItems() {
    return _items.where((i) => i.isExpiringSoon).toList();
  }

  List<InventoryModel> getExpiredItems() {
    return _items.where((i) => i.isExpired).toList();
  }

  List<InventoryModel> getExpiringWithin30Days() {
    return _items.where((i) => i.isExpiringWithinMonth).toList();
  }

  List<InventoryModel> getFreshItems() {
    return _items.where((i) => i.isFresh).toList();
  }

  List<InventoryModel> getDistributableItems() {
    return _items.where((i) => !i.isExpired && i.availableQuantity > 0).toList();
  }

  Future<void> loadInventory() async {
    _isLoading = true;
    notifyListeners();

    try {
      _items = await _dbService.getAllInventory();
    } catch (e) {
      debugPrint('Error loading inventory: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addFoodItem(InventoryModel item) async {
    await _dbService.insertInventoryItem(item);
    await loadInventory();
  }

  Future<void> updateFoodItem(InventoryModel item) async {
    await _dbService.updateInventoryItem(item);
    await loadInventory();
  }

  Future<void> deleteFoodItem(String id) async {
    await _dbService.deleteInventoryItem(id);
    await loadInventory();
  }

  Future<void> updateStock(String id, double newQuantity) async {
    final item = await _dbService.getInventoryItemById(id);
    if (item != null) {
      final updated = item.copyWith(
        availableQuantity: newQuantity,
        lastUpdated: DateTime.now(),
      );
      await _dbService.updateInventoryItem(updated);
      await loadInventory();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSortBy(String sortOption) {
    _sortBy = sortOption;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _sortBy = 'name_asc';
    notifyListeners();
  }
}

