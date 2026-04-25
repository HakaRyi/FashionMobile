import 'item_variant_model.dart';

class PublicItemDetailModel {
  final int itemId;
  final int wardrobeId;
  final int accountId;
  final int? ownerId;

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

  final bool isForSale;
  final double? listedPrice;
  final String? condition;
  final List<ItemVariantModel> variants;

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
    required this.isForSale,
    required this.listedPrice,
    required this.condition,
    required this.variants,
    this.ownerId,
  });

  factory PublicItemDetailModel.fromJson(Map<String, dynamic> json) {
    final variantList = (json['variants'] as List<dynamic>? ?? [])
        .map((e) => ItemVariantModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return PublicItemDetailModel(
      itemId: int.tryParse(json['itemId'].toString()) ?? 0,
      wardrobeId: int.tryParse(json['wardrobeId'].toString()) ?? 0,
      accountId: int.tryParse(json['accountId'].toString()) ?? 0,
      ownerId: _parseNullableInt(
        json['ownerId'] ??
            json['ownerAccountId'] ??
            json['sellerId'] ??
            json['accountId'],
      ),
      itemName: json['itemName']?.toString(),
      itemType: json['itemType']?.toString(),
      category: json['category']?.toString(),
      subCategory: json['subCategory']?.toString(),
      style: json['style']?.toString(),
      gender: json['gender']?.toString(),
      mainColor: json['mainColor']?.toString(),
      subColor: json['subColor']?.toString(),
      material: json['material']?.toString(),
      pattern: json['pattern']?.toString(),
      fit: json['fit']?.toString(),
      neckline: json['neckline']?.toString(),
      sleeveLength: json['sleeveLength']?.toString(),
      length: json['length']?.toString(),
      size: json['size']?.toString(),
      brand: json['brand']?.toString(),
      description: json['description']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      imageUrls: (json['imageUrls'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .where((url) => url.trim().isNotEmpty)
          .toList(),
      ownerUserName: json['ownerUserName']?.toString(),
      ownerAvatarUrl: json['ownerAvatarUrl']?.toString(),
      isForSale: json['isForSale'] == true,
      listedPrice: json['listedPrice'] != null
          ? double.tryParse(json['listedPrice'].toString())
          : null,
      condition: json['condition']?.toString(),
      variants: variantList,
    );
  }

  String? get firstImageUrl {
    if (imageUrls.isEmpty) {
      return null;
    }

    return imageUrls.first;
  }

  static int? _parseNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }

    return int.tryParse(value.toString());
  }
}