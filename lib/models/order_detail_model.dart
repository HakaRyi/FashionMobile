class OrderDetailModel {
  final int orderDetailId;
  final int orderId;
  final int itemId;
  final int? itemVariantId;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String itemName;
  final String? variantSnapshot;
  final String? skuSnapshot;
  final String? imageUrl;

  OrderDetailModel({
    required this.orderDetailId,
    required this.orderId,
    required this.itemId,
    this.itemVariantId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.itemName,
    this.variantSnapshot,
    this.skuSnapshot,
    this.imageUrl,
  });

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) {
    return OrderDetailModel(
      orderDetailId: _parseInt(json['orderDetailId']),
      orderId: _parseInt(json['orderId']),
      itemId: _parseInt(json['itemId']),
      itemVariantId: json['itemVariantId'] == null
          ? null
          : _parseInt(json['itemVariantId']),
      quantity: _parseInt(json['quantity']),
      unitPrice: _parseDouble(json['unitPrice']),
      totalPrice: _parseDouble(json['totalPrice']),
      itemName: json['itemName']?.toString() ?? 'Unknown Item',
      variantSnapshot: json['variantSnapshot']?.toString(),
      skuSnapshot: json['skuSnapshot']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }
}