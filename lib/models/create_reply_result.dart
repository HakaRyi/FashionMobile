// lib/models/create_reply_result.dart
import 'comment_reply_model.dart';

class CreateReplyResult {
  final CommentReplyModel reply;
  final int parentCommentId;
  final int replyCount;
  final bool hasReplies;

  const CreateReplyResult({
    required this.reply,
    required this.parentCommentId,
    required this.replyCount,
    required this.hasReplies,
  });

  factory CreateReplyResult.fromJson(Map<String, dynamic> json) {
    return CreateReplyResult(
      reply: CommentReplyModel.fromJson(
        Map<String, dynamic>.from(json['reply'] as Map),
      ),
      parentCommentId: json['parentCommentId'] ?? 0,
      replyCount: json['replyCount'] ?? 0,
      hasReplies: json['hasReplies'] ?? false,
    );
  }
}