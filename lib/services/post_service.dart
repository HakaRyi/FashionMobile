import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import 'auth_service.dart';
import 'dart:convert';
class PostService {
  Future<List<dynamic>> getAllPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    // Giả sử bạn đã định nghĩa getAllPostsEndpoint trong ApiConstants là "/Post"
    final url = Uri.parse("${ApiConstants.baseUrl}${ApiConstants.getAllPostEndpoint}");

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
        if (data is List) {
          return data;
        } else if (data is Map && data.containsKey('message')) {
          return []; // Trả về mảng rỗng nếu Backend báo không có bài viết
        }
      }
      return [];
    } catch (e) {
      print("Error fetching all posts: $e");
      return [];
    }
  }
  Future<bool> createPost(Uint8List imageBytes, String content, bool isPublic) async {
    return await _attemptCreatePost(imageBytes, content, isPublic, isRetry: false);
  }

  Future<bool> _attemptCreatePost(Uint8List imageBytes, String content, bool isPublic, {required bool isRetry}) async {
    final url = Uri.parse("${ApiConstants.baseUrl}${ApiConstants.createPostEndpoint}");

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      var request = http.MultipartRequest('POST', url);

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      request.fields['content'] = content;
      request.fields['isPublic'] = isPublic.toString();

      request.files.add(http.MultipartFile.fromBytes(
        'Images',
        imageBytes,
        filename: 'post_image.jpg',
      ));

      final response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else if (response.statusCode == 401 && !isRetry) {
        final authService = AuthService();
        final isRefreshed = await authService.refreshToken();

        if (isRefreshed) {
          return await _attemptCreatePost(imageBytes, content, isPublic, isRetry: true);
        } else {
          return false;
        }
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
  Future<List<dynamic>> fetchMyPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse("${ApiConstants.baseUrl}${ApiConstants.getMyPostEndpoint}");

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
        if (data is List) {
          return data;
        } else if (data is Map && data.containsKey('message')) {
          return [];
        }
      }
      return [];
    } catch (e) {
      print("Error fetching posts: $e");
      return [];
    }
  }
}