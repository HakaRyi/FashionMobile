class OrderStatusHistoryModel {
  final int id;
  final String status;
  final DateTime changedAt;
  final String actorType; // "Buyer", "Seller", "Shipper", "System"
  final int? changedById;
  final String? note;

  OrderStatusHistoryModel({
    required this.id,
    required this.status,
    required this.changedAt,
    required this.actorType,
    this.changedById,
    this.note,
  });

  factory OrderStatusHistoryModel.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistoryModel(
      id: _parseInt(json['id']),
      status: json['status']?.toString() ?? '',
      changedAt: _parseDate(json['changedAt']) ?? DateTime.now(),
      actorType: json['actorType']?.toString() ?? 'System',
      changedById: json['changedById'] != null
          ? _parseInt(json['changedById'])
          : null,
      note: json['note']?.toString(),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }
}