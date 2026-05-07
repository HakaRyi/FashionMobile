import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';
import '../managers/google_auth_manager.dart';

class AuthService {
  Map<String, dynamic> _decodeResponseBody(String body) {
    if (body.trim().isEmpty) {
      return {};
    }

    final decoded = jsonDecode(body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return {};
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}',
    );

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': '69420',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final responseData = _decodeResponseBody(response.body);

      if (response.statusCode == 200) {
        await _saveAuthData(responseData);

        return {
          'success': true,
          'data': responseData,
        };
      }

      if (response.statusCode == 400 || response.statusCode == 401) {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Invalid email or password.',
          'statusCode': response.statusCode
        };
      }

      return {
        'success': false,
        'message': 'System error (${response.statusCode}). Please try again later.',
      };
    } catch (_) {
      return {
        'success': false,
        'message':
        'Unable to connect to the server. Please check your internet connection and try again.',
      };
    }
  }

  Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.googleLoginEndpoint}',
    );

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': '69420',
        },
        body: jsonEncode({
          'idToken': idToken,
        }),
      );

      final responseData = _decodeResponseBody(response.body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> dataObj = responseData['data'] ?? {};
        final bool isNewUser = dataObj['isNewUser'] ?? false;

        await _saveAuthData(responseData);

        return {
          'success': true,
          'data': responseData,
          'isNewUser': isNewUser,
        };
      }

      if (response.statusCode == 400 || response.statusCode == 401) {
        return {
          'success': false,
          'message':
          responseData['message'] ?? 'Google authentication failed.',
        };
      }

      return {
        'success': false,
        'message': 'System error (${response.statusCode}). Please try again later.',
      };
    } catch (_) {
      return {
        'success': false,
        'message':
        'Unable to connect to the server. Please check your internet connection and try again.',
      };
    }
  }

  Future<bool> refreshToken() async {
    final prefs = await SharedPreferences.getInstance();

    final String? accessToken = prefs.getString('token');
    final String? refreshToken = prefs.getString('refreshToken');

    if (accessToken == null ||
        accessToken.trim().isEmpty ||
        refreshToken == null ||
        refreshToken.trim().isEmpty) {
      return false;
    }

    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.refreshTokenEndpoint}',
    );

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': '69420',
        },
        body: jsonEncode({
          'accessToken': accessToken,
          'refreshToken': refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = _decodeResponseBody(response.body);

        final String? newAccessToken =
        (responseData['accessToken'] ??
            responseData['data']?['accessToken'])
            ?.toString();

        final String? newRefreshToken =
        (responseData['refreshToken'] ??
            responseData['data']?['refreshToken'])
            ?.toString();

        if (newAccessToken != null &&
            newAccessToken.isNotEmpty &&
            newRefreshToken != null &&
            newRefreshToken.isNotEmpty) {
          await prefs.setString('token', newAccessToken);
          await prefs.setString('refreshToken', newRefreshToken);

          await _saveUserInfoFromToken(newAccessToken);

          return true;
        }
      }

      await prefs.remove('token');
      await prefs.remove('refreshToken');
      return false;
    } catch (_) {
      await prefs.remove('token');
      await prefs.remove('refreshToken');
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    final accessToken = prefs.getString('token') ?? '';
    final refreshToken = prefs.getString('refreshToken') ?? '';

    try {
      if (accessToken.trim().isNotEmpty && refreshToken.trim().isNotEmpty) {
        final url = Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.logoutEndpoint}',
        );

        await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
            'ngrok-skip-browser-warning': '69420',
          },
          body: jsonEncode({
            'refreshToken': refreshToken,
          }),
        );
      }
    } catch (_) {
      // Still clear local data even if server logout fails.
    }

    await prefs.clear();

    try {
      final GoogleAuthManager googleAuthManager = GoogleAuthManager();
      await googleAuthManager.signOut();
    } catch (_) {}
  }

  Future<Map<String, dynamic>> register(
      String email,
      String password,
      String username,
      DateTime dob,
      ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.registerEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': '69420',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'username': username,
          'dateOfBirth': dob.toIso8601String(),
        }),
      );

      final data = _decodeResponseBody(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Registration successful.',
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Registration failed.',
      };
    } catch (_) {
      return {
        'success': false,
        'message':
        'Unable to connect to the server. Please check your internet connection and try again.',
      };
    }
  }

  Future<Map<String, dynamic>> verifyAccount(String email, String code) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/verify'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': '69420',
        },
        body: jsonEncode({
          'email': email,
          'code': code,
        }),
      );

      final data = _decodeResponseBody(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Account verified successfully.',
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Verification failed.',
      };
    } catch (_) {
      return {
        'success': false,
        'message':
        'Unable to connect to the server. Please check your internet connection and try again.',
      };
    }
  }

  Future<void> _saveAuthData(Map<String, dynamic> responseData) async {
    final prefs = await SharedPreferences.getInstance();

    final Map<String, dynamic> dataObj = responseData['data'] ?? {};

    final String accessToken =
    (responseData['accessToken'] ?? dataObj['accessToken'] ?? '')
        .toString();

    final String refreshToken =
    (responseData['refreshToken'] ?? dataObj['refreshToken'] ?? '')
        .toString();

    if (accessToken.isEmpty || refreshToken.isEmpty) {
      throw Exception('Token information is missing.');
    }

    await prefs.setString('token', accessToken);
    await prefs.setString('refreshToken', refreshToken);

    await _saveUserInfoFromToken(accessToken);
  }

  Future<void> _saveUserInfoFromToken(String accessToken) async {
    final prefs = await SharedPreferences.getInstance();

    final Map<String, dynamic> decodedToken = JwtDecoder.decode(accessToken);

    final String username =
    (decodedToken['Username'] ?? decodedToken['username'] ?? 'User')
        .toString();

    final String avatar = (decodedToken['Avatar'] ?? '').toString();

    final String email =
    (decodedToken['email'] ?? decodedToken['Email'] ?? '').toString();

    final String userId = (decodedToken['AccountId'] ??
        decodedToken['accountId'] ??
        decodedToken['nameid'] ??
        decodedToken[
        'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] ??
        '')
        .toString();

    await prefs.setString('username', username);
    await prefs.setString('avatar', avatar);
    await prefs.setString('email', email);
    await prefs.setString('userId', userId);
  }
}