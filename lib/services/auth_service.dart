import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse("${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "data": responseData};
      } else if (response.statusCode == 400 || response.statusCode == 401) {
        return {"success": false, "message": responseData['message'] ?? "Sai tài khoản"};
      } else {
        return {"success": false, "message": "Lỗi hệ thống (${response.statusCode})"};
      }
    } catch (e) {
      return {"success": false, "message": "Không thể kết nối đến máy chủ: $e"};
    }
  }
}