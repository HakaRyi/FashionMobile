class ExpenseSummaryModel {
  final double totalIncome;
  final double totalExpense;
  final double netAmount;
  final int totalTransactions;
  final double currentBalance;
  final double currentLockedBalance;
  final String currency;

  ExpenseSummaryModel({
    required this.totalIncome,
    required this.totalExpense,
    required this.netAmount,
    required this.totalTransactions,
    required this.currentBalance,
    required this.currentLockedBalance,
    required this.currency,
  });

  factory ExpenseSummaryModel.fromJson(Map<String, dynamic> json) {
    return ExpenseSummaryModel(
      totalIncome: (json['totalIncome'] ?? 0).toDouble(),
      totalExpense: (json['totalExpense'] ?? 0).toDouble(),
      netAmount: (json['netAmount'] ?? 0).toDouble(),
      totalTransactions: json['totalTransactions'] ?? 0,
      currentBalance: (json['currentBalance'] ?? 0).toDouble(),
      currentLockedBalance: (json['currentLockedBalance'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'VND',
    );
  }
}