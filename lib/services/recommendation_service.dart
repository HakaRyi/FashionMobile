import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../models/recommendation_history_model.dart';

class RecommendationService {
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Accept': '*/*',
      'Authorization': 'Bearer $token',
      'ngrok-skip-browser-warning': '69420',
    };
  }

  Future<List<RecommendationHistoryModel>> getMyHistory() async {
    final url = Uri.parse("${ApiConstants.baseUrl}/Recommendations/history");
    try {
      final response = await http.get(url, headers: await _getHeaders());
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> data = body['data'];
        return data.map((item) => RecommendationHistoryModel.fromJson(item)).toList();
      }
    } catch (e) {
      print("Lỗi getMyHistory: $e");
    }
    return [];
  }

  Future<List<dynamic>> getHistoryDetail(int historyId) async {
    final url = Uri.parse("${ApiConstants.baseUrl}/Recommendations/history/$historyId");
    try {
      final response = await http.get(url, headers: await _getHeaders());
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        return body['data'] ?? [];
      }
    } catch (e) {
      print("Lỗi getHistoryDetail: $e");
    }
    return [];
  }
}