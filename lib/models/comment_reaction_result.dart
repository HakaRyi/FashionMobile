// lib/models/comment_reaction_result.dart
class CommentReactionResult {
  final int commentId;
  final bool isLiked;
  final int likeCount;

  CommentReactionResult({
    required this.commentId,
    required this.isLiked,
    required this.likeCount,
  });

  factory CommentReactionResult.fromJson(Map<String, dynamic> json) {
    return CommentReactionResult(
      commentId: json['commentId'],
      isLiked: json['isLiked'],
      likeCount: json['likeCount'],
    );
  }
}