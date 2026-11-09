import 'package:flutter/foundation.dart';
import '../models/donation_model.dart';
import '../services/database_service.dart';

/// Provider handling donation state management, filtering, searching,
/// and inventory synchronization.
class DonationProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService.instance;

  List<DonationModel> _donations = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _selectedCategory;
  DateTime? _filterDate;

  List<DonationModel> get donations => _donations;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  DateTime? get filterDate => _filterDate;

  /// Returns filtered and searched donations
  List<DonationModel> get filteredDonations {
    return _donations.where((d) {
      final matchesSearch = _searchQuery.isEmpty ||
          d.donorName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          d.foodItemName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          d.phoneNumber.contains(_searchQuery);

      final matchesCategory =
          _selectedCategory == null || _selectedCategory == 'All' || d.category == _selectedCategory;

      final matchesDate = _filterDate == null ||
          (d.donationDate.year == _filterDate!.year &&
              d.donationDate.month == _filterDate!.month &&
              d.donationDate.day == _filterDate!.day);

      return matchesSearch && matchesCategory && matchesDate;
    }).toList();
  }

  Future<void> loadDonations() async {
    _isLoading = true;
    notifyListeners();

    try {
      _donations = await _dbService.getAllDonations();
    } catch (e) {
      debugPrint('Error loading donations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addDonation(DonationModel donation) async {
    await _dbService.recordDonationWithInventorySync(donation);
    await loadDonations();
  }

  Future<void> updateDonation(DonationModel updated, DonationModel old) async {
    await _dbService.updateDonationWithInventorySync(updated, old);
    await loadDonations();
  }

  Future<void> deleteDonation(DonationModel donation) async {
    await _dbService.deleteDonationWithInventorySync(donation);
    await loadDonations();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setDateFilter(DateTime? date) {
    _filterDate = date;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _filterDate = null;
    notifyListeners();
  }
}

