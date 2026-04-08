// lib/models/try_on_history_model.dart
class TryOnHistoryModel {
  final int id;
  final String imageUrl;
  final String status;
  final DateTime createdAt;

  TryOnHistoryModel({
    required this.id,
    required this.imageUrl,
    required this.status,
    required this.createdAt,
  });

  factory TryOnHistoryModel.fromJson(Map<String, dynamic> json) {
    return TryOnHistoryModel(
      id: json["tryOnId"],
      imageUrl: json["imageUrl"] ?? "",
      status: json["status"] ?? "",
      createdAt: DateTime.parse(json["createdAt"]),
    );
  }
}