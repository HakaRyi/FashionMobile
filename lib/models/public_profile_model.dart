// lib/models/public_profile_model.dart
class PublicProfileModel {
  final int accountId;
  final String? userName;
  final String? description;
  final int countPost;
  final int countFollower;
  final int countFollowing;
  final String? avatarUrl;
  final int totalPublicItems;

  PublicProfileModel({
    required this.accountId,
    required this.userName,
    required this.description,
    required this.countPost,
    required this.countFollower,
    required this.countFollowing,
    required this.avatarUrl,
    required this.totalPublicItems,
  });

  factory PublicProfileModel.fromJson(Map<String, dynamic> json) {
    return PublicProfileModel(
      accountId: json['accountId'] ?? 0,
      userName: json['userName'],
      description: json['description'],
      countPost: json['countPost'] ?? 0,
      countFollower: json['countFollower'] ?? 0,
      countFollowing: json['countFollowing'] ?? 0,
      avatarUrl: json['avatarUrl'],
      totalPublicItems: json['totalPublicItems'] ?? 0,
    );
  }
}