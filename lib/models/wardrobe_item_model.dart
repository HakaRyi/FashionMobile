// lib/models/wardrobe_item_model.dart
class WardrobeItemModel {
  final int itemId;
  final String itemName;
  final String? description;
  final String? mainColor;
  final String? brand;
  final String? status;
  final String? imageUrl;
  final bool isSaved;
  final bool isOwner;
  final String? category;

  WardrobeItemModel({
    required this.itemId,
    required this.itemName,
    this.description,
    this.mainColor,
    this.brand,
    this.status,
    this.imageUrl,
    this.isSaved = false,
    this.isOwner = false,
    this.category,
  });

  factory WardrobeItemModel.fromJson(Map<String, dynamic> json) {
    try {
      return WardrobeItemModel(
        itemId: json['itemId'] ?? 0,
        itemName: json['itemName'] ?? '',
        description: json['description'],
        mainColor: json['mainColor'],
        brand: json['brand'],
        status: json['status']?.toString(),
        imageUrl: json['thumbnailUrl'] ?? json['imageUrl'],
        isSaved: json['isSaved'] ?? false,
        isOwner: json['isOwner'] ?? false,
        category: json['category'],
      );
    } catch (e) {
      print("❌ LỖI TẠI WardrobeItemModel: $e | Dữ liệu gây lỗi: $json");
      rethrow;
    }
  }
  WardrobeItemModel copyWith({bool? isSaved}) {
    return WardrobeItemModel(
      itemId: this.itemId,
      itemName: this.itemName,
      imageUrl: this.imageUrl,
      category: this.category,
      isSaved: isSaved ?? this.isSaved,
      isOwner: this.isOwner,
    );
  }
}