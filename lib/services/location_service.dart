import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class LocationService {
  final String _apiKey = dotenv.env['GOONG_API_KEY'] ?? '';

  Future<List<String>> searchAddress(String query) async {
    if (query.isEmpty) return [];
    final url = Uri.parse('https://rsapi.goong.io/Place/AutoComplete?api_key=$_apiKey&input=$query');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final predictions = data['predictions'] as List;
        return predictions.map((p) => p['description'].toString()).toList();
      }
      return [];
    } catch (e) {
      print("Lỗi tìm địa chỉ: $e");
      return [];
    }
  }
}