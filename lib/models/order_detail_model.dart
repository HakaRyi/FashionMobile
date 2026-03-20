class OrderDetailModel {
  final int orderDetailId;
  final int orderId;
  final int? outfitId;
  final int? productId;
  final int quantity;
  final double unitPrice;
  final String itemName;
  final String itemImage;

  OrderDetailModel({
    required this.orderDetailId,
    required this.orderId,
    this.outfitId,
    this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.itemName,
    required this.itemImage,
  });

  double get totalPrice => unitPrice * quantity;

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) {
    return OrderDetailModel(
      orderDetailId: json['orderDetailId'] ?? 0,
      orderId: json['orderId'] ?? 0,
      outfitId: json['outfitId'],
      productId: json['productId'],
      quantity: json['quantity'] ?? 1,
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      itemName: json['itemName'] ?? 'Sản phẩm',
      itemImage: json['itemImage'] ?? '',
    );
  }
}