class MyPostModel {
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
  final bool isSaved;
  final DateTime createdAt;

  final String? status;
  final String visibility;
  final bool isOwner;
  final bool canEdit;
  final bool canDelete;
  final bool canHide;
  final bool canUnhide;
  final bool isPubliclyVisible;

  List<String> get imageUrls => images;

  MyPostModel({
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
    required this.isLiked,
    required this.isSaved,
    required this.createdAt,
    required this.status,
    required this.visibility,
    required this.isOwner,
    required this.canEdit,
    required this.canDelete,
    required this.canHide,
    required this.canUnhide,
    required this.isPubliclyVisible,
  });

  factory MyPostModel.fromJson(Map<String, dynamic> json) {
    return MyPostModel(
      postId: json['postId'],
      accountId: json['accountId'],
      userName: json['userName'] ?? '',
      avatarUrl: json['avatarUrl'],
      title: json['title'],
      content: json['content'],
      images: List<String>.from(json['images'] ?? const []),
      likeCount: json['likeCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      shareCount: json['shareCount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      isSaved: json['isSaved'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      status: json['status'],
      visibility: json['visibility'] ?? 'Visible',
      isOwner: json['isOwner'] ?? true,
      canEdit: json['canEdit'] ?? false,
      canDelete: json['canDelete'] ?? false,
      canHide: json['canHide'] ?? false,
      canUnhide: json['canUnhide'] ?? false,
      isPubliclyVisible: json['isPubliclyVisible'] ?? false,
    );
  }

  MyPostModel copyWith({
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
    String? status,
    String? visibility,
    bool? isOwner,
    bool? canEdit,
    bool? canDelete,
    bool? canHide,
    bool? canUnhide,
    bool? isPubliclyVisible,
  }) {
    return MyPostModel(
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
      status: status ?? this.status,
      visibility: visibility ?? this.visibility,
      isOwner: isOwner ?? this.isOwner,
      canEdit: canEdit ?? this.canEdit,
      canDelete: canDelete ?? this.canDelete,
      canHide: canHide ?? this.canHide,
      canUnhide: canUnhide ?? this.canUnhide,
      isPubliclyVisible: isPubliclyVisible ?? this.isPubliclyVisible,
    );
  }
}