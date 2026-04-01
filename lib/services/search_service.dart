// ---> BẮT ĐẦU SỬA
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../models/search_model.dart';

class SearchService {
  Future<List<UserSuggestionModel>> getTopInfluencers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse("${ApiConstants.baseUrl}/searchs/top-influencers");

    try {
      final response = await http.get(
        url,
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => UserSuggestionModel.fromJson(json)).toList();
      } else {
        print("❌ Lỗi API getTopInfluencers: Code ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("❌ Exception getTopInfluencers: $e");
    }
    return [];
  }

  Future<List<UserSuggestionModel>> searchUsers(String keyword) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse("${ApiConstants.baseUrl}/searchs/users?q=$keyword");

    try {
      final response = await http.get(
        url,
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => UserSuggestionModel.fromJson(json)).toList();
      } else {
        print("❌ Lỗi API searchUsers: Code ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("❌ Exception searchUsers: $e");
    }
    return [];
  }

  Future<List<SearchHistoryModel>> getSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse("${ApiConstants.baseUrl}/searchs/history");

    try {
      final response = await http.get(
        url,
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => SearchHistoryModel.fromJson(json)).toList();
      } else {
        print("❌ Lỗi API getSearchHistory: Code ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("❌ Exception getSearchHistory: $e");
    }
    return [];
  }

  Future<void> addSearchHistory(String keyword) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse("${ApiConstants.baseUrl}/searchs/history");

    await http.post(
      url,
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'keyword': keyword}),
    );
  }

  Future<void> clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse("${ApiConstants.baseUrl}/searchs/history");

    await http.delete(
      url,
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
  }
}
// <--- KẾT THÚC SỬA