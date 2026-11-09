import '../utils/app_constants.dart';

/// Stock status classification
enum StockStatus {
  expired,
  outOfStock,
  lowStock,
  sufficient,
}

/// Represents an item in the FoodBridge food inventory.
class InventoryModel {
  final String id;
  final String foodName;
  final String category;
  final double availableQuantity;
  final String unit;
  final DateTime expiryDate;
  final double lowStockThreshold;
  final DateTime lastUpdated;

  InventoryModel({
    required this.id,
    required this.foodName,
    required this.category,
    required this.availableQuantity,
    required this.unit,
    required this.expiryDate,
    this.lowStockThreshold = AppConstants.lowStockThreshold,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  /// Days remaining until expiry (negative if already expired)
  int get daysUntilExpiry {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiry.difference(today).inDays;
  }

  bool get isExpired => daysUntilExpiry < 0;

  bool get isExpiringSoon => daysUntilExpiry >= 0 && daysUntilExpiry <= AppConstants.expiringSoonDays;

  bool get isExpiringWithinMonth =>
      daysUntilExpiry > AppConstants.expiringSoonDays &&
      daysUntilExpiry <= AppConstants.expiringWithinMonthDays;

  bool get isFresh => daysUntilExpiry > AppConstants.expiringWithinMonthDays;

  bool get isOutOfStock => availableQuantity <= 0;

  bool get isLowStock => !isOutOfStock && availableQuantity <= lowStockThreshold;

  StockStatus get status {
    if (isExpired) return StockStatus.expired;
    if (isOutOfStock) return StockStatus.outOfStock;
    if (isLowStock) return StockStatus.lowStock;
    return StockStatus.sufficient;
  }

  String get statusLabel {
    switch (status) {
      case StockStatus.expired:
        return 'Expired';
      case StockStatus.outOfStock:
        return 'Out of Stock';
      case StockStatus.lowStock:
        return 'Low Stock';
      case StockStatus.sufficient:
        return 'Sufficient';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'food_name': foodName,
      'category': category,
      'available_quantity': availableQuantity,
      'unit': unit,
      'expiry_date': expiryDate.toIso8601String(),
      'low_stock_threshold': lowStockThreshold,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  factory InventoryModel.fromMap(Map<String, dynamic> map) {
    return InventoryModel(
      id: map['id'] as String,
      foodName: map['food_name'] as String,
      category: map['category'] as String,
      availableQuantity: (map['available_quantity'] as num).toDouble(),
      unit: map['unit'] as String,
      expiryDate: DateTime.parse(map['expiry_date'] as String),
      lowStockThreshold: (map['low_stock_threshold'] as num?)?.toDouble() ??
          AppConstants.lowStockThreshold,
      lastUpdated: map['last_updated'] != null
          ? DateTime.parse(map['last_updated'] as String)
          : DateTime.now(),
    );
  }

  InventoryModel copyWith({
    String? id,
    String? foodName,
    String? category,
    double? availableQuantity,
    String? unit,
    DateTime? expiryDate,
    double? lowStockThreshold,
    DateTime? lastUpdated,
  }) {
    return InventoryModel(
      id: id ?? this.id,
      foodName: foodName ?? this.foodName,
      category: category ?? this.category,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      unit: unit ?? this.unit,
      expiryDate: expiryDate ?? this.expiryDate,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

