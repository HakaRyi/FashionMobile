class SpendingLimitModel {
  final double? monthlySpendingLimit;
  final bool isHardSpendingLimit;
  final double spendingWarningThresholdPercent;
  final double spentThisMonth;
  final double remainingAmount;
  final double usedPercent;
  final bool isExceeded;
  final bool isWarning;
  final String currency;

  SpendingLimitModel({
    required this.monthlySpendingLimit,
    required this.isHardSpendingLimit,
    required this.spendingWarningThresholdPercent,
    required this.spentThisMonth,
    required this.remainingAmount,
    required this.usedPercent,
    required this.isExceeded,
    required this.isWarning,
    required this.currency,
  });

  factory SpendingLimitModel.fromJson(Map<String, dynamic> json) {
    return SpendingLimitModel(
      monthlySpendingLimit: (json['monthlySpendingLimit'] as num?)?.toDouble(),
      isHardSpendingLimit: json['isHardSpendingLimit'] ?? false,
      spendingWarningThresholdPercent:
      (json['spendingWarningThresholdPercent'] as num?)?.toDouble() ?? 0,
      spentThisMonth: (json['spentThisMonth'] as num?)?.toDouble() ?? 0,
      remainingAmount: (json['remainingAmount'] as num?)?.toDouble() ?? 0,
      usedPercent: (json['usedPercent'] as num?)?.toDouble() ?? 0,
      isExceeded: json['isExceeded'] ?? false,
      isWarning: json['isWarning'] ?? false,
      currency: json['currency'] ?? 'VND',
    );
  }
}