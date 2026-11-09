/// Represents a donation record registered by a donor in FoodBridge.
class DonationModel {
  final String id;
  final String donorName;
  final String phoneNumber;
  final String foodItemName;
  final String category;
  final double quantity;
  final String unit;
  final DateTime donationDate;
  final DateTime expiryDate;
  final String condition;
  final String description;
  final DateTime createdAt;

  DonationModel({
    required this.id,
    required this.donorName,
    required this.phoneNumber,
    required this.foodItemName,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.donationDate,
    required this.expiryDate,
    required this.condition,
    this.description = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'donor_name': donorName,
      'phone_number': phoneNumber,
      'food_item_name': foodItemName,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'donation_date': donationDate.toIso8601String(),
      'expiry_date': expiryDate.toIso8601String(),
      'condition': condition,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DonationModel.fromMap(Map<String, dynamic> map) {
    return DonationModel(
      id: map['id'] as String,
      donorName: map['donor_name'] as String,
      phoneNumber: map['phone_number'] as String? ?? '',
      foodItemName: map['food_item_name'] as String,
      category: map['category'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String,
      donationDate: DateTime.parse(map['donation_date'] as String),
      expiryDate: DateTime.parse(map['expiry_date'] as String),
      condition: map['condition'] as String? ?? 'Good',
      description: map['description'] as String? ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  DonationModel copyWith({
    String? id,
    String? donorName,
    String? phoneNumber,
    String? foodItemName,
    String? category,
    double? quantity,
    String? unit,
    DateTime? donationDate,
    DateTime? expiryDate,
    String? condition,
    String? description,
    DateTime? createdAt,
  }) {
    return DonationModel(
      id: id ?? this.id,
      donorName: donorName ?? this.donorName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      foodItemName: foodItemName ?? this.foodItemName,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      donationDate: donationDate ?? this.donationDate,
      expiryDate: expiryDate ?? this.expiryDate,
      condition: condition ?? this.condition,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

