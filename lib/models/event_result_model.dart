// Model cho Leaderboard (Bảng xếp hạng chung)
class EventLeaderboardModel {
  final int rank;
  final int accountId;
  final String userName;
  final String? avatarUrl;
  final double finalScore;
  final int postId;

  EventLeaderboardModel({
    required this.rank,
    required this.accountId,
    required this.userName,
    this.avatarUrl,
    required this.finalScore,
    required this.postId,
  });

  factory EventLeaderboardModel.fromJson(Map<String, dynamic> json) {
    return EventLeaderboardModel(
      rank: json['rank'],
      accountId: json['accountId'],
      userName: json['userName'],
      avatarUrl: json['avatarUrl'],
      finalScore: (json['finalScore'] as num).toDouble(),
      postId: json['postId'],
    );
  }
}

// Model cho My Result (Kết quả chi tiết cá nhân)
class MyEventResultModel {
  final int rank;
  final double myScore;
  final String? myPostImageUrl;
  final List<ExpertReviewModel> expertReviews;

  MyEventResultModel({
    required this.rank,
    required this.myScore,
    this.myPostImageUrl,
    required this.expertReviews,
  });

  factory MyEventResultModel.fromJson(Map<String, dynamic> json) {
    return MyEventResultModel(
      rank: json['rank'],
      myScore: (json['myScore'] as num).toDouble(),
      myPostImageUrl: json['myPostImageUrl'],
      expertReviews: (json['expertReviews'] as List)
          .map((e) => ExpertReviewModel.fromJson(e))
          .toList(),
    );
  }
}

class ExpertReviewModel {
  final String expertName;
  final String? expertAvatar;
  final double score;
  final String? reason;

  ExpertReviewModel({
    required this.expertName,
    this.expertAvatar,
    required this.score,
    this.reason,
  });

  factory ExpertReviewModel.fromJson(Map<String, dynamic> json) {
    return ExpertReviewModel(
      expertName: json['expertName'],
      expertAvatar: json['expertAvatar'],
      score: (json['score'] as num).toDouble(),
      reason: json['reason'],
    );
  }
}