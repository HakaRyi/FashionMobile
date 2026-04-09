import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../models/public_item_detail_model.dart';

class ItemService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
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
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = jsonDecode(response.body);
        return decodedData['data'] ?? [];
      }
      return [];
    } catch (e) {
      print("Lỗi getMyItems: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>?> getItemById(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse("${ApiConstants.baseUrl}/item/$id");

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
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

  Future<bool> deleteItem(int itemId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final endpoint = ApiConstants.deleteItemEndpoint.replaceFirst('{itemId}', itemId.toString());
    final url = Uri.parse("${ApiConstants.baseUrl}$endpoint");

    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Server báo: ${data['message']}");
        return true;
      }
      return false;
    } catch (e) {
      print("Lỗi deleteItem: $e");
      return false;
    }
  }
  Future<bool> updateItem(int itemId, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final endpoint = ApiConstants.updateItemEndpoint.replaceFirst('{itemId}', itemId.toString());
    final url = Uri.parse("${ApiConstants.baseUrl}$endpoint");

    try {
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Lỗi updateItem: $e");
      return false;
    }
  }
  Future<List<dynamic>> getSmartRecommendations({
    required int? referenceItemId,
    required String prompt,
    required bool useMyWardrobe,
    required bool useSavedItems,
    required List<int> targetWardrobeIds,
    int limit = 10,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse("${ApiConstants.baseUrl}${ApiConstants.smartMatchEndpoint}");

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': '69420',
        },
        body: jsonEncode({
          "prompt": prompt,
          "referenceItemId": referenceItemId,
          "targetWardrobeIds": targetWardrobeIds,
          "includeMyWardrobe": useMyWardrobe,
          "includeSavedItems": useSavedItems,
          "limit": limit,
        }),
      );

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        return decodedData['data'];
      }
    } catch (e) {
      print("Lỗi getSmartRecommendations: $e");
    }
    return [];
  }
  Future<int?> sendConsultRequest(int itemId) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/Chat/consult/$itemId"),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['groupId'];
    }
    return null;
  }
  Future<bool> saveItem(int itemId) async {
    final token = await _getToken();
    final url = Uri.parse("${ApiConstants.baseUrl}/items/$itemId/save");
    try {
      final response = await http.post(url, headers: {'Authorization': 'Bearer $token'});
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> unsaveItem(int itemId) async {
    final token = await _getToken();
    final url = Uri.parse("${ApiConstants.baseUrl}/items/$itemId/save");
    try {
      final response = await http.delete(url, headers: {'Authorization': 'Bearer $token'});
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> getSavedItems() async {
    final token = await _getToken();
    final url = Uri.parse("${ApiConstants.baseUrl}/items/saved");
    try {
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List;
      }
    } catch (e) {
      print("Lỗi getSavedItems: $e");
    }
    return [];
  }

}