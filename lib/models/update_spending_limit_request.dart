class UpdateSpendingLimitRequest {
  final double? monthlySpendingLimit;
  final bool isHardSpendingLimit;
  final double spendingWarningThresholdPercent;

  UpdateSpendingLimitRequest({
    required this.monthlySpendingLimit,
    required this.isHardSpendingLimit,
    required this.spendingWarningThresholdPercent,
  });

  Map<String, dynamic> toJson() {
    return {
      'monthlySpendingLimit': monthlySpendingLimit,
      'isHardSpendingLimit': isHardSpendingLimit,
      'spendingWarningThresholdPercent': spendingWarningThresholdPercent,
    };
  }
}