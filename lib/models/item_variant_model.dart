class ItemVariantModel {
  final int itemVariantId;
  final int itemId;
  final String sku;
  final String? sizeCode;
  final String? color;
  final double price;
  final int stockQuantity;
  final int reservedQuantity;
  final int availableQuantity;
  final int status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ItemVariantModel({
    required this.itemVariantId,
    required this.itemId,
    required this.sku,
    required this.sizeCode,
    required this.color,
    required this.price,
    required this.stockQuantity,
    required this.reservedQuantity,
    required this.availableQuantity,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ItemVariantModel.fromJson(Map<String, dynamic> json) {
    final stockQuantity = int.tryParse(json['stockQuantity'].toString()) ?? 0;
    final reservedQuantity =
        int.tryParse(json['reservedQuantity'].toString()) ?? 0;

    return ItemVariantModel(
      itemVariantId: int.tryParse(json['itemVariantId'].toString()) ?? 0,
      itemId: int.tryParse(json['itemId'].toString()) ?? 0,
      sku: json['sku']?.toString() ?? '',
      sizeCode: json['sizeCode']?.toString(),
      color: json['color']?.toString(),
      price: json['price'] != null
          ? double.tryParse(json['price'].toString()) ?? 0
          : 0,
      stockQuantity: stockQuantity,
      reservedQuantity: reservedQuantity,
      availableQuantity: json['availableQuantity'] != null
          ? int.tryParse(json['availableQuantity'].toString()) ??
          (stockQuantity - reservedQuantity)
          : (stockQuantity - reservedQuantity),
      status: int.tryParse(json['status'].toString()) ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'sku': sku,
      'sizeCode': sizeCode,
      'color': color,
      'price': price,
      'stockQuantity': stockQuantity,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'sku': sku,
      'sizeCode': sizeCode,
      'color': color,
      'price': price,
      'stockQuantity': stockQuantity,
      'status': status,
    };
  }

  ItemVariantModel copyWith({
    int? itemVariantId,
    int? itemId,
    String? sku,
    String? sizeCode,
    String? color,
    double? price,
    int? stockQuantity,
    int? reservedQuantity,
    int? availableQuantity,
    int? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ItemVariantModel(
      itemVariantId: itemVariantId ?? this.itemVariantId,
      itemId: itemId ?? this.itemId,
      sku: sku ?? this.sku,
      sizeCode: sizeCode ?? this.sizeCode,
      color: color ?? this.color,
      price: price ?? this.price,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      reservedQuantity: reservedQuantity ?? this.reservedQuantity,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}