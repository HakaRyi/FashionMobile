import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'api_client.dart';

class TryOnHistoryService {
  Future<bool> saveHistory(Uint8List imageBytes) async {
    final url = Uri.parse("${ApiConstants.baseUrl}/TryOnHistory/save");

    try {
      final headers = await ApiClient.getHeaders();

      var request = http.MultipartRequest('POST', url);
      request.headers.addAll(headers);

      request.files.add(http.MultipartFile.fromBytes(
        'Image',
        imageBytes,
        filename: 'try_on_result.jpg',
      ));

      final streamedResponse = await request.send();
      return streamedResponse.statusCode == 200 || streamedResponse.statusCode == 201;
    } catch (e) {
      print("Lỗi saveHistory: $e");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getMyHistory() async {
    final url = Uri.parse("${ApiConstants.baseUrl}/TryOnHistory/my-history");

    try {
      final response = await ApiClient.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final List<dynamic> data = jsonResponse['data'] ?? [];
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print("Lỗi getMyHistory: $e");
    }
    return [];
  }
}