// lib/models/comment_reply_model.dart
class CommentReplyModel {
  final int commentId;
  final int accountId;
  final String userName;
  final String? avatarUrl;
  final String content;
  final int likeCount;
  final bool isLiked;
  final DateTime createdAt;
  final int parentCommentId;

  const CommentReplyModel({
    required this.commentId,
    required this.accountId,
    required this.userName,
    this.avatarUrl,
    required this.content,
    required this.likeCount,
    required this.isLiked,
    required this.createdAt,
    required this.parentCommentId,
  });

  factory CommentReplyModel.fromJson(Map<String, dynamic> json) {
    return CommentReplyModel(
      commentId: json['commentId'] ?? 0,
      accountId: json['accountId'] ?? 0,
      userName: json['userName'] ?? '',
      avatarUrl: (json['avatarUrl'] == '' ? null : json['avatarUrl']) as String?,
      content: json['content'] ?? '',
      likeCount: json['likeCount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      parentCommentId: json['parentCommentId'] ?? 0,
    );
  }

  CommentReplyModel copyWith({
    int? commentId,
    int? accountId,
    String? userName,
    String? avatarUrl,
    String? content,
    int? likeCount,
    bool? isLiked,
    DateTime? createdAt,
    int? parentCommentId,
  }) {
    return CommentReplyModel(
      commentId: commentId ?? this.commentId,
      accountId: accountId ?? this.accountId,
      userName: userName ?? this.userName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      content: content ?? this.content,
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt ?? this.createdAt,
      parentCommentId: parentCommentId ?? this.parentCommentId,
    );
  }
}