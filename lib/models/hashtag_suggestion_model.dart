class HashtagSuggestionModel {
  final int hashtagId;
  final String name;
  final int usageCount;
  final bool isTrending;

  HashtagSuggestionModel({
    required this.hashtagId,
    required this.name,
    required this.usageCount,
    required this.isTrending,
  });

  factory HashtagSuggestionModel.fromJson(Map<String, dynamic> json) {
    return HashtagSuggestionModel(
      hashtagId: json['hashtagId'] ?? 0,
      name: json['name'] ?? '',
      usageCount: json['usageCount'] ?? 0,
      isTrending: json['isTrending'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hashtagId': hashtagId,
      'name': name,
      'usageCount': usageCount,
      'isTrending': isTrending,
    };
  }
}