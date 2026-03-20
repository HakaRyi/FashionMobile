// lib/models/post_reaction_result.dart
class PostReactionResult {
  final bool isLiked;
  final int likeCount;

  PostReactionResult({
    required this.isLiked,
    required this.likeCount,
  });

  factory PostReactionResult.fromJson(Map<String, dynamic> json) {
    return PostReactionResult(
      isLiked: json['isLiked'],
      likeCount: json['likeCount'],
    );
  }
}