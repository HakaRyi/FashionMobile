  // lib/services/post_service.dart
  import 'dart:convert';
  import 'dart:typed_data';

  import 'package:http/http.dart' as http;
  import 'package:shared_preferences/shared_preferences.dart';

  import '../constants/api_constants.dart';
  import '../models/my_post_model.dart';
  import '../models/post_feed_model.dart';
  import 'api_client.dart';

  class PostService {
    Future<List<PostFeedModel>> fetchFeed({
      DateTime? cursor,
      int pageSize = 10,
    }) async {
      final query = {
        'pageSize': pageSize.toString(),
        if (cursor != null) 'cursor': cursor.toIso8601String(),
      };

      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.feed}',
      ).replace(queryParameters: query);

      final response = await ApiClient.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Failed to load feed');
      }

      final data = jsonDecode(response.body) as List;
      return data.map((e) => PostFeedModel.fromJson(e)).toList();
    }

    Future<List<PostFeedModel>> fetchTrendingPosts({
      int limit = 10,
    }) async {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.trendingPosts}',
      ).replace(queryParameters: {
        'limit': limit.toString(),
      });

      final response = await ApiClient.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Failed to load trending posts');
      }

      final data = jsonDecode(response.body) as List;
      return data.map((e) => PostFeedModel.fromJson(e)).toList();
    }

    Future<PostFeedModel> getPostDetail(int postId) async {
      final endpoint = ApiConstants.getPostDetail.replaceAll(
        '{postId}',
        postId.toString(),
      );

      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final response = await ApiClient.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Failed to load post detail');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return PostFeedModel.fromJson(data);
    }
    Future<int?> joinEventWithPost({
      required List<Uint8List> imageBytesList,
      required String content,
      required int eventId,
      String? title,
    }) async {
      final uri = Uri.parse('${ApiConstants.baseUrl}/post/event-participation');

      final headers = await ApiClient.getHeaders();
      final request = http.MultipartRequest('POST', uri);

      request.headers.addAll(headers);

      request.fields['Content'] = content.trim();
      request.fields['EventId'] = eventId.toString();
      if (title != null) request.fields['Title'] = title.trim();

      for (int i = 0; i < imageBytesList.length; i++) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'Images',
            imageBytesList[i],
            filename: 'event_post_$i.jpg',
          ),
        );
      }

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(body);
        return data['postId'] as int?;
      } else {
        final errorData = jsonDecode(body);
        throw Exception(errorData['message'] ?? 'Lỗi tham gia sự kiện');
      }
    }
    Future<int?> createPost({
      required List<Uint8List> imageBytesList,
      required String content,
      String? title,
    }) async {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.createPost}',
      );

      final headers = await ApiClient.getHeaders();
      final request = http.MultipartRequest('POST', uri);

      request.headers.addAll(headers);

      request.fields['content'] = content.trim();
      if (title != null && title.trim().isNotEmpty) {
        request.fields['title'] = title.trim();
      }

      for (int i = 0; i < imageBytesList.length; i++) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'Images',
            imageBytesList[i],
            filename: 'post_$i.jpg',
          ),
        );
      }

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('Create post failed: $body');
      }

      if (body.isEmpty) return null;

      final data = jsonDecode(body) as Map<String, dynamic>;
      return data['postId'] as int?;
    }

    Future<List<PostFeedModel>> fetchMyPosts({
      int page = 1,
      int pageSize = 10,
    }) async {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.getMyPosts}',
      ).replace(queryParameters: {
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      });

      final response = await ApiClient.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Failed to load my posts');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = (data['items'] as List?) ?? const [];

      return items.map((e) => PostFeedModel.fromJson(e)).toList();
    }

    Future<List<PostFeedModel>> fetchUserPosts({
      required int userId,
      int page = 1,
      int pageSize = 10,
    }) async {
      final endpoint = ApiConstants.getUserPosts.replaceAll(
        '{userId}',
        userId.toString(),
      );

      final uri = Uri.parse(
        '${ApiConstants.baseUrl}$endpoint',
      ).replace(queryParameters: {
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      });

      final response = await ApiClient.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Failed to load user posts');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = (data['items'] as List?) ?? const [];

      return items.map((e) => PostFeedModel.fromJson(e)).toList();
    }

    Future<Map<String, dynamic>> hidePost(int postId) async {
      final endpoint = ApiConstants.hidePost.replaceAll(
        '{postId}',
        postId.toString(),
      );

      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final response = await ApiClient.patch(uri);

      if (response.statusCode != 200) {
        throw Exception('Hide post failed');
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    Future<Map<String, dynamic>> unhidePost(int postId) async {
      final endpoint = ApiConstants.unhidePost.replaceAll(
        '{postId}',
        postId.toString(),
      );

      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final response = await ApiClient.patch(uri);

      if (response.statusCode != 200) {
        throw Exception('Unhide post failed');
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    Future<void> updatePost({
      required int postId,
      String? title,
      String? content,
    }) async {
      final endpoint = ApiConstants.updatePost.replaceAll(
        '{postId}',
        postId.toString(),
      );

      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');

      final body = <String, dynamic>{};
      if (title != null) body['title'] = title.trim();
      if (content != null) body['content'] = content.trim();

      final response = await ApiClient.put(uri, body: body);

      if (response.statusCode != 204) {
        throw Exception('Update post failed: ${response.body}');
      }
    }


    // Future<bool> updatePost(int postId, Uint8List? newImageBytes, String content, bool isPublic) async {
    //   final url = Uri.parse("${ApiConstants.baseUrl}/Post/$postId");
    //
    //   try {
    //     final prefs = await SharedPreferences.getInstance();
    //     final token = prefs.getString('token') ?? '';
    //
    //     var request = http.MultipartRequest('PUT', url);
    //
    //     request.headers.addAll({
    //       'Authorization': 'Bearer $token',
    //       'Content-Type': 'multipart/form-data',
    //     });
    //
    //     request.fields['Content'] = content;
    //     request.fields['IsPublic'] = isPublic.toString();
    //
    //     if (newImageBytes != null) {
    //       request.files.add(
    //         http.MultipartFile.fromBytes(
    //           'Images',
    //           newImageBytes,
    //           filename: 'updated_image.jpg',
    //         ),
    //       );
    //     }
    //
    //     final response = await request.send();
    //
    //     if (response.statusCode == 200) {
    //       return true;
    //     } else if (response.statusCode == 401) {
    //       final authService = AuthService();
    //       final isRefreshed = await authService.refreshToken();
    //       if (isRefreshed) {
    //         return await updatePost(postId, newImageBytes, content, isPublic);
    //       }
    //       return false;
    //     } else {
    //       final respStr = await response.stream.bytesToString();
    //       print("Update failed: ${response.statusCode} - $respStr");
    //       return false;
    //     }
    //   } catch (e) {
    //     print("Error updating post: $e");
    //     return false;
    //   }
    // }

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

  //
  //   Future<void> deletePost(int postId) async {
  //     final endpoint = ApiConstants.deletePost.replaceAll(
  //       '{postId}',
  //       postId.toString(),
  //     );
  //
  //     final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
  //     final response = await ApiClient.delete(uri);
  //
  //
  //     if (response.statusCode != 204) {
  //       throw Exception('Delete post failed');
  //     }
  //
  //   }
  //
    Future<bool> savePost(int postId) async {
      final endpoint = ApiConstants.toggleSavePost.replaceAll(
        '{postId}',
        postId.toString(),
      );

      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final response = await ApiClient.post(uri);

      if (response.statusCode != 200) {
        throw Exception('Save post failed');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['isSaved'] == true;
    }

    Future<bool> unsavePost(int postId) async {
      final endpoint = ApiConstants.toggleSavePost.replaceAll(
        '{postId}',
        postId.toString(),
      );

      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final response = await ApiClient.delete(uri);

      if (response.statusCode != 200) {
        throw Exception('Unsave post failed');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['isSaved'] == true;
    }

    Future<List<PostFeedModel>> fetchSavedPosts({
      int page = 1,
      int pageSize = 10,
    }) async {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.getSavedPosts}',
      ).replace(queryParameters: {
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      });

      final response = await ApiClient.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Failed to load saved posts');
      }

      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded.map((e) => PostFeedModel.fromJson(e)).toList();
      }

      if (decoded is Map<String, dynamic>) {
        final items = (decoded['items'] as List?) ?? const [];
        return items.map((e) => PostFeedModel.fromJson(e)).toList();
      }

      throw Exception('Unexpected saved posts response');
    }
  }