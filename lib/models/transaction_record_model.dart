enum TransactionType {
  donation,
  distribution,
}

/// A unified representation of either an incoming donation or an outgoing distribution.
class TransactionRecordModel {
  final String id;
  final TransactionType type;
  final String foodItem;
  final double quantity;
  final String unit;
  final DateTime date;
  final String partyName; // Donor or Recipient
  final String phoneNumber;
  final String details; // Condition for donation or Purpose for distribution
  final String category;

  TransactionRecordModel({
    required this.id,
    required this.type,
    required this.foodItem,
    required this.quantity,
    required this.unit,
    required this.date,
    required this.partyName,
    required this.phoneNumber,
    required this.details,
    this.category = 'Other',
  });

  bool get isDonation => type == TransactionType.donation;
  bool get isDistribution => type == TransactionType.distribution;

  String get typeLabel => isDonation ? 'Donation (In)' : 'Distribution (Out)';
}

