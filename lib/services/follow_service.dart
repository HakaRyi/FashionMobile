import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';
import '../models/search_model.dart';
import '../utils/global_event_bus.dart';

class FollowService {
  Future<bool> followUser(int targetUserId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse("${ApiConstants.baseUrl}/Follow/$targetUserId");

    try {
      final response = await http.post(
        url,
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        GlobalEventBus().fireProfileUpdate();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> unfollowUser(int targetUserId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse("${ApiConstants.baseUrl}/Follow/$targetUserId");

    try {
      final response = await http.delete(
        url,
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        GlobalEventBus().fireProfileUpdate();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkIsFollowing(int targetUserId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse("${ApiConstants.baseUrl}/Follow/check/$targetUserId");

    try {
      final response = await http.post(
        url,
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['isFollowing'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<List<UserSuggestionModel>> getFollowers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse("${ApiConstants.baseUrl}/Follow/get-followers");

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

        return data.map((json) {
          return UserSuggestionModel(
            accountId: json['followerId'] ?? '',
            fullName: json['followerName']?.toString() ?? '',
            username: json['followerName']?.toString() ?? '',
            avatarUrl: json['followerAvatar']?.toString() ?? '',
            followerCount: 0,
            isFollowing: true,
          );
        }).toList();
      }
    } catch (e) {
      return [];
    }
    return [];
  }
}