// lib/models/comment_model.dart
import 'comment_reply_model.dart';

class CommentModel {
  final int commentId;
  final int postId;
  final int accountId;
  final String userName;
  final String? avatarUrl;
  final String content;
  final int likeCount;
  final bool isLiked;
  final DateTime createdAt;
  final int? parentCommentId;

  final int replyCount;
  final bool hasReplies;

  final List<CommentReplyModel> replies;

  const CommentModel({
    required this.commentId,
    required this.postId,
    required this.accountId,
    required this.userName,
    this.avatarUrl,
    required this.content,
    required this.likeCount,
    required this.isLiked,
    required this.createdAt,
    required this.parentCommentId,
    required this.replyCount,
    required this.hasReplies,
    required this.replies,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      commentId: json['commentId'] ?? 0,
      postId: json['postId'] ?? 0,
      accountId: json['accountId'] ?? 0,
      userName: json['userName'] ?? '',
      avatarUrl: (json['avatarUrl'] == '' ? null : json['avatarUrl']) as String?,
      content: json['content'] ?? '',
      likeCount: json['likeCount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      parentCommentId: json['parentCommentId'],
      replyCount: json['replyCount'] ?? 0,
      hasReplies: json['hasReplies'] ?? false,
      replies: (json['replies'] as List<dynamic>? ?? const [])
          .map((e) => CommentReplyModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  CommentModel copyWith({
    int? commentId,
    int? postId,
    int? accountId,
    String? userName,
    String? avatarUrl,
    String? content,
    int? likeCount,
    bool? isLiked,
    DateTime? createdAt,
    int? parentCommentId,
    int? replyCount,
    bool? hasReplies,
    List<CommentReplyModel>? replies,
  }) {
    return CommentModel(
      commentId: commentId ?? this.commentId,
      postId: postId ?? this.postId,
      accountId: accountId ?? this.accountId,
      userName: userName ?? this.userName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      content: content ?? this.content,
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt ?? this.createdAt,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      replyCount: replyCount ?? this.replyCount,
      hasReplies: hasReplies ?? this.hasReplies,
      replies: replies ?? this.replies,
    );
  }
}