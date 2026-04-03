import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import 'api_client.dart';

class AccountService {
  Future<Map<String, dynamic>?> getMyProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString('userId');

    if (userId == null) return null;

    final url = Uri.parse("${ApiConstants.baseUrl}/Account/$userId");

    try {
      final response = await ApiClient.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Lỗi fetch profile: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>?> getUserProfile(String targetUserId) async {
    final prefs = await SharedPreferences.getInstance();

    if (targetUserId.trim().isEmpty) return null;

    final url = Uri.parse("${ApiConstants.baseUrl}/Account/$targetUserId");

    try {
      final response = await ApiClient.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Lỗi fetch user profile: $e");
    }
    return null;
  }

  Future<bool> completeOnboarding(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return false;

    final url = Uri.parse("${ApiConstants.baseUrl}/Account/onboarding");

    try {
      final response = await ApiClient.put(
        url,
        body: {
          "userName": username,
        },
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', username);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}