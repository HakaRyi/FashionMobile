// lib/managers/report_manager.dart
import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../models/report_models.dart';
import '../models/report_type_model.dart';
import '../services/report_service.dart';

class ReportManager extends ChangeNotifier {
  ReportManager({ReportService? service}) : _service = service ?? ReportService();

  final ReportService _service;

  List<ReportTypeModel> _reportTypes = const [];
  bool _isLoadingTypes = false;
  bool _isSubmitting = false;

  List<ReportTypeModel> get reportTypes => _reportTypes;
  bool get isLoadingTypes => _isLoadingTypes;
  bool get isSubmitting => _isSubmitting;

  Future<List<ReportTypeModel>> loadReportTypes({
    bool forceRefresh = false,
  }) async {
    if (_reportTypes.isNotEmpty && !forceRefresh) {
      return _reportTypes;
    }

    if (_isLoadingTypes) {
      return _reportTypes;
    }

    _isLoadingTypes = true;
    notifyListeners();

    try {
      final items = await _service.getReportTypes();
      _reportTypes = items;
      return _reportTypes;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Không tải được danh sách loại báo cáo.');
    } finally {
      _isLoadingTypes = false;
      notifyListeners();
    }
  }

  Future<CreateReportResponse> submitReport({
    required int postId,
    required int reportTypeId,
    String? reason,
  }) async {
    if (_isSubmitting) {
      throw ApiException('Yêu cầu đang được xử lý, vui lòng chờ.');
    }

    if (postId <= 0) {
      throw ApiException('Bài viết không hợp lệ.');
    }

    if (reportTypeId <= 0) {
      throw ApiException('Vui lòng chọn loại báo cáo.');
    }

    final trimmedReason = reason?.trim();

    if (trimmedReason != null && trimmedReason.length > 1000) {
      throw ApiException('Lý do không được vượt quá 1000 ký tự.');
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      return await _service.reportPost(
        postId: postId,
        request: CreateReportRequest(
          reportTypeId: reportTypeId,
          reason: (trimmedReason == null || trimmedReason.isEmpty)
              ? null
              : trimmedReason,
        ),
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Không thể gửi báo cáo lúc này. Vui lòng thử lại.');
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}

final reportManager = ReportManager();