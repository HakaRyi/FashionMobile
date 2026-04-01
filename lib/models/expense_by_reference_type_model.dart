class ExpenseByReferenceTypeModel {
  final String referenceType;
  final double amount;
  final int transactionCount;

  ExpenseByReferenceTypeModel({
    required this.referenceType,
    required this.amount,
    required this.transactionCount,
  });

  factory ExpenseByReferenceTypeModel.fromJson(Map<String, dynamic> json) {
    return ExpenseByReferenceTypeModel(
      referenceType: json['referenceType'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      transactionCount: json['transactionCount'] ?? 0,
    );
  }
}