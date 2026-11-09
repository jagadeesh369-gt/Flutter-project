/// Represents a food distribution transaction to a beneficiary or organization.
class DistributionModel {
  final String id;
  final String recipientName;
  final String phoneNumber;
  final String foodItemId;
  final String foodItemName;
  final double quantityDistributed;
  final String unit;
  final DateTime distributionDate;
  final String purpose;
  final DateTime createdAt;

  DistributionModel({
    required this.id,
    required this.recipientName,
    required this.phoneNumber,
    required this.foodItemId,
    required this.foodItemName,
    required this.quantityDistributed,
    required this.unit,
    required this.distributionDate,
    required this.purpose,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipient_name': recipientName,
      'phone_number': phoneNumber,
      'food_item_id': foodItemId,
      'food_item_name': foodItemName,
      'quantity_distributed': quantityDistributed,
      'unit': unit,
      'distribution_date': distributionDate.toIso8601String(),
      'purpose': purpose,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DistributionModel.fromMap(Map<String, dynamic> map) {
    return DistributionModel(
      id: map['id'] as String,
      recipientName: map['recipient_name'] as String,
      phoneNumber: map['phone_number'] as String? ?? '',
      foodItemId: map['food_item_id'] as String,
      foodItemName: map['food_item_name'] as String,
      quantityDistributed: (map['quantity_distributed'] as num).toDouble(),
      unit: map['unit'] as String,
      distributionDate: DateTime.parse(map['distribution_date'] as String),
      purpose: map['purpose'] as String? ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  DistributionModel copyWith({
    String? id,
    String? recipientName,
    String? phoneNumber,
    String? foodItemId,
    String? foodItemName,
    double? quantityDistributed,
    String? unit,
    DateTime? distributionDate,
    String? purpose,
    DateTime? createdAt,
  }) {
    return DistributionModel(
      id: id ?? this.id,
      recipientName: recipientName ?? this.recipientName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      foodItemId: foodItemId ?? this.foodItemId,
      foodItemName: foodItemName ?? this.foodItemName,
      quantityDistributed: quantityDistributed ?? this.quantityDistributed,
      unit: unit ?? this.unit,
      distributionDate: distributionDate ?? this.distributionDate,
      purpose: purpose ?? this.purpose,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

