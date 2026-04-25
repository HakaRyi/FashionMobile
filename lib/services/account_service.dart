import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';
import 'api_client.dart';

class AccountService {
  Future<Map<String, dynamic>?> getMyProfile() async {
    final url = Uri.parse('${ApiConstants.baseUrl}/Account/me');

    try {
      final response = await ApiClient.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return null;
    } catch (e) {
      debugPrintSafe('Fetch profile error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String targetUserId) async {
    if (targetUserId.trim().isEmpty) {
      return null;
    }

    final url = Uri.parse('${ApiConstants.baseUrl}/Account/$targetUserId');

    try {
      final response = await ApiClient.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return null;
    } catch (e) {
      debugPrintSafe('Fetch user profile error: $e');
      return null;
    }
  }

  Future<bool> completeOnboarding(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.trim().isEmpty) {
      return false;
    }

    final url = Uri.parse('${ApiConstants.baseUrl}/Account/onboarding');

    try {
      final response = await ApiClient.put(
        url,
        body: {
          'userName': username,
        },
      );

      if (response.statusCode == 200) {
        await prefs.setString('username', username);
        return true;
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  Future<int> updateProfile({
    required String username,
    required String email,
    required String description,
    File? avatarFile,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.trim().isEmpty) {
      return -1;
    }

    final url = Uri.parse('${ApiConstants.baseUrl}/Account/update-profile');

    final request = http.MultipartRequest('PUT', url);

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['ngrok-skip-browser-warning'] = '69420';

    request.fields['Username'] = username;
    request.fields['Email'] = email;
    request.fields['Description'] = description;

    if (avatarFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'Avatar',
          avatarFile.path,
        ),
      );
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        await prefs.setString('username', username);
        await prefs.setString('email', email);
        return 1;
      }

      if (response.statusCode == 401) {
        return -1;
      }

      if (response.statusCode == 409) {
        final body = jsonDecode(response.body);
        final msg = body['message']?.toString() ?? '';

        if (msg.contains('Email')) {
          return -2;
        }

        return -3;
      }

      return 0;
    } catch (e) {
      debugPrintSafe('Update profile error: $e');
      return 0;
    }
  }
}

void debugPrintSafe(String message) {
  // Keep this helper simple so service files can log without importing Flutter.
  // ignore: avoid_print
  print(message);
}