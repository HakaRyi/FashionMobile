class PostFeedModel {
  final int postId;
  final int accountId;
  final String userName;
  final String? avatarUrl;
  final String? title;
  final String? content;
  final List<String> images;
  final List<String> hashtags;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final bool isLiked;
  final bool isSaved;
  final DateTime createdAt;
  final String? status;
  final String? visibility;
  final bool isEvent;
  final String? eventName;
  final bool isExpertPost;
  final bool isLikedByExpert;

  List<String> get imageUrls => images;

  PostFeedModel({
    required this.postId,
    required this.accountId,
    required this.userName,
    this.avatarUrl,
    this.title,
    this.content,
    required this.images,
    this.hashtags = const [],
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    required this.isLiked,
    required this.isSaved,
    required this.createdAt,
    this.status,
    this.visibility,
    required this.isEvent,
    this.eventName,
    required this.isExpertPost,
    required this.isLikedByExpert,
  });

  factory PostFeedModel.fromJson(Map<String, dynamic> json) {
    return PostFeedModel(
      postId: json['postId'] ?? 0,
      accountId: json['accountId'] ?? 0,
      userName: json['userName'] ?? '',
      avatarUrl: json['avatarUrl'],
      title: json['title'],
      content: json['content'],
      images: List<String>.from(json['images'] ?? const []),
      hashtags: (json['hashtags'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],

      likeCount: json['likeCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      shareCount: json['shareCount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      isSaved: json['isSaved'] ?? false,
      createdAt: DateTime.tryParse(
        json['createdAt']?.toString() ?? '',
      ) ??
          DateTime.now(),
      status: json['status'],
      visibility: json['visibility'],
      isEvent: json['isEvent'] ?? false,
      eventName: json['eventName'],
      isExpertPost: json['isExpertPost'] ?? false,
      isLikedByExpert: json['isLikedByExpert'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'postId': postId,
      'accountId': accountId,
      'userName': userName,
      'avatarUrl': avatarUrl,
      'title': title,
      'content': content,
      'images': images,
      'hashtags': hashtags,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'shareCount': shareCount,
      'isLiked': isLiked,
      'isSaved': isSaved,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'visibility': visibility,
      'isEvent': isEvent,
      'eventName': eventName,
      'isExpertPost': isExpertPost,
      'isLikedByExpert': isLikedByExpert,
    };
  }

  PostFeedModel copyWith({
    int? postId,
    int? accountId,
    String? userName,
    String? avatarUrl,
    String? title,
    String? content,
    List<String>? images,
    List<String>? hashtags,
    int? likeCount,
    int? commentCount,
    int? shareCount,
    bool? isLiked,
    bool? isSaved,
    DateTime? createdAt,
    String? status,
    String? visibility,
    bool? isEvent,
    String? eventName,
    bool? isExpertPost,
    bool? isLikedByExpert,
  }) {
    return PostFeedModel(
      postId: postId ?? this.postId,
      accountId: accountId ?? this.accountId,
      userName: userName ?? this.userName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      title: title ?? this.title,
      content: content ?? this.content,
      images: images ?? this.images,
      hashtags: hashtags ?? this.hashtags,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      visibility: visibility ?? this.visibility,
      isEvent: isEvent ?? this.isEvent,
      eventName: eventName ?? this.eventName,
      isExpertPost: isExpertPost ?? this.isExpertPost,
      isLikedByExpert: isLikedByExpert ?? this.isLikedByExpert,
    );
  }
}