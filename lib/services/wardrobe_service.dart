import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../models/wardrobe_item_model.dart';

class WardrobeService {
  Future<List<WardrobeItemModel>> getMyWardrobeItems() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/Wardrobe/my-items'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
        "ngrok-skip-browser-warning": "69420",
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => WardrobeItemModel.fromJson(json)).toList();
    } else {
      throw Exception('Lỗi tải danh sách tủ đồ');
    }
  }
}