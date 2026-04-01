// lib/models/public_wardrobe_item_model.dart
class PublicWardrobeItemModel {
  final int itemId;
  final String? itemName;
  final String? itemType;
  final String? category;
  final String? subCategory;
  final String? style;
  final String? gender;
  final String? mainColor;
  final String? subColor;
  final String? material;
  final String? pattern;
  final String? fit;
  final String? size;
  final String? brand;
  final String? description;
  final DateTime? createdAt;
  final String? thumbnailUrl;

  PublicWardrobeItemModel({
    required this.itemId,
    required this.itemName,
    required this.itemType,
    required this.category,
    required this.subCategory,
    required this.style,
    required this.gender,
    required this.mainColor,
    required this.subColor,
    required this.material,
    required this.pattern,
    required this.fit,
    required this.size,
    required this.brand,
    required this.description,
    required this.createdAt,
    required this.thumbnailUrl,
  });

  factory PublicWardrobeItemModel.fromJson(Map<String, dynamic> json) {
    return PublicWardrobeItemModel(
      itemId: json['itemId'] ?? 0,
      itemName: json['itemName'],
      itemType: json['itemType'],
      category: json['category'],
      subCategory: json['subCategory'],
      style: json['style'],
      gender: json['gender'],
      mainColor: json['mainColor'],
      subColor: json['subColor'],
      material: json['material'],
      pattern: json['pattern'],
      fit: json['fit'],
      size: json['size'],
      brand: json['brand'],
      description: json['description'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      thumbnailUrl: json['thumbnailUrl'],
    );
  }
}