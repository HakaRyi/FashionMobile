// lib/services/try_on_history_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../core/api_exception.dart';
import '../models/try_on_history_model.dart';
import 'api_client.dart';

class TryOnHistoryService {
  Future<List<TryOnHistoryModel>> getMyHistory() async {
    final url = Uri.parse(
      "${ApiConstants.baseUrl}${ApiConstants.tryOnHistoryEndpoint}",
    );

    try {
      final http.Response response = await ApiClient.get(url);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> data = body["data"] ?? [];

        return data
            .map((e) => TryOnHistoryModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      String message = "Không lấy được lịch sử thử đồ.";
      try {
        final body = jsonDecode(response.body);
        message = (body["message"] ?? message).toString();
      } catch (_) {}

      throw ApiException(message, statusCode: response.statusCode);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException("Lỗi tải lịch sử thử đồ: $e");
    }
  }

  Future<void> deleteHistory(int id) async {
    final url = Uri.parse(
      "${ApiConstants.baseUrl}${ApiConstants.tryOnHistoryDeleteEndpoint}/$id",
    );

    try {
      final http.Response response = await ApiClient.delete(url);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      }

      String message = "Không thể xóa lịch sử thử đồ.";
      try {
        final body = jsonDecode(response.body);
        message = (body["message"] ?? message).toString();
      } catch (_) {}

      throw ApiException(message, statusCode: response.statusCode);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException("Lỗi xóa lịch sử thử đồ: $e");
    }
  }
}