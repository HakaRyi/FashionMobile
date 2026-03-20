import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import 'auth_service.dart';

class PostService {

  Future<List<dynamic>> fetchFeed({
    DateTime? cursor,
    int pageSize = 10,
  }) async {

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    String url =
        "${ApiConstants.baseUrl}${ApiConstants.feedEndpoint}?pageSize=$pageSize";

    if (cursor != null) {
      url += "&cursor=${Uri.encodeComponent(cursor.toIso8601String())}";
    }

    final uri = Uri.parse(url);

    try {

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {

        final data = jsonDecode(response.body);

        if (data is List) {
          return data;
        }

      }

      return [];

    } catch (e) {

      print("Error fetching feed: $e");
      return [];

    }
  }


  Future<bool> createPost(
      Uint8List imageBytes,
      String content,
      bool isPublic,
      ) async {

    return await _attemptCreatePost(
      imageBytes,
      content,
      isPublic,
      isRetry: false,
    );
  }


  Future<bool> _attemptCreatePost(
      Uint8List imageBytes,
      String content,
      bool isPublic,
      {required bool isRetry}
      ) async {

    final url =
    Uri.parse("${ApiConstants.baseUrl}${ApiConstants.createPostEndpoint}");

    try {

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      var request = http.MultipartRequest('POST', url);

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      request.fields['content'] = content;
      request.fields['isPublic'] = isPublic.toString();

      request.files.add(
        http.MultipartFile.fromBytes(
          'Images',
          imageBytes,
          filename: 'post_image.jpg',
        ),
      );

      final response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {

        return true;

      }
      else if (response.statusCode == 401 && !isRetry) {

        final authService = AuthService();

        final isRefreshed =
        await authService.refreshToken();

        if (isRefreshed) {

          return await _attemptCreatePost(
            imageBytes,
            content,
            isPublic,
            isRetry: true,
          );

        }

        return false;

      }
      else {

        return false;

      }

    } catch (e) {

      print("Create post error: $e");
      return false;

    }
  }

  Future<bool> updatePost(int postId, Uint8List? newImageBytes, String content, bool isPublic) async {
    final url = Uri.parse("${ApiConstants.baseUrl}/Post/$postId");

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      var request = http.MultipartRequest('PUT', url);

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Content-Type': 'multipart/form-data',
      });

      request.fields['Content'] = content;
      request.fields['IsPublic'] = isPublic.toString();

      if (newImageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'Images',
            newImageBytes,
            filename: 'updated_image.jpg',
          ),
        );
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        final authService = AuthService();
        final isRefreshed = await authService.refreshToken();
        if (isRefreshed) {
          return await updatePost(postId, newImageBytes, content, isPublic);
        }
        return false;
      } else {
        final respStr = await response.stream.bytesToString();
        print("Update failed: ${response.statusCode} - $respStr");
        return false;
      }
    } catch (e) {
      print("Error updating post: $e");
      return false;
    }
  }

  Future<bool> deletePost(int postId) async {
    final url = Uri.parse("${ApiConstants.baseUrl}/Post/$postId");
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Delete error: $e");
      return false;
    }
  }
  Future<List<dynamic>> fetchMyPosts() async {

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final url =
    Uri.parse("${ApiConstants.baseUrl}${ApiConstants.getMyPostEndpoint}");

    try {

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {

        final data = jsonDecode(response.body);

        if (data is Map && data.containsKey('items')) {
          return data['items'] as List<dynamic>;
        }

      }

      return [];

    } catch (e) {

      print("Error fetching my posts: $e");
      return [];

    }

  }

}