// lib/services/try_on_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../core/api_exception.dart';
import 'api_client.dart';

class TryOnService {
  Future<Uint8List> processTryOn({
    String? modelAssetPath,
    String? modelImageUrl,
    required String clothImagePath,
  }) async {
    final url = Uri.parse("${ApiConstants.baseUrl}${ApiConstants.tryOnEndpoint}");

    try {
      final headers = await ApiClient.getHeaders();

      final request = http.MultipartRequest('POST', url);
      request.headers.addAll(headers);

      Uint8List? modelBytes;

      if (modelAssetPath != null && modelAssetPath.trim().isNotEmpty) {
        final modelByteData = await rootBundle.load(modelAssetPath);
        modelBytes = modelByteData.buffer.asUint8List();
      } else if (modelImageUrl != null && modelImageUrl.trim().isNotEmpty) {
        final modelResponse = await http.get(Uri.parse(modelImageUrl));
        if (modelResponse.statusCode == 200) {
          modelBytes = modelResponse.bodyBytes;
        } else {
          throw ApiException(
            "Không tải được ảnh model.",
            statusCode: modelResponse.statusCode,
          );
        }
      }

      if (modelBytes == null) {
        throw ApiException("Không tìm thấy ảnh model để thử đồ.");
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

      final response = await request.send();
      final responseData = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        return responseData.bodyBytes;
      }

      String message = "Có lỗi xảy ra khi thử đồ.";

      try {
        final decoded = jsonDecode(responseData.body);
        if (decoded is Map<String, dynamic>) {
          message = (decoded["message"] ?? decoded["error"] ?? message).toString();
        }
      } catch (_) {}

      throw ApiException(message, statusCode: response.statusCode);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException("Lỗi kết nối hoặc xử lý ảnh: $e");
    }
  }
}