import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class ItemService {
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
        return jsonDecode(response.body);
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
    required bool useCommunityItems,
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
        },
        body: jsonEncode({
          "prompt": prompt,
          "referenceItemId": referenceItemId,
          "useMyWardrobe": useMyWardrobe,
          "useCommunityItems": useCommunityItems,
          "useSavedItems": false,
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
}