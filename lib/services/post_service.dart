import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../models/hashtag_suggestion_model.dart';
import '../models/paged_posts_response.dart';
import '../models/post_feed_model.dart';
import '../models/shareable_user_model.dart';
import '../models/trending_hashtag_model.dart';
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
      throw Exception('Failed to load feed: ${response.body}');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is List) {
      return decoded.map((e) => PostFeedModel.fromJson(e)).toList();
    }

    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];

      if (data is List) {
        return data.map((e) => PostFeedModel.fromJson(e)).toList();
      }

      if (data is Map<String, dynamic>) {
        final items = (data['items'] as List?) ?? const [];
        return items.map((e) => PostFeedModel.fromJson(e)).toList();
      }

      final items = (decoded['items'] as List?) ?? const [];
      return items.map((e) => PostFeedModel.fromJson(e)).toList();
    }

    throw Exception('Unexpected feed response');
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
      throw Exception('Failed to load trending posts: ${response.body}');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is List) {
      return decoded.map((e) => PostFeedModel.fromJson(e)).toList();
    }

    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];

      if (data is List) {
        return data.map((e) => PostFeedModel.fromJson(e)).toList();
      }

      if (data is Map<String, dynamic>) {
        final items = (data['items'] as List?) ?? const [];
        return items.map((e) => PostFeedModel.fromJson(e)).toList();
      }

      final items = (decoded['items'] as List?) ?? const [];
      return items.map((e) => PostFeedModel.fromJson(e)).toList();
    }

    throw Exception('Unexpected trending response');
  }

  Future<PostFeedModel> getPostDetail(int postId) async {
    final endpoint = ApiConstants.getPostDetail.replaceAll(
      '{postId}',
      postId.toString(),
    );

    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final response = await ApiClient.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load post detail: ${response.body}');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];

      if (data is Map<String, dynamic>) {
        return PostFeedModel.fromJson(data);
      }

      return PostFeedModel.fromJson(decoded);
    }

    throw Exception('Unexpected post detail response');
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
    request.headers.remove('Content-Type');

    request.fields['Content'] = content.trim();
    request.fields['EventId'] = eventId.toString();

    if (title != null && title.trim().isNotEmpty) {
      request.fields['Title'] = title.trim();
    }

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

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Join event with post failed: $body');
    }

    if (body.isEmpty) return null;

    final decoded = jsonDecode(body);

    if (decoded is Map<String, dynamic>) {
      final root = decoded['data'] is Map<String, dynamic>
          ? decoded['data'] as Map<String, dynamic>
          : decoded;

      return root['postId'] as int?;
    }

    return null;
  }

  Future<int?> createPost({
    required List<Uint8List> imageBytesList,
    required String content,
    String? title,
    List<String>? hashtags,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.createPost}',
    );

    final headers = await ApiClient.getHeaders();
    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll(headers);
    request.headers.remove('Content-Type');

    request.fields['Content'] = content.trim();

    if (hashtags != null && hashtags.isNotEmpty) {
      for (int i = 0; i < hashtags.length; i++) {
        final cleanTag = hashtags[i].replaceAll('#', '').trim();
        if (cleanTag.isNotEmpty) {
          request.fields['Hashtags[$i]'] = cleanTag;
        }
      }
    }

    if (title != null && title.trim().isNotEmpty) {
      request.fields['Title'] = title.trim();
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

    final decoded = jsonDecode(body);

    if (decoded is Map<String, dynamic>) {
      final root = decoded['data'] is Map<String, dynamic>
          ? decoded['data'] as Map<String, dynamic>
          : decoded;

      return root['postId'] as int?;
    }

    return null;
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
      throw Exception('Failed to load my posts: ${response.body}');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected my posts response');
    }

    final root = decoded['data'] is Map<String, dynamic>
        ? decoded['data'] as Map<String, dynamic>
        : decoded;

    final items = (root['items'] as List?) ?? const [];

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
      throw Exception('Failed to load user posts: ${response.body}');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected user posts response');
    }

    final root = decoded['data'] is Map<String, dynamic>
        ? decoded['data'] as Map<String, dynamic>
        : decoded;

    final items = (root['items'] as List?) ?? const [];

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
      throw Exception('Hide post failed: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'];

    if (data is Map<String, dynamic>) {
      return data;
    }

    return decoded;
  }

  Future<Map<String, dynamic>> unhidePost(int postId) async {
    final endpoint = ApiConstants.unhidePost.replaceAll(
      '{postId}',
      postId.toString(),
    );

    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final response = await ApiClient.patch(uri);

    if (response.statusCode != 200) {
      throw Exception('Unhide post failed: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'];

    if (data is Map<String, dynamic>) {
      return data;
    }

    return decoded;
  }

  Future<PostFeedModel> updatePost({
    required int postId,
    String? title,
    String? content,
    List<Uint8List>? imageBytesList,
    List<String>? hashtags,
  }) async {
    final endpoint = ApiConstants.updatePost.replaceAll(
      '{postId}',
      postId.toString(),
    );

    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');

    final headers = await ApiClient.getHeaders();
    final request = http.MultipartRequest('PUT', uri);

    request.headers.addAll(headers);
    request.headers.remove('Content-Type');

    if (title != null) {
      request.fields['Title'] = title.trim();
    }

    if (content != null) {
      request.fields['Content'] = content.trim();
    }

    if (hashtags != null && hashtags.isNotEmpty) {
      for (int i = 0; i < hashtags.length; i++) {
        final cleanTag = hashtags[i].replaceAll('#', '').trim();
        if (cleanTag.isNotEmpty) {
          request.fields['Hashtags[$i]'] = cleanTag;
        }
      }
    }

    if (imageBytesList != null && imageBytesList.isNotEmpty) {
      for (int i = 0; i < imageBytesList.length; i++) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'Images',
            imageBytesList[i],
            filename: 'updated_post_$i.jpg',
          ),
        );
      }
    }

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Update post failed: $body');
    }

    if (body.isEmpty) {
      return getPostDetail(postId);
    }

    final decoded = jsonDecode(body);

    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];

      if (data is Map<String, dynamic>) {
        return PostFeedModel.fromJson(data);
      }

      return PostFeedModel.fromJson(decoded);
    }

    return getPostDetail(postId);
  }

  Future<void> deletePost(int postId) async {
    final endpoint = ApiConstants.deletePost.replaceAll(
      '{postId}',
      postId.toString(),
    );

    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final response = await ApiClient.delete(uri);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Delete post failed: ${response.body}');
    }
  }

  Future<bool> savePost(int postId) async {
    final endpoint = ApiConstants.toggleSavePost.replaceAll(
      '{postId}',
      postId.toString(),
    );

    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final response = await ApiClient.post(uri);

    if (response.statusCode != 200) {
      throw Exception('Save post failed: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'];

    if (data is Map<String, dynamic>) {
      return data['isSaved'] == true;
    }

    return decoded['isSaved'] == true;
  }

  Future<bool> unsavePost(int postId) async {
    final endpoint = ApiConstants.toggleSavePost.replaceAll(
      '{postId}',
      postId.toString(),
    );

    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final response = await ApiClient.delete(uri);

    if (response.statusCode != 200) {
      throw Exception('Unsave post failed: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'];

    if (data is Map<String, dynamic>) {
      return data['isSaved'] == true;
    }

    return decoded['isSaved'] == true;
  }

  Future<PagedPostsResponse> fetchSavedPosts({
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
      throw Exception('Failed to load saved posts: ${response.body}');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected saved posts response');
    }

    final root = decoded['data'] is Map<String, dynamic>
        ? decoded['data'] as Map<String, dynamic>
        : decoded;

    return PagedPostsResponse.fromJson(root);
  }

  Future<List<ShareableUserModel>> getShareableUsers() async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.getShareableUsersEndpoint}',
    );

    final response = await ApiClient.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load shareable users: ${response.body}');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is List) {
      return decoded
          .map((e) => ShareableUserModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];

      if (data is List) {
        return data
            .map((e) => ShareableUserModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      final items = (decoded['items'] as List?) ?? const [];

      return items
          .map((e) => ShareableUserModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception('Unexpected shareable users response');
  }

  Future<void> sharePostToChat({
    required int postId,
    required List<int> receiverAccountIds,
    String? caption,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.sharePostToChatEndpoint}',
    );

    final body = <String, dynamic>{
      'postId': postId,
      'receiverAccountIds': receiverAccountIds,
      'caption': caption?.trim().isNotEmpty == true ? caption!.trim() : null,
    };

    final response = await ApiClient.post(uri, body: body);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Share post to chat failed: ${response.body}');
    }
  }

  Future<List<HashtagSuggestionModel>> fetchHashtagSuggestions({
    String? query,
    int limit = 8,
  }) async {
    final Map<String, String> queryParams = {
      'limit': limit.toString(),
    };

    if (query != null && query.trim().isNotEmpty) {
      queryParams['query'] = query.trim();
    }

    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.hashtagSuggestions}',
    ).replace(queryParameters: queryParams);

    final response = await ApiClient.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load hashtag suggestions: ${response.body}');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is List) {
      return decoded.map((e) => HashtagSuggestionModel.fromJson(e)).toList();
    }

    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is List) {
        return data.map((e) => HashtagSuggestionModel.fromJson(e)).toList();
      }
      final items = (decoded['items'] as List?) ?? (decoded['data']?['items'] as List?) ?? const [];
      return items.map((e) => HashtagSuggestionModel.fromJson(e)).toList();
    }

    throw Exception('Unexpected hashtag suggestions response');
  }

  Future<List<TrendingHashtagModel>> fetchTrendingHashtags({
    int limit = 10,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.trendingHashtags}',
    ).replace(queryParameters: {
      'limit': limit.toString(),
    });

    final response = await ApiClient.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load trending hashtags: ${response.body}');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is List) {
      return decoded.map((e) => TrendingHashtagModel.fromJson(e)).toList();
    }

    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is List) {
        return data.map((e) => TrendingHashtagModel.fromJson(e)).toList();
      }
      final items = (decoded['items'] as List?) ?? (decoded['data']?['items'] as List?) ?? const [];
      return items.map((e) => TrendingHashtagModel.fromJson(e)).toList();
    }

    throw Exception('Unexpected trending hashtags response');
  }

  // 2. Lấy luồng bài viết được gắn tag tương ứng (Hỗ trợ phân trang bằng cursor tương tự fetchFeed)
  Future<List<PostFeedModel>> fetchPostsByHashtag({
    required String tagName,
    DateTime? cursor,
    int pageSize = 10,
  }) async {
    final endpoint = ApiConstants.getPostsByHashtag.replaceAll(
      '{tagName}',
      Uri.encodeComponent(tagName.replaceAll('#', '').trim()),
    );

    final query = {
      'pageSize': pageSize.toString(),
      if (cursor != null) 'cursor': cursor.toIso8601String(),
    };

    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint').replace(queryParameters: query);
    final response = await ApiClient.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load posts by hashtag: ${response.body}');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is List) {
      return decoded.map((e) => PostFeedModel.fromJson(e)).toList();
    }

    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is List) {
        return data.map((e) => PostFeedModel.fromJson(e)).toList();
      }
      if (data is Map<String, dynamic>) {
        final items = (data['items'] as List?) ?? const [];
        return items.map((e) => PostFeedModel.fromJson(e)).toList();
      }
      final items = (decoded['items'] as List?) ?? const [];
      return items.map((e) => PostFeedModel.fromJson(e)).toList();
    }

    throw Exception('Unexpected posts by hashtag response');
  }
}