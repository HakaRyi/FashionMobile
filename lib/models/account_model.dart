class AccountModel {
  final int accountId;
  final String name;

  AccountModel({
    required this.accountId,
    required this.name,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      accountId: json['accountId'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}