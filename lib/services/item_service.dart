// lib/services/item_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../models/public_item_detail_model.dart';

class ItemService {
  Future<Map<String, String>> _buildHeaders({bool withAuth = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': '69420',
    };

    if (withAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Lấy danh sách đồ của tôi
  Future<List<dynamic>> getMyItems() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse("${ApiConstants.baseUrl}${ApiConstants.getAllMyItemEndpoint}");

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': '69420',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print("Lỗi getMyItems: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>?> getItemById(int id) async {
    final url = Uri.parse("${ApiConstants.baseUrl}/items/$id");

    try {
      final response = await http.get(
        url,
        headers: await _buildHeaders(withAuth: true),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print("Lỗi getItemById: $e");
    }
    return null;
  }

  Future<PublicItemDetailModel> getPublicItemDetail(int itemId) async {
    final url = Uri.parse("${ApiConstants.baseUrl}/items/public/$itemId");

    final response = await http.get(
      url,
      headers: await _buildHeaders(),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.body);

      if (body['data'] == null || body['data'] is! Map<String, dynamic>) {
        throw Exception('Dữ liệu chi tiết món đồ không hợp lệ.');
      }

      return PublicItemDetailModel.fromJson(
        body['data'] as Map<String, dynamic>,
      );
    }

    try {
      final Map<String, dynamic> body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Không thể tải chi tiết món đồ công khai.');
    } catch (_) {
      throw Exception('Không thể tải chi tiết món đồ công khai.');
    }
  }
}