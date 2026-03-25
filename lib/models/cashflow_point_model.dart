class CashflowPointModel {
  final String period;
  final double income;
  final double expense;
  final double netAmount;

  CashflowPointModel({
    required this.period,
    required this.income,
    required this.expense,
    required this.netAmount,
  });

  factory CashflowPointModel.fromJson(Map<String, dynamic> json) {
    return CashflowPointModel(
      period: json['period'] ?? '',
      income: (json['income'] ?? 0).toDouble(),
      expense: (json['expense'] ?? 0).toDouble(),
      netAmount: (json['netAmount'] ?? 0).toDouble(),
    );
  }
}