import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../core/api_exception.dart';

class TryOnService {
  Future<Uint8List?> processTryOn({
    String? modelAssetPath,
    String? modelImageUrl,
    required String clothImagePath,
    int? category,
  }) async {
    final url = Uri.parse(
      "${ApiConstants.baseUrl}${ApiConstants.tryOnEndpoint}",
    );

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final request = http.MultipartRequest('POST', url);

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'ngrok-skip-browser-warning': '69420',
      'Accept': 'application/json',
    });

    if (category != null) {
      request.fields['category'] = category.toString();
    }

    Uint8List? modelBytes;

    if (modelAssetPath != null && modelAssetPath.trim().isNotEmpty) {
      final modelByteData = await rootBundle.load(modelAssetPath);
      modelBytes = modelByteData.buffer.asUint8List();
    } else if (modelImageUrl != null && modelImageUrl.trim().isNotEmpty) {
      final modelResponse = await http.get(Uri.parse(modelImageUrl));

      if (modelResponse.statusCode == 200) {
        modelBytes = modelResponse.bodyBytes;
      } else {
        throw ApiException("Không thể tải ảnh model.");
      }
    }

    if (modelBytes == null) {
      throw ApiException("Thiếu ảnh model.");
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        'model_image',
        modelBytes,
        filename: 'model.jpg',
      ),
    );

    request.files.add(
      await http.MultipartFile.fromPath(
        'cloth_image',
        clothImagePath,
      ),
    );

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }

      String message = "Lỗi xử lý thử đồ.";

      try {
        final data = jsonDecode(response.body);

        if (data is Map<String, dynamic>) {
          final apiMessage = data['message']?.toString();
          if (apiMessage != null && apiMessage.trim().isNotEmpty) {
            message = apiMessage;
          }
        }
      } catch (_) {
        if (response.body.trim().isNotEmpty) {
          message = response.body;
        }
      }

      throw ApiException(
        message,
        statusCode: response.statusCode,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException("Lỗi xử lý thử đồ: $e");
    }
  }
}