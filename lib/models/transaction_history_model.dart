class TransactionHistoryModel {
  final int transactionId;
  final int walletId;
  final int? paymentId;
  final String transactionCode;
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final String type;
  final String referenceType;
  final int? referenceId;
  final String? description;
  final DateTime createdAt;
  final String status;

  TransactionHistoryModel({
    required this.transactionId,
    required this.walletId,
    required this.paymentId,
    required this.transactionCode,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.type,
    required this.referenceType,
    required this.referenceId,
    required this.description,
    required this.createdAt,
    required this.status,
  });

  factory TransactionHistoryModel.fromJson(Map<String, dynamic> json) {
    return TransactionHistoryModel(
      transactionId: json['transactionId'] ?? 0,
      walletId: json['walletId'] ?? 0,
      paymentId: json['paymentId'],
      transactionCode: json['transactionCode'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      balanceBefore: (json['balanceBefore'] ?? 0).toDouble(),
      balanceAfter: (json['balanceAfter'] ?? 0).toDouble(),
      type: json['type'] ?? '',
      referenceType: json['referenceType'] ?? '',
      referenceId: json['referenceId'],
      description: json['description'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? '',
    );
  }
}