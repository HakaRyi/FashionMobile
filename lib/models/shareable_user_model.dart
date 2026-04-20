class ShareableUserModel {
  final int accountId;
  final String userName;
  final String? avatarUrl;
  final bool isFollower;
  final bool isFollowing;

  const ShareableUserModel({
    required this.accountId,
    required this.userName,
    this.avatarUrl,
    required this.isFollower,
    required this.isFollowing,
  });

  factory ShareableUserModel.fromJson(Map<String, dynamic> json) {
    return ShareableUserModel(
      accountId: json['accountId'] as int? ?? 0,
      userName: (json['userName'] ?? '').toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      isFollower: json['isFollower'] == true,
      isFollowing: json['isFollowing'] == true,
    );
  }
}