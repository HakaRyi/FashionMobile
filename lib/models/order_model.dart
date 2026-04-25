import 'order_detail_model.dart';

class OrderModel {
  final int orderId;
  final String orderCode;

  final int buyerId;
  final String buyerName;

  final int sellerId;
  final String sellerName;

  final double subTotal;
  final double serviceFee;
  final double totalAmount;

  final String status;
  final String? note;
  final String? cancelReason;
  final String? shippingAddress;
  final String? receiverName;
  final String? receiverPhone;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? paidAt;
  final DateTime? deliveredAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;

  final List<OrderDetailModel> orderDetails;

  OrderModel({
    required this.orderId,
    required this.orderCode,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.sellerName,
    required this.subTotal,
    required this.serviceFee,
    required this.totalAmount,
    required this.status,
    this.note,
    this.cancelReason,
    this.shippingAddress,
    this.receiverName,
    this.receiverPhone,
    this.createdAt,
    this.updatedAt,
    this.paidAt,
    this.deliveredAt,
    this.completedAt,
    this.cancelledAt,
    required this.orderDetails,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderId: _parseInt(json['orderId']),
      orderCode: json['orderCode']?.toString() ?? '',

      buyerId: _parseInt(json['buyerId']),
      buyerName: json['buyerName']?.toString() ?? 'Unknown',

      sellerId: _parseInt(json['sellerId']),
      sellerName: json['sellerName']?.toString() ?? 'Unknown',

      subTotal: _parseDouble(json['subTotal']),
      serviceFee: _parseDouble(json['serviceFee']),
      totalAmount: _parseDouble(json['totalAmount']),

      status: json['status']?.toString() ?? '',

      note: json['note']?.toString(),
      cancelReason: json['cancelReason']?.toString(),
      shippingAddress: json['shippingAddress']?.toString(),
      receiverName: json['receiverName']?.toString(),
      receiverPhone: json['receiverPhone']?.toString(),

      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      paidAt: _parseDate(json['paidAt']),
      deliveredAt: _parseDate(json['deliveredAt']),
      completedAt: _parseDate(json['completedAt']),
      cancelledAt: _parseDate(json['cancelledAt']),

      orderDetails: (json['orderDetails'] as List<dynamic>? ?? [])
          .map((e) => OrderDetailModel.fromJson(e as Map<String, dynamic>))
          .toList(),
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

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }

  String get displayItemName {
    return orderDetails.isNotEmpty ? orderDetails.first.itemName : 'Unknown';
  }

  String get firstItemImage {
    return orderDetails.isNotEmpty ? orderDetails.first.imageUrl ?? '' : '';
  }

  bool get isPendingPayment => status.toLowerCase() == 'pendingpayment';

  bool get isProcessing => status.toLowerCase() == 'processing';

  bool get isShipping => status.toLowerCase() == 'shipping';

  bool get isDelivered => status.toLowerCase() == 'delivered';

  bool get isCompleted => status.toLowerCase() == 'completed';

  bool get isDone => status.toLowerCase() == 'done';

  bool get isCancelled => status.toLowerCase() == 'cancelled';

  bool get isRefunding => status.toLowerCase() == 'refunding';

  bool get isRefunded => status.toLowerCase() == 'refunded';
}