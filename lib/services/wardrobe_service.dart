// lib/services/wardrobe_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../models/wardrobe_item_model.dart';

class WardrobeService {
  Future<Map<String, String>> _buildHeaders({bool withAuth = false}) async {
    final headers = <String, String>{
      "Content-Type": "application/json",
      "ngrok-skip-browser-warning": "69420",
    };

    if (withAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isNotEmpty) {
        headers["Authorization"] = "Bearer $token";
      }
    }

    return headers;
  }

  Future<List<WardrobeItemModel>> getMyWardrobeItems() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/wardrobes/me/items'),
      headers: await _buildHeaders(withAuth: true),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      final List<dynamic> data = body['data'] ?? [];
      return data.map((json) => WardrobeItemModel.fromJson(json)).toList();
    } else {
      throw Exception('Lỗi tải danh sách tủ đồ của tôi');
    }
  }

  Future<Map<String, dynamic>> getPublicProfile(int accountId) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/wardrobes/public/$accountId/profile'),
      headers: await _buildHeaders(),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      return body['data'] as Map<String, dynamic>;
    } else {
      throw Exception('Lỗi tải thông tin trang cá nhân');
    }
  }

  Future<List<WardrobeItemModel>> getPublicWardrobeItems(
      int accountId, {
        int page = 1,
        int pageSize = 12,
      }) async {
    final response = await http.get(
      Uri.parse(
        '${ApiConstants.baseUrl}/wardrobes/public/$accountId/items?page=$page&pageSize=$pageSize',
      ),
      headers: await _buildHeaders(withAuth: true),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      print("DEBUG: Response Body Keys: ${body.keys.toList()}");
      try{
        final Map<String, dynamic> data = body['data'] ?? {};
        print("DEBUG: Data Keys: ${data.keys.toList()}");
        final Map<String, dynamic> itemsWrapper = data['items'] ?? {};
        print("DEBUG: ItemsWrapper Keys: ${itemsWrapper.keys.toList()}");
        final List<dynamic> items = itemsWrapper['items'] ?? [];
        print("DEBUG: Danh sách items có ${items.length} phần tử.");
        if (items.isNotEmpty) {
          print("DEBUG: Thử parse phần tử đầu tiên: ${items[0]}");
        }
        return items.map((json) => WardrobeItemModel.fromJson(json)).toList();
      }catch(e, stacktrace){
        print("❌ LỖI PARSE JSON: $e");
        print("Stacktrace: $stacktrace");
        throw Exception('Lỗi xử lý dữ liệu từ server: $e');
      }
    } else {
      print("❌ LỖI SERVER: ${response.statusCode} - ${response.body}");
      throw Exception('Lỗi tải danh sách tủ đồ công khai');
    }
  }

  Future<int> getPublicWardrobeCount(int accountId) async {
    final response = await http.get(
      Uri.parse(
        '${ApiConstants.baseUrl}/wardrobes/public/$accountId/items?page=1&pageSize=1',
      ),
      headers: await _buildHeaders(),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      final Map<String, dynamic> data = body['data'] ?? {};
      return data['totalPublicItems'] ?? 0;
    } else {
      throw Exception('Lỗi tải số lượng món đồ công khai');
    }
  }
  Future<List<dynamic>> searchWardrobeByUsername(String username) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.searchWardrobeByUsernameEndpoint}?username=$username'),
      headers: await _buildHeaders(),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      return body['data'] ?? [];
    }
    return [];
  }
}