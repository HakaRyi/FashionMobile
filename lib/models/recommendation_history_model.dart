class RecommendationHistoryModel {
  final int id;
  final String prompt;
  final DateTime createdAt;
  final int? referenceItemId;
  final String? referenceItemName;
  final String? referenceItemImage;

  RecommendationHistoryModel({
    required this.id,
    required this.prompt,
    required this.createdAt,
    this.referenceItemId,
    this.referenceItemName,
    this.referenceItemImage,
  });

  factory RecommendationHistoryModel.fromJson(Map<String, dynamic> json) {
    return RecommendationHistoryModel(
      id: json['id'],
      prompt: json['prompt'] ?? "",
      createdAt: DateTime.parse(json['createdAt']),
      referenceItemId: json['referenceItemId'],
      referenceItemName: json['referenceItemName'],
      referenceItemImage: json['referenceItemImage'],
    );
  }
}