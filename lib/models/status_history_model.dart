class StatusHistoryModel {
  final int id;
  final String status;
  final DateTime changedAt;
  final String actorType;
  final int? changedById;
  final String? note;

  StatusHistoryModel({
    required this.id,
    required this.status,
    required this.changedAt,
    required this.actorType,
    this.changedById,
    this.note,
  });

  factory StatusHistoryModel.fromJson(Map<String, dynamic> json) {
    return StatusHistoryModel(
      id: json['id'] as int? ?? 0,
      status: json['status']?.toString() ?? '',
      changedAt: DateTime.tryParse(json['changedAt']?.toString() ?? '') ?? DateTime.now(),
      actorType: json['actorType']?.toString() ?? '',
      changedById: json['changedById'] as int?,
      note: json['note']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'status': status,
    'changedAt': changedAt.toIso8601String(),
    'actorType': actorType,
    'changedById': changedById,
    'note': note,
  };
}