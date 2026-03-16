// lib/services/reaction_service.dart
import 'dart:convert';

import '../constants/api_constants.dart';
import '../models/comment_reaction_result.dart';
import '../models/post_reaction_result.dart';
import 'api_client.dart';

class ReactionService {
  /// ==========================
  /// TOGGLE POST LIKE
  /// ==========================
  Future<PostReactionResult> togglePostLike(int postId) async {
    final endpoint =
    ApiConstants.togglePostLike.replaceFirst("{postId}", postId.toString());

    final uri = Uri.parse("${ApiConstants.baseUrl}$endpoint");

    final response = await ApiClient.post(uri);

    if (response.statusCode != 200) {
      throw Exception("Toggle like failed");
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    return PostReactionResult.fromJson(data);
  }

  /// ==========================
  /// TOGGLE COMMENT LIKE
  /// ==========================
  Future<CommentReactionResult> toggleCommentLike(int commentId) async {
    final endpoint = ApiConstants.toggleCommentLike
        .replaceFirst("{commentId}", commentId.toString());

    final uri = Uri.parse("${ApiConstants.baseUrl}$endpoint");

    final response = await ApiClient.post(uri);

    if (response.statusCode != 200) {
      throw Exception("Toggle comment like failed");
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    return CommentReactionResult.fromJson(data);
  }
}