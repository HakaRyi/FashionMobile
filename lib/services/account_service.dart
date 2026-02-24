import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class AccountService {
  Future<Map<String, dynamic>?> getMyProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString('userId');
    final String? token = prefs.getString('token');

    if (userId == null) return null;

    // Thay thế {id} bằng id thực tế
    final url = Uri.parse("${ApiConstants.baseUrl}/Account/$userId");

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
    } catch (e) {
      print("Lỗi fetch profile: $e");
    }
    return null;
  }
}