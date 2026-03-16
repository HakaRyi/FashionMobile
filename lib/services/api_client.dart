import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const Duration timeout = Duration(seconds: 10);

  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> get(Uri url) async {
    final headers = await _headers();

    return http.get(url, headers: headers).timeout(timeout);
  }

  static Future<http.Response> post(
      Uri url, {
        Map<String, dynamic>? body,
      }) async {
    final headers = await _headers();

    return http
        .post(
      url,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    )
        .timeout(timeout);
  }

  static Future<http.Response> put(
      Uri url, {
        Map<String, dynamic>? body,
      }) async {
    final headers = await _headers();

    return http
        .put(
      url,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    )
        .timeout(timeout);
  }

  static Future<http.Response> delete(
      Uri url, {
        Map<String, dynamic>? body,
      }) async {
    final headers = await _headers();

    return http
        .delete(
      url,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    )
        .timeout(timeout);
  }

  static Future<Map<String, String>> getHeaders() async {
    return await _headers();
  }
}