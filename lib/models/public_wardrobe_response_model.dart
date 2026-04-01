// lib/models/public_wardrobe_response_model.dart
import 'public_wardrobe_item_model.dart';

class PublicWardrobeResponseModel {
  final int accountId;
  final int wardrobeId;
  final int totalPublicItems;
  final List<PublicWardrobeItemModel> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final bool hasMore;

  PublicWardrobeResponseModel({
    required this.accountId,
    required this.wardrobeId,
    required this.totalPublicItems,
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.hasMore,
  });

  factory PublicWardrobeResponseModel.fromJson(Map<String, dynamic> json) {
    final itemsContainer = json['items'] as Map<String, dynamic>? ?? {};
    final rawItems = (itemsContainer['items'] as List?) ?? [];

    return PublicWardrobeResponseModel(
      accountId: json['accountId'] ?? 0,
      wardrobeId: json['wardrobeId'] ?? 0,
      totalPublicItems: json['totalPublicItems'] ?? 0,
      items: rawItems
          .map((e) => PublicWardrobeItemModel.fromJson(e))
          .toList()
          .cast<PublicWardrobeItemModel>(),
      page: itemsContainer['page'] ?? 1,
      pageSize: itemsContainer['pageSize'] ?? 12,
      totalCount: itemsContainer['totalCount'] ?? 0,
      hasMore: itemsContainer['hasMore'] ?? false,
    );
  }
}