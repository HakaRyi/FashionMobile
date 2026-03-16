// lib/services/post_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../models/post_feed_model.dart';
import 'api_client.dart';

class PostService {
  /// ==========================
  /// FETCH FEED
  /// ==========================
  Future<List<PostFeedModel>> fetchFeed({
    DateTime? cursor,
    int pageSize = 10,
  }) async {
    final query = {
      "pageSize": pageSize.toString(),
      if (cursor != null) "cursor": cursor.toIso8601String(),
    };

    final uri = Uri.parse(
      "${ApiConstants.baseUrl}${ApiConstants.feed}",
    ).replace(queryParameters: query);

    final response = await ApiClient.get(uri);

    if (response.statusCode != 200) {
      throw Exception("Failed to load feed");
    }

    final data = jsonDecode(response.body) as List;
    return data.map((e) => PostFeedModel.fromJson(e)).toList();
  }

  /// ==========================
  /// CREATE POST
  /// ==========================
  Future<int?> createPost({
    required List<Uint8List> imageBytesList,
    required String content,
    String? title,
  }) async {
    final uri = Uri.parse(
      "${ApiConstants.baseUrl}${ApiConstants.createPost}",
    );

    final headers = await ApiClient.getHeaders();
    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll(headers);

    request.fields['content'] = content;
    if (title != null && title.trim().isNotEmpty) {
      request.fields['title'] = title.trim();
    }

    for (int i = 0; i < imageBytesList.length; i++) {
      request.files.add(
        http.MultipartFile.fromBytes(
          "Images",
          imageBytesList[i],
          filename: "post_$i.jpg",
        ),
      );
    }

    final response = await request.send();

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception("Create post failed");
    }

    final body = await response.stream.bytesToString();
    final data = jsonDecode(body);

    return data["postId"];
  }

  /// ==========================
  /// GET MY POSTS
  /// backend trả PagedResultDto
  /// ==========================
  Future<List<PostFeedModel>> fetchMyPosts({
    int page = 1,
    int pageSize = 10,
  }) async {
    final uri = Uri.parse(
      "${ApiConstants.baseUrl}${ApiConstants.getMyPosts}",
    ).replace(queryParameters: {
      "page": page.toString(),
      "pageSize": pageSize.toString(),
    });

    final response = await ApiClient.get(uri);

    if (response.statusCode != 200) {
      throw Exception("Failed to load my posts");
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (data["items"] as List?) ?? const [];

    return items.map((e) => PostFeedModel.fromJson(e)).toList();
  }

  /// ==========================
  /// SAVE POST
  /// ==========================
  Future<bool> savePost(int postId) async {
    final endpoint = ApiConstants.toggleSavePost.replaceAll(
      "{postId}",
      postId.toString(),
    );

    final uri = Uri.parse("${ApiConstants.baseUrl}$endpoint");
    final response = await ApiClient.post(uri);

    if (response.statusCode != 200) {
      throw Exception("Save post failed");
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data["isSaved"] == true;
  }

  /// ==========================
  /// UNSAVE POST
  /// ==========================
  Future<bool> unsavePost(int postId) async {
    final endpoint = ApiConstants.toggleSavePost.replaceAll(
      "{postId}",
      postId.toString(),
    );

    final uri = Uri.parse("${ApiConstants.baseUrl}$endpoint");
    final response = await ApiClient.delete(uri);

    if (response.statusCode != 200) {
      throw Exception("Unsave post failed");
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data["isSaved"] == true;
  }

  /// ==========================
  /// GET SAVED POSTS
  /// ==========================
  Future<List<PostFeedModel>> fetchSavedPosts({
    int page = 1,
    int pageSize = 10,
  }) async {
    final uri = Uri.parse(
      "${ApiConstants.baseUrl}${ApiConstants.getSavedPosts}",
    ).replace(queryParameters: {
      "page": page.toString(),
      "pageSize": pageSize.toString(),
    });

    final response = await ApiClient.get(uri);

    if (response.statusCode != 200) {
      throw Exception("Failed to load saved posts");
    }

    final data = jsonDecode(response.body) as List;
    return data.map((e) => PostFeedModel.fromJson(e)).toList();
  }
}