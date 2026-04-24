class PublishItemRequestModel {
  final double listedPrice;
  final String? condition;
  final List<PublishItemVariantRequestModel> variants;

  PublishItemRequestModel({
    required this.listedPrice,
    this.condition,
    required this.variants,
  });

  Map<String, dynamic> toJson() {
    return {
      'listedPrice': listedPrice,
      'condition': condition,
      'variants': variants.map((variant) => variant.toJson()).toList(),
    };
  }
}

class PublishItemVariantRequestModel {
  final String sku;
  final String? sizeCode;
  final String? color;
  final double price;
  final int stockQuantity;

  PublishItemVariantRequestModel({
    required this.sku,
    this.sizeCode,
    this.color,
    required this.price,
    required this.stockQuantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'sku': sku,
      'sizeCode': sizeCode,
      'color': color,
      'price': price,
      'stockQuantity': stockQuantity,
    };
  }
}