class WardrobeItemModel {
  final int itemId;
  final String itemName;
  final String? description;
  final String? mainColor;
  final String? brand;
  final String? status;
  final String? imageUrl;
  final String? size;
  final bool isSaved;
  final bool isOwner;
  final String? category;

  final bool isForSale;
  final double? listedPrice;
  final String? condition;

  WardrobeItemModel({
    required this.itemId,
    required this.itemName,
    this.description,
    this.mainColor,
    this.brand,
    this.status,
    this.imageUrl,
    this.size,
    this.isSaved = false,
    this.isOwner = false,
    this.category,
    required this.isForSale,
    required this.listedPrice,
    required this.condition,
  });

  factory WardrobeItemModel.fromJson(Map<String, dynamic> json) {
    return WardrobeItemModel(
      itemId: int.tryParse(json['itemId'].toString()) ?? 0,
      itemName: json['itemName']?.toString() ?? '',
      description: json['description']?.toString(),
      mainColor: json['mainColor']?.toString(),
      brand: json['brand']?.toString(),
      status: json['status']?.toString(),
      imageUrl: json['thumbnailUrl']?.toString() ?? json['imageUrl']?.toString(),
      size: json['size']?.toString(),
      isSaved: json['isSaved'] == true,
      isOwner: json['isOwner'] == true,
      category: json['category']?.toString(),
      isForSale: json['isForSale'] == true,
      listedPrice: json['listedPrice'] != null
          ? double.tryParse(json['listedPrice'].toString())
          : null,
      condition: json['condition']?.toString(),
    );
  }

  String? get thumbnailUrl => imageUrl;

  WardrobeItemModel copyWith({
    int? itemId,
    String? itemName,
    String? description,
    String? mainColor,
    String? brand,
    String? status,
    String? imageUrl,
    String? size,
    bool? isSaved,
    bool? isOwner,
    String? category,
    bool? isForSale,
    double? listedPrice,
    String? condition,
  }) {
    return WardrobeItemModel(
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      description: description ?? this.description,
      mainColor: mainColor ?? this.mainColor,
      brand: brand ?? this.brand,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      size: size ?? this.size,
      isSaved: isSaved ?? this.isSaved,
      isOwner: isOwner ?? this.isOwner,
      category: category ?? this.category,
      isForSale: isForSale ?? this.isForSale,
      listedPrice: listedPrice ?? this.listedPrice,
      condition: condition ?? this.condition,
    );
  }
}