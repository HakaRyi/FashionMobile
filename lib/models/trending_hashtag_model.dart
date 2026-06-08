class TrendingHashtagModel {
  final int? hashtagId;
  final String? keyword;
  final int? score;
  final int? totalPosts;
  final int? totalEngagement;
  final DateTime? calculatedAt;

  TrendingHashtagModel({
    this.hashtagId,
    this.keyword,
    this.score,
    this.totalPosts,
    this.totalEngagement,
    this.calculatedAt,
  });

  factory TrendingHashtagModel.fromJson(Map<String, dynamic> json) {
    return TrendingHashtagModel(
      hashtagId: json['hashtagId'] as int?,
      keyword: json['keyword'] as String?,
      score: json['score'] as int?,
      totalPosts: json['totalPosts'] as int?,
      totalEngagement: json['totalEngagement'] as int?,
      calculatedAt: json['calculatedAt'] != null
          ? DateTime.tryParse(json['calculatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hashtagId': hashtagId,
      'keyword': keyword,
      'score': score,
      'totalPosts': totalPosts,
      'totalEngagement': totalEngagement,
      'calculatedAt': calculatedAt?.toIso8601String(),
    };
  }
}