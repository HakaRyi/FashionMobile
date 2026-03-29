import 'package:intl/intl.dart';
import 'account_model.dart';
import 'order_detail_model.dart';

class OrderModel {
  final int orderId;
  final int buyerId;
  final int sellerId;
  final double subTotal;
  final double serviceFee;
  final double totalAmount;
  final String status;
  final String? note;
  final String? shippingAddress;
  final String? receiverName;
  final String? receiverPhone;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final AccountModel? buyer;
  final AccountModel? seller;
  final List<OrderDetailModel> orderDetails;

  OrderModel({
    required this.orderId,
    required this.buyerId,
    required this.sellerId,
    required this.subTotal,
    required this.serviceFee,
    required this.totalAmount,
    required this.status,
    this.note,
    this.shippingAddress,
    this.receiverName,
    this.receiverPhone,
    required this.createdAt,
    this.updatedAt,
    this.buyer,
    this.seller,
    required this.orderDetails,
  });

  String get displayItemName {
    if (orderDetails.isEmpty) return 'Đơn hàng';
    if (orderDetails.length == 1) return orderDetails.first.itemName;
    return '${orderDetails.first.itemName} và ${orderDetails.length - 1} sản phẩm khác';
  }

  String get firstItemImage {
    if (orderDetails.isNotEmpty) {
      return orderDetails.first.itemImage;
    }
    return '';
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDateSafe(dynamic dateValue) {
      if (dateValue == null) return null;
      String dateStr = dateValue.toString();
      if (!dateStr.endsWith('Z')) {
        dateStr += 'Z';
      }
      return DateTime.parse(dateStr).toLocal();
    }

    return OrderModel(
      orderId: json['orderId'] ?? 0,
      buyerId: json['buyerId'] ?? 0,
      sellerId: json['sellerId'] ?? 0,
      subTotal: (json['subTotal'] ?? 0).toDouble(),
      serviceFee: (json['serviceFee'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      status: json['status'] ?? 'PENDING',
      note: json['note'],
      shippingAddress: json['shippingAddress'],
      receiverName: json['receiverName'],
      receiverPhone: json['receiverPhone'],
      createdAt: parseDateSafe(json['createdAt']) ?? DateTime.now(),
      updatedAt: parseDateSafe(json['updatedAt']),
      buyer: json['buyer'] != null ? AccountModel.fromJson(json['buyer']) : AccountModel(accountId: json['buyerId'] ?? 0, name: json['buyerName'] ?? 'Người mua'),
      seller: json['seller'] != null ? AccountModel.fromJson(json['seller']) : AccountModel(accountId: json['sellerId'] ?? 0, name: json['sellerName'] ?? 'Người bán'),
      orderDetails: (json['orderDetails'] as List?)?.map((e) => OrderDetailModel.fromJson(e)).toList() ?? [],
    );
  }

  String get formattedTotalAmount {
    return NumberFormat.decimalPattern('vi_VN').format(totalAmount);
  }

  String get formattedCreatedAt {
    return DateFormat('dd/MM/yyyy HH:mm').format(createdAt);
  }

  String get formattedUpdatedAt {
    if (updatedAt == null) return '--';
    return DateFormat('dd/MM/yyyy HH:mm').format(updatedAt!);
  }
}