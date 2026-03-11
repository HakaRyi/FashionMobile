  import 'dart:convert';
  import 'package:http/http.dart' as http;
  import 'package:shared_preferences/shared_preferences.dart';
  import '../constants/api_constants.dart';

  class SocialService {

    /// ==========================
    /// LIKE / UNLIKE
    /// ==========================
    static Future<Map<String, dynamic>?> toggleLike(int postId) async {

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final endpoint =
      ApiConstants.toggleLike.replaceFirst("{postId}", postId.toString());

      final url = Uri.parse("${ApiConstants.baseUrl}$endpoint");

      try {

        final response = await http
            .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {

          final data = jsonDecode(response.body);

          if (data is Map<String, dynamic>) {
            return data;
          }

          return null;
        }

        print("ToggleLike failed: ${response.statusCode}");
        return null;

      } catch (e) {

        print("ToggleLike error: $e");
        return null;
      }
    }



    /// ==========================
    /// GET LIKE COUNT
    /// ==========================
    static Future<int> getLikeCount(String postId) async {

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final endpoint =
      ApiConstants.getLikeCount.replaceFirst("{postId}", postId);

      final url = Uri.parse("${ApiConstants.baseUrl}$endpoint");

      try {

        final response = await http
            .get(
          url,
          headers: {
            'Authorization': 'Bearer $token',
          },
        )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {

          final data = jsonDecode(response.body);

          return data['likeCount'] ?? 0;
        }

        print("GetLikeCount failed: ${response.statusCode}");
        return 0;

      } catch (e) {

        print("GetLikeCount error: $e");
        return 0;
      }
    }



    /// ==========================
    /// GET COMMENTS
    /// ==========================
    static Future<List<dynamic>> getComments(int postId) async {

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final endpoint =
      ApiConstants.comments.replaceFirst("{postId}", postId.toString());

      final url = Uri.parse("${ApiConstants.baseUrl}$endpoint");

      try {

        final response = await http
            .get(
          url,
          headers: {
            'Authorization': 'Bearer $token',
          },
        )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {

          final data = jsonDecode(response.body);

          if (data is List) {
            return data;
          }

          return [];
        }

        print("GetComments failed: ${response.statusCode}");
        return [];

      } catch (e) {

        print("GetComments error: $e");
        return [];
      }
    }

    /// ==========================
    /// CREATE COMMENT
    /// ==========================
    static Future<Map<String, dynamic>?> createComment(
        int postId,
        String content,
        ) async {

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final endpoint =
      ApiConstants.createComment.replaceFirst("{postId}", postId.toString());

      final url = Uri.parse("${ApiConstants.baseUrl}$endpoint");

      try {

        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            "content": content,
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200 || response.statusCode == 201) {

          final data = jsonDecode(response.body);

          if (data is Map<String, dynamic>) {
            return data;
          }

          return null;
        }

        print("CreateComment failed: ${response.statusCode}");
        return null;

      } catch (e) {

        print("CreateComment error: $e");
        return null;
      }
    }
  }