// lib/services/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';
import '../constants/api_constants.dart';
import '../main.dart';
import '../screens/login_screen.dart';

class ApiClient {
  static const Duration timeout = Duration(seconds: 10);

  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'ngrok-skip-browser-warning': '69420',
    };
  }

  static Future<http.Response> get(Uri url) async {
    return _execute((headers) => http.get(url, headers: headers));
  }

  static Future<http.Response> post(
      Uri url, {
        Map<String, dynamic>? body,
      }) async {

    return _execute((headers) => http.post(
      url,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    ));
  }

  static Future<http.Response> put(
      Uri url, {
        Map<String, dynamic>? body,
      }) async {

    return _execute((headers) => http.put(
      url,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    ));
  }

  static Future<http.Response> patch(
      Uri url, {
        Map<String, dynamic>? body,
      }) async {

    return _execute((headers) => http.patch(
      url,
      headers: headers,
      body: body == null ? null : jsonEncode(body),
    ));
  }

  static Future<http.Response> delete(
      Uri url, {
        Map<String, dynamic>? body,
      }) async {
    return _execute((headers) => http.delete(
      url,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    ));
  }

  static Future<Map<String, String>> getHeaders() async {
    return await _headers();
  }

  static Future<bool> _refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refreshToken');

    if (refreshToken == null) return false;

    try {
      final url = Uri.parse("${ApiConstants.baseUrl}/Auth/refresh");
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': '69420',
        },
        body: jsonEncode({
          'refreshToken': refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await prefs.setString('token', data['accessToken']);
        await prefs.setString('refreshToken', data['refreshToken']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<http.Response> _execute(Future<http.Response> Function(Map<String, String>) request) async {
    Map<String, String> headers = await _headers();
    http.Response response = await request(headers).timeout(timeout);

    if (response.statusCode == 401) {
      final isRefreshed = await _refreshToken();
      if (isRefreshed) {
        headers = await _headers();
        response = await request(headers).timeout(timeout);
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
        );
      }
    }
    return response;
  }
}