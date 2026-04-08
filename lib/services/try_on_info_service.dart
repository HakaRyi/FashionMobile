// lib/services/try_on_info_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../core/api_exception.dart';
import 'api_client.dart';

class TryOnInfoService {
  Future<Map<String, dynamic>> getInfo() async {
    final url = Uri.parse("${ApiConstants.baseUrl}${ApiConstants.tryOnInfoEndpoint}");

    try {
      final http.Response response = await ApiClient.get(url);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body["data"] as Map<String, dynamic>;
      }

      String message = "Không lấy được thông tin thử đồ.";
      try {
        final body = jsonDecode(response.body);
        message = (body["message"] ?? message).toString();
      } catch (_) {}

      throw ApiException(message, statusCode: response.statusCode);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException("Lỗi tải thông tin thử đồ: $e");
    }
  }
}