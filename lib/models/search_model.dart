
class UserSuggestionModel {
  final int accountId;
  final String fullName;
  final String username;
  final String avatarUrl;
  final int followerCount;
  bool isFollowing;

  UserSuggestionModel({
    required this.accountId,
    required this.fullName,
    required this.username,
    required this.avatarUrl,
    required this.followerCount,
    required this.isFollowing,
  });

  factory UserSuggestionModel.fromJson(Map<String, dynamic> json) {
    return UserSuggestionModel(
      accountId: json['accountId'] ?? '',
      fullName: json['fullName']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString() ?? '',
      followerCount: int.tryParse(json['followerCount']?.toString() ?? '0') ?? 0,
      isFollowing: json['isFollowing'] ?? false,
    );
  }
}

class SearchHistoryModel {
  final int id;
  final String keyword;

  SearchHistoryModel({
    required this.id,
    required this.keyword,
  });

  factory SearchHistoryModel.fromJson(Map<String, dynamic> json) {
    return SearchHistoryModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      keyword: json['keyword']?.toString() ?? '',
    );
  }
}