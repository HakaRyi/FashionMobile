class WardrobeItemModel {
  final int itemId;
  final String itemName;
  final String? description;
  final String? mainColor;
  final String? brand;
  final String? status;
  final String? imageUrl;

  WardrobeItemModel({
    required this.itemId,
    required this.itemName,
    this.description,
    this.mainColor,
    this.brand,
    this.status,
    this.imageUrl,
  });

  factory WardrobeItemModel.fromJson(Map<String, dynamic> json) {
    return WardrobeItemModel(
      itemId: json['itemId'] ?? 0,
      itemName: json['itemName'] ?? 'Unknown Item',
      description: json['description'],
      mainColor: json['mainColor'],
      brand: json['brand'],
      status: json['status'],
      imageUrl: json['imageUrl'],
    );
  }
}