// lib/models/public_item_detail_model.dart
class PublicItemDetailModel {
  final int itemId;
  final int wardrobeId;
  final int accountId;

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
  final String? neckline;
  final String? sleeveLength;
  final String? length;
  final String? size;
  final String? brand;
  final String? description;
  final DateTime? createdAt;

  final List<String> imageUrls;

  final String? ownerUserName;
  final String? ownerAvatarUrl;

  const PublicItemDetailModel({
    required this.itemId,
    required this.wardrobeId,
    required this.accountId,
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
    required this.neckline,
    required this.sleeveLength,
    required this.length,
    required this.size,
    required this.brand,
    required this.description,
    required this.createdAt,
    required this.imageUrls,
    required this.ownerUserName,
    required this.ownerAvatarUrl,
  });

  factory PublicItemDetailModel.fromJson(Map<String, dynamic> json) {
    return PublicItemDetailModel(
      itemId: json['itemId'] ?? 0,
      wardrobeId: json['wardrobeId'] ?? 0,
      accountId: json['accountId'] ?? 0,
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
      neckline: json['neckline'],
      sleeveLength: json['sleeveLength'],
      length: json['length'],
      size: json['size'],
      brand: json['brand'],
      description: json['description'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      imageUrls: (json['imageUrls'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      ownerUserName: json['ownerUserName'],
      ownerAvatarUrl: json['ownerAvatarUrl'],
    );
  }

  String? get firstImageUrl {
    if (imageUrls.isEmpty) return null;
    return imageUrls.first;
  }
}