class ReportTypeModel {
  final int reportTypeId;
  final String typeName;
  final String? description;

  const ReportTypeModel({
    required this.reportTypeId,
    required this.typeName,
    this.description,
  });

  factory ReportTypeModel.fromJson(Map<String, dynamic> json) {
    return ReportTypeModel(
      reportTypeId: _toInt(json['reportTypeId']),
      typeName: (json['typeName'] ?? '').toString(),
      description: json['description']?.toString(),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}