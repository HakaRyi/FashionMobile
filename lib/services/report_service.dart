// lib/services/report_service.dart
import 'dart:convert';

import '../constants/api_constants.dart';
import '../core/api_exception.dart';
import '../models/report_models.dart';
import '../models/report_type_model.dart';
import 'api_client.dart';

class ReportService {
  Future<List<ReportTypeModel>> getReportTypes() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.reportTypes}');
    final response = await ApiClient.get(uri);

    if (response.statusCode != 200) {
      throw _buildApiException(
        response.statusCode,
        response.body,
        fallbackMessage: 'Không tải được danh sách loại báo cáo.',
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw ApiException(
        'Phản hồi danh sách loại báo cáo không hợp lệ.',
        statusCode: response.statusCode,
      );
    }

    final data = decoded is Map<String, dynamic> ? decoded['data'] : null;

    if (data is List) {
      return data
          .map((e) => ReportTypeModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return const <ReportTypeModel>[];
  }

  Future<CreateReportResponse> reportPost({
    required int postId,
    required CreateReportRequest request,
  }) async {
    final endpoint =
    ApiConstants.reportPost.replaceFirst('{postId}', '$postId');
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');

    final response = await ApiClient.post(
      uri,
      body: request.toJson(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _buildApiException(
        response.statusCode,
        response.body,
        fallbackMessage: 'Gửi báo cáo thất bại.',
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw ApiException(
        'Phản hồi báo cáo không hợp lệ.',
        statusCode: response.statusCode,
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw ApiException(
        'Phản hồi báo cáo không hợp lệ.',
        statusCode: response.statusCode,
      );
    }

    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw ApiException(
        decoded['message']?.toString() ?? 'Phản hồi báo cáo không hợp lệ.',
        statusCode: response.statusCode,
      );
    }

    return CreateReportResponse.fromJson({
      ...Map<String, dynamic>.from(data),
      'message': decoded['message'],
    });
  }

  ApiException _buildApiException(
      int statusCode,
      String responseBody, {
        required String fallbackMessage,
      }) {
    String message = fallbackMessage;

    try {
      final decoded = jsonDecode(responseBody);

      if (decoded is Map<String, dynamic>) {
        final apiMessage = decoded['message']?.toString().trim();
        if (apiMessage != null && apiMessage.isNotEmpty) {
          message = apiMessage;
        }
      }
    } catch (_) {}

    message = _mapFriendlyMessage(statusCode, message);

    return ApiException(message, statusCode: statusCode);
  }

  String _mapFriendlyMessage(int statusCode, String message) {
    final normalized = message.trim();

    if (normalized.isEmpty) {
      switch (statusCode) {
        case 400:
          return 'Dữ liệu báo cáo chưa hợp lệ.';
        case 401:
          return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
        case 403:
          return 'Bạn không có quyền thực hiện thao tác này.';
        case 404:
          return 'Không tìm thấy dữ liệu yêu cầu.';
        case 500:
          return 'Hệ thống đang bận, vui lòng thử lại sau.';
        default:
          return 'Có lỗi xảy ra, vui lòng thử lại.';
      }
    }

    if (statusCode == 401) {
      return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
    }

    if (statusCode == 403) {
      return 'Bạn không có quyền thực hiện thao tác này.';
    }

    if (statusCode >= 500) {
      return 'Hệ thống đang bận, vui lòng thử lại sau.';
    }

    return normalized;
  }
}