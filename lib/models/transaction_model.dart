class TransactionModel {
  final int transactionId;
  final double amount;
  final String type;
  final String description;
  final DateTime createdAt;

  TransactionModel({
    required this.transactionId,
    required this.amount,
    required this.type,
    required this.description,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      transactionId: json['transactionId'] ?? 0,
      amount: (json['amount'] ?? 0).toDouble(),
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse('${json['createdAt']}Z').toLocal()
          : DateTime.now(),
    );
  }

  bool get isPositive => type == 'Credit';
}