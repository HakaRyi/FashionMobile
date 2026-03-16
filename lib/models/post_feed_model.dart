// lib/models/post_feed_model.dart
class PostFeedModel {
  final int postId;
  final int accountId;
  final String userName;
  final String? avatarUrl;
  final String? title;
  final String? content;
  final List<String> images;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final bool isLiked;
  final DateTime createdAt;
  final bool isSaved;
  List<String> get imageUrls => images;

  PostFeedModel({
    required this.postId,
    required this.accountId,
    required this.userName,
    this.avatarUrl,
    this.title,
    this.content,
    required this.images,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    required this.isSaved,
    required this.isLiked,
    required this.createdAt,
  });

  factory PostFeedModel.fromJson(Map<String, dynamic> json) {
    return PostFeedModel(
      postId: json['postId'],
      accountId: json['accountId'],
      userName: json['userName'],
      avatarUrl: json['avatarUrl'],
      title: json['title'],
      content: json['content'],
      images: List<String>.from(json['images'] ?? []),
      likeCount: json['likeCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      shareCount: json['shareCount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      isSaved: json['isSaved'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  PostFeedModel copyWith({
    int? postId,
    int? accountId,
    String? userName,
    String? avatarUrl,
    String? title,
    String? content,
    List<String>? images,
    int? likeCount,
    int? commentCount,
    int? shareCount,
    bool? isLiked,
    bool? isSaved,
    DateTime? createdAt,
  }) {
    return PostFeedModel(
      postId: postId ?? this.postId,
      accountId: accountId ?? this.accountId,
      userName: userName ?? this.userName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      title: title ?? this.title,
      content: content ?? this.content,
      images: images ?? this.images,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}