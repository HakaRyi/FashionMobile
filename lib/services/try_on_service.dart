import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import '../constants/api_constants.dart';
import '../services/try_on_history_service.dart';
import '../utils/try_on_manager.dart';

final TryOnManager tryOnManager = TryOnManager();

class TryOnService {
  Future<Uint8List?> processTryOn(String modelAssetPath, String clothImagePath) async {
    final url = Uri.parse("${ApiConstants.baseUrl}${ApiConstants.tryOnEndpoint}");

    try {
      var request = http.MultipartRequest('POST', url);

      final modelByteData = await rootBundle.load(modelAssetPath);

      request.files.add(http.MultipartFile.fromBytes(
        'model_image',
        modelByteData.buffer.asUint8List(),
        filename: 'model.jpg',
      ));

      request.files.add(await http.MultipartFile.fromPath(
        'cloth_image',
        clothImagePath,
      ));

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