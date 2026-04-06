class CreateReportRequest {
  final int reportTypeId;
  final String? reason;

  const CreateReportRequest({
    required this.reportTypeId,
    this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'reportTypeId': reportTypeId,
      'reason': reason,
    };
  }
}

class CreateReportResponse {
  final int userReportId;
  final int postId;
  final int accountId;
  final int reportTypeId;
  final String reportTypeName;
  final String? reason;
  final String status;
  final DateTime? createdAt;
  final String message;

  const CreateReportResponse({
    required this.userReportId,
    required this.postId,
    required this.accountId,
    required this.reportTypeId,
    required this.reportTypeName,
    required this.reason,
    required this.status,
    required this.createdAt,
    required this.message,
  });

  factory CreateReportResponse.fromJson(Map<String, dynamic> json) {
    return CreateReportResponse(
      userReportId: _toInt(json['userReportId']),
      postId: _toInt(json['postId']),
      accountId: _toInt(json['accountId']),
      reportTypeId: _toInt(json['reportTypeId']),
      reportTypeName: (json['reportTypeName'] ?? '').toString(),
      reason: json['reason']?.toString(),
      status: (json['status'] ?? '').toString(),
      createdAt: _parseDate(json['createdAt']),
      message: (json['message'] ?? '').toString(),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

class ApiEnvelope<T> {
  final String message;
  final T data;

  const ApiEnvelope({
    required this.message,
    required this.data,
  });
}