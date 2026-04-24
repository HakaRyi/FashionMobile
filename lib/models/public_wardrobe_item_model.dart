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

  final bool isForSale;
  final double? listedPrice;
  final String? condition;

  final bool? isSaved;
  final bool? isOwner;

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
    required this.isForSale,
    required this.listedPrice,
    required this.condition,
    this.isSaved,
    this.isOwner,
  });

  factory PublicWardrobeItemModel.fromJson(Map<String, dynamic> json) {
    return PublicWardrobeItemModel(
      itemId: int.tryParse(json['itemId'].toString()) ?? 0,
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
      size: json['size']?.toString(),
      brand: json['brand']?.toString(),
      description: json['description']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      isForSale: json['isForSale'] == true,
      listedPrice: json['listedPrice'] != null
          ? double.tryParse(json['listedPrice'].toString())
          : null,
      condition: json['condition']?.toString(),
      isSaved: json['isSaved'] == true,
      isOwner: json['isOwner'] == true,
    );
  }

  PublicWardrobeItemModel copyWith({
    bool? isSaved,
    bool? isOwner,
    bool? isForSale,
    double? listedPrice,
    String? condition,
  }) {
    return PublicWardrobeItemModel(
      itemId: itemId,
      itemName: itemName,
      itemType: itemType,
      category: category,
      subCategory: subCategory,
      style: style,
      gender: gender,
      mainColor: mainColor,
      subColor: subColor,
      material: material,
      pattern: pattern,
      fit: fit,
      size: size,
      brand: brand,
      description: description,
      createdAt: createdAt,
      thumbnailUrl: thumbnailUrl,
      isForSale: isForSale ?? this.isForSale,
      listedPrice: listedPrice ?? this.listedPrice,
      condition: condition ?? this.condition,
      isSaved: isSaved ?? this.isSaved,
      isOwner: isOwner ?? this.isOwner,
    );
  }
}