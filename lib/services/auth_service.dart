import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../managers/google_auth_manager.dart';
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
        final prefs = await SharedPreferences.getInstance();

        final String accessToken = responseData['accessToken'];
        final String refreshToken = responseData['refreshToken'];
        Map<String, dynamic> decodedToken = JwtDecoder.decode(accessToken);
        String username = decodedToken['Username'] ?? "User";
        String avatar = decodedToken['Avatar'] ?? "";
        String email = decodedToken['email'] ?? "";
        String userId = decodedToken['AccountId'] ?? "";
        await prefs.setString('token', accessToken);
        await prefs.setString('refreshToken', refreshToken);
        await prefs.setString('username', username);
        await prefs.setString('avatar', avatar);
        await prefs.setString('email', email);
        await prefs.setString('userId', userId);
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

  // ---> CHỖ ĐƯỢC SỬA: Bổ sung hàm tự động lấy Token mới
  Future<bool> refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final String? accessToken = prefs.getString('token');
    final String? refreshToken = prefs.getString('refreshToken');

    if (accessToken == null || refreshToken == null) return false;

    final url = Uri.parse("${ApiConstants.baseUrl}${ApiConstants.refreshTokenEndpoint}");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "accessToken": accessToken,
          "refreshToken": refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        final String? newAccessToken = responseData['accessToken'];
        final String? newRefreshToken = responseData['refreshToken'];

        if (newAccessToken != null && newRefreshToken != null) {
          await prefs.setString('token', newAccessToken);
          await prefs.setString('refreshToken', newRefreshToken);
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    final url = Uri.parse("${ApiConstants.baseUrl}${ApiConstants.googleLoginEndpoint}");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"idToken": idToken}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        final Map<String, dynamic> dataObj = responseData['data'] ?? {};
        final String accessToken = (responseData['accessToken'] ?? dataObj['accessToken'] ?? '').toString();
        final String refreshToken = (responseData['refreshToken'] ?? dataObj['refreshToken'] ?? '').toString();


        Map<String, dynamic> decodedToken = JwtDecoder.decode(accessToken);
        String username = decodedToken['Username']?.toString() ?? "User";
        String avatar = decodedToken['Avatar']?.toString() ?? "";
        String decodedEmail = decodedToken['email']?.toString() ?? "";
        String userId = decodedToken['AccountId']?.toString() ?? "";
        final bool isNewUser = dataObj['isNewUser'] ?? false;

        await prefs.setString('token', accessToken);
        await prefs.setString('refreshToken', refreshToken);
        await prefs.setString('username', username);
        await prefs.setString('avatar', avatar);
        await prefs.setString('email', decodedEmail);
        await prefs.setString('userId', userId);

        return {"success": true, "data": responseData, "isNewUser": isNewUser};
      } else if (response.statusCode == 400 || response.statusCode == 401) {
        return {"success": false, "message": responseData['message'] ?? "Lỗi xác thực"};
      } else {
        return {"success": false, "message": "Lỗi hệ thống (${response.statusCode})"};
      }
    } catch (e) {
      return {"success": false, "message": "Không thể kết nối đến máy chủ: $e"};
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    try {
      final GoogleAuthManager googleAuthManager = GoogleAuthManager();
      await googleAuthManager.signOut();
    } catch (e) {
    }
  }
}