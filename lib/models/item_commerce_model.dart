import 'item_variant_model.dart';

class ItemCommerceModel {
  final int itemId;
  final String? itemName;
  final bool isForSale;
  final double? listedPrice;
  final String? condition;
  final DateTime? publishedAt;
  final List<ItemVariantModel> variants;

  ItemCommerceModel({
    required this.itemId,
    required this.itemName,
    required this.isForSale,
    required this.listedPrice,
    required this.condition,
    required this.publishedAt,
    required this.variants,
  });

  factory ItemCommerceModel.fromJson(Map<String, dynamic> json) {
    final variantList = (json['variants'] as List<dynamic>? ?? [])
        .map((e) => ItemVariantModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return ItemCommerceModel(
      itemId: int.tryParse(json['itemId'].toString()) ?? 0,
      itemName: json['itemName']?.toString(),
      isForSale: json['isForSale'] == true,
      listedPrice: json['listedPrice'] != null
          ? double.tryParse(json['listedPrice'].toString())
          : null,
      condition: json['condition']?.toString(),
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'].toString())
          : null,
      variants: variantList,
    );
  }
}