// lib/services/try_on_service.dart
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class TryOnService {
  Future<Uint8List?> processTryOn({
    String? modelAssetPath,
    String? modelImageUrl,
    required String clothImagePath,
    int? category
  }) async {
    final url = Uri.parse("${ApiConstants.baseUrl}${ApiConstants.tryOnEndpoint}");

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final request = http.MultipartRequest('POST', url);

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': '69420',
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
        }
      }

      if (modelBytes == null) {
        return null;
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
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}