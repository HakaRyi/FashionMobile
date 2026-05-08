// lib/services/comment_service.dart
import 'dart:convert';

import '../constants/api_constants.dart';
import '../models/comment_model.dart';
import '../models/comment_replies_response.dart';
import '../models/create_reply_result.dart';
import '../models/paged_comments_response.dart';
import 'api_client.dart';

class CommentService {
  /// ==========================
  /// GET COMMENTS (paged)
  /// ==========================
  Future<PagedCommentsResponse> getComments(
      int postId, {
        int skip = 0,
        int take = 20,
      }) async {
    final endpoint =
    ApiConstants.getComments.replaceFirst("{postId}", postId.toString());

    final uri = Uri.parse("${ApiConstants.baseUrl}$endpoint").replace(
      queryParameters: {
        'skip': '$skip',
        'take': '$take',
      },
    );

    final response = await ApiClient.get(uri);

    if (response.statusCode != 200) {
      throw Exception("Failed to fetch comments");
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return PagedCommentsResponse.fromJson(data);
  }

  /// ==========================
  /// CREATE COMMENT
  /// ==========================
  Future<CommentModel> createComment({
    required int postId,
    required String content,
  }) async {
    final endpoint =
    ApiConstants.createComment.replaceFirst("{postId}", postId.toString());

    final uri = Uri.parse("${ApiConstants.baseUrl}$endpoint");

    final response = await ApiClient.post(
      uri,
      body: {"content": content},
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Create comment failed");
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return CommentModel.fromJson(data);
  }

  /// ==========================
  /// GET REPLIES (paged)
  /// ==========================
  Future<CommentRepliesResponse> getReplies(
      int commentId, {
        int skip = 0,
        int take = 20,
      }) async {
    final endpoint =
    ApiConstants.getReplies.replaceFirst("{commentId}", commentId.toString());

    final uri = Uri.parse("${ApiConstants.baseUrl}$endpoint").replace(
      queryParameters: {
        'skip': '$skip',
        'take': '$take',
      },
    );

    final response = await ApiClient.get(uri);

    if (response.statusCode != 200) {
      throw Exception("Failed to fetch replies");
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return CommentRepliesResponse.fromJson(data);
  }

  /// ==========================
  /// REPLY COMMENT
  /// ==========================
  Future<CreateReplyResult> replyComment(
      int commentId,
      String content,
      ) async {
    final endpoint = ApiConstants.replyComment
        .replaceFirst("{commentId}", commentId.toString());

    final uri = Uri.parse("${ApiConstants.baseUrl}$endpoint");

    final response = await ApiClient.post(
      uri,
      body: {"content": content},
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Reply comment failed");
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return CreateReplyResult.fromJson(data);
  }

  /// ==========================
  /// UPDATE COMMENT / REPLY
  /// ==========================
  Future<void> updateComment({
    required int commentId,
    required String content,
  }) async {
    final endpoint = ApiConstants.updateComment
        .replaceFirst("{commentId}", commentId.toString());

    final uri = Uri.parse("${ApiConstants.baseUrl}$endpoint");

    final response = await ApiClient.put(
      uri,
      body: {
        "content": content,
      },
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception("Update comment failed");
    }
  }

  /// ==========================
  /// DELETE COMMENT / REPLY
  /// ==========================
  Future<void> deleteComment(int commentId) async {
    final endpoint = ApiConstants.deleteComment
        .replaceFirst("{commentId}", commentId.toString());

    final uri = Uri.parse("${ApiConstants.baseUrl}$endpoint");

    final response = await ApiClient.delete(uri);

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception("Delete comment failed");
    }
  }
}