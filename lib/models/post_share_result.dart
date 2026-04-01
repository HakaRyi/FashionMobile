// lib/models/post_share_result.dart
class PostShareResult {
  final int postId;
  final int shareCount;
  final String? message;

  const PostShareResult({
    required this.postId,
    required this.shareCount,
    this.message,
  });

  factory PostShareResult.fromJson(Map<String, dynamic> json) {
    return PostShareResult(
      postId: json['postId'] as int? ?? 0,
      shareCount: json['shareCount'] as int? ?? 0,
      message: json['message'] as String?,
    );
  }
}