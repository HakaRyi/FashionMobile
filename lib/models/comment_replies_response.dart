// lib/models/comment_replies_response.dart
import 'comment_reply_model.dart';

class CommentRepliesResponse {
  final int parentCommentId;
  final int replyCount;
  final bool hasReplies;
  final List<CommentReplyModel> items;
  final int skip;
  final int take;
  final bool hasMore;

  const CommentRepliesResponse({
    required this.parentCommentId,
    required this.replyCount,
    required this.hasReplies,
    required this.items,
    required this.skip,
    required this.take,
    required this.hasMore,
  });

  factory CommentRepliesResponse.fromJson(Map<String, dynamic> json) {
    return CommentRepliesResponse(
      parentCommentId: json['parentCommentId'] ?? 0,
      replyCount: json['replyCount'] ?? 0,
      hasReplies: json['hasReplies'] ?? false,
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((e) => CommentReplyModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      skip: json['skip'] ?? 0,
      take: json['take'] ?? 20,
      hasMore: json['hasMore'] ?? false,
    );
  }
}