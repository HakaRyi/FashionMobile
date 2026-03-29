import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../models/event_model.dart';
import '../models/event_result_model.dart';
import '../models/post_feed_model.dart';

class EventService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
  Future<List<EventModel>> getPublicEvents() async {
    final String? token = await _getToken();
    final url = Uri.parse("${ApiConstants.baseUrl}${ApiConstants.publicEventsEndpoint}");

    try {
      final response = await http.get(url,
        headers: {
          'Authorization': 'Bearer $token', // THÊM DÒNG NÀY
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((dynamic item) => EventModel.fromJson(item)).toList();
      } else {
        throw Exception("Failed to load events");
      }
    } catch (e) {
      print("Error fetching events: $e");
      return [];
    }
  }
  Future<EventModel?> getEventById(int id) async {
    final String? token = await _getToken(); // LẤY TOKEN
    final url = Uri.parse("${ApiConstants.baseUrl}/events/$id");

    try {
      print("TOKEN THỰC TẾ: $token");
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token', // THÊM DÒNG NÀY VÀO ĐÂY
          'Content-Type': 'application/json',
        },
      );

      // LOG ĐỂ KIỂM TRA CHO CHẮC
      print("DEBUG API RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        return EventModel.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print("Lỗi lấy chi tiết event: $e");
    }
    return null;
  }
  Future<List<PostFeedModel>> getEventPosts(int eventId) async {
    final token = await _getToken();
    final url = Uri.parse("${ApiConstants.baseUrl}/events/$eventId/posts");
    try {
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        // Lưu ý: Backend trả về 'imageUrls' nhưng PostFeedModel dùng 'images', cần map lại
        return body.map((item) {
          item['images'] = item['imageUrls']; // Map field để tương thích PostFeedModel
          return PostFeedModel.fromJson(item);
        }).toList();
      }
    } catch (e) { print("Lỗi lấy bài post sự kiện: $e"); }
    return [];
  }

  // 2. Lấy bảng xếp hạng (Dùng cho EventResultScreen)
  Future<List<EventLeaderboardModel>> getLeaderboard(int eventId) async {
    final url = Uri.parse("${ApiConstants.baseUrl}/events/$eventId/leaderboard");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((e) => EventLeaderboardModel.fromJson(e)).toList();
      }
    } catch (e) { print("Lỗi lấy leaderboard: $e"); }
    return [];
  }

  // 3. Lấy kết quả cá nhân (Dùng cho MyResultDetailScreen)
  Future<MyEventResultModel?> getMyResult(int eventId) async {
    final token = await _getToken();
    final url = Uri.parse("${ApiConstants.baseUrl}/events/$eventId/my-result");
    try {
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        return MyEventResultModel.fromJson(jsonDecode(response.body));
      }
    } catch (e) { print("Lỗi lấy kết quả cá nhân: $e"); }
    return null;
  }
}