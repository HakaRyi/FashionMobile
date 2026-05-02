import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';

class ApiClient {
  static const Duration timeout = Duration(seconds: 10);
  static Completer<bool>? _refreshTokenCompleter;

  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    return {
      'Content-Type': 'application/json',
      if (token.trim().isNotEmpty) 'Authorization': 'Bearer $token',
      'ngrok-skip-browser-warning': '69420',
    };
  }

  static Future<http.Response> get(Uri url) async {
    return _execute(
          (headers) => http.get(
        url,
        headers: headers,
      ),
    );
  }

  static Future<http.Response> post(
      Uri url, {
        Map<String, dynamic>? body,
      }) async {
    return _execute(
          (headers) => http.post(
        url,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ),
    );
  }

  static Future<http.Response> put(
      Uri url, {
        Map<String, dynamic>? body,
      }) async {
    return _execute(
          (headers) => http.put(
        url,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ),
    );
  }

  static Future<http.Response> patch(
      Uri url, {
        Map<String, dynamic>? body,
      }) async {
    return _execute(
          (headers) => http.patch(
        url,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ),
    );
  }

  static Future<http.Response> delete(
      Uri url, {
        Map<String, dynamic>? body,
      }) async {
    return _execute(
          (headers) => http.delete(
        url,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ),
    );
  }

  static Future<Map<String, String>> getHeaders() async {
    return _headers();
  }

  static Future<bool> hasSession() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token');
    final refreshToken = prefs.getString('refreshToken');

    return token != null &&
        token.trim().isNotEmpty &&
        refreshToken != null &&
        refreshToken.trim().isNotEmpty;
  }

  static Future<bool> _refreshToken() async {
    if (_refreshTokenCompleter != null) {
      return _refreshTokenCompleter!.future;
    }

    _refreshTokenCompleter = Completer<bool>();

    final prefs = await SharedPreferences.getInstance();

    final accessToken = prefs.getString('token');
    final refreshToken = prefs.getString('refreshToken');

    if (accessToken == null ||
        accessToken.trim().isEmpty ||
        refreshToken == null ||
        refreshToken.trim().isEmpty) {
      _completeRefresh(false);
      return false;
    }

    try {
      final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.refreshTokenEndpoint}',
      );

      final response = await http
          .post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': '69420',
        },
        body: jsonEncode({
          'accessToken': accessToken,
          'refreshToken': refreshToken,
        }),
      )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = _decodeResponseBody(response.body);

        final newAccessToken =
        (data['accessToken'] ?? data['data']?['accessToken'])?.toString();

        final newRefreshToken =
        (data['refreshToken'] ?? data['data']?['refreshToken'])
            ?.toString();

        if (newAccessToken != null &&
            newAccessToken.isNotEmpty &&
            newRefreshToken != null &&
            newRefreshToken.isNotEmpty) {
          await prefs.setString('token', newAccessToken);
          await prefs.setString('refreshToken', newRefreshToken);

          _completeRefresh(true);
          return true;
        }
      }

      _completeRefresh(false);
      return false;
    } catch (_) {
      _completeRefresh(false);
      return false;
    }
  }

  static Map<String, dynamic> _decodeResponseBody(String body) {
    if (body.trim().isEmpty) {
      return {};
    }

    final decoded = jsonDecode(body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return {};
  }

  static void _completeRefresh(bool value) {
    if (_refreshTokenCompleter != null &&
        !_refreshTokenCompleter!.isCompleted) {
      _refreshTokenCompleter!.complete(value);
    }

    _refreshTokenCompleter = null;
  }

  static Future<http.Response> _execute(
      Future<http.Response> Function(Map<String, String>) request,
      ) async {
    Map<String, String> headers = await _headers();

    http.Response response = await request(headers).timeout(timeout);

    if (response.statusCode == 401) {
      final isRefreshed = await _refreshToken();

      if (isRefreshed) {
        headers = await _headers();
        response = await request(headers).timeout(timeout);
        return response;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('refreshToken');

      throw Exception('Your session has expired. Please log in again.');
    }

    return response;
  }
}