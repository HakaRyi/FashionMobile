import 'order_detail_model.dart';
import 'status_history_model.dart';

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

  final List<OrderDetailModel> orderDetails;
  final List<StatusHistoryModel> statusHistories;

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
    required this.orderDetails,
    this.statusHistories = const [],
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
      orderDetails: (json['orderDetails'] as List<dynamic>? ?? [])
          .map((e) => OrderDetailModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      statusHistories: (json['statusHistories'] as List<dynamic>? ?? [])
          .map((e) => StatusHistoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  // ─── History lookup ──────────────────────────────────────────────────────────

  DateTime? getStatusTime(String status) {
    final s = status.toUpperCase();
    final matches = statusHistories
        .where((h) => h.status.toUpperCase() == s)
        .toList()
      ..sort((a, b) => a.changedAt.compareTo(b.changedAt));
    return matches.isEmpty ? null : matches.first.changedAt;
  }

  DateTime? get paidAtFromHistory      => getStatusTime('PROCESSING');
  DateTime? get shippingAtFromHistory  => getStatusTime('SHIPPING');
  DateTime? get deliveredAtFromHistory => getStatusTime('DELIVERED');
  DateTime? get completedAtFromHistory => getStatusTime('COMPLETED');
  DateTime? get cancelledAtFromHistory => getStatusTime('CANCELLED');
  DateTime? get refundingAtFromHistory => getStatusTime('REFUNDING');

  // ─── Display ─────────────────────────────────────────────────────────────────

  String get displayItemName =>
      orderDetails.isNotEmpty ? orderDetails.first.itemName : 'Unknown';

  String get firstItemImage =>
      orderDetails.isNotEmpty ? orderDetails.first.imageUrl ?? '' : '';

  // ─── Status booleans ─────────────────────────────────────────────────────────

  bool get isPendingPayment  => status.toLowerCase() == 'pendingpayment';
  bool get isProcessing      => status.toLowerCase() == 'processing';
  bool get isShipping        => status.toLowerCase() == 'shipping';
  bool get isDelivered       => status.toLowerCase() == 'delivered';
  bool get isCompleted       => status.toLowerCase() == 'completed';
  bool get isDone            => status.toLowerCase() == 'done';
  bool get isCancelled       => status.toLowerCase() == 'cancelled';
  bool get isRefunding       => status.toLowerCase() == 'refunding';
  bool get isRefunded        => status.toLowerCase() == 'refunded';
  bool get isReturnApproved  => status.toLowerCase() == 'returnapproved';
  bool get isReturnPickedUp  => status.toLowerCase() == 'returnpickedup';
  bool get isReturnShipping  => status.toLowerCase() == 'returnshipping';
  bool get isReturnDelivered => status.toLowerCase() == 'returndelivered';
  bool get isReturnCompleted => status.toLowerCase() == 'returncompleted';

  bool get isAnyRefundState {
    final s = status.toLowerCase();
    return s == 'refunding'       ||
        s == 'refunded'        ||
        s == 'returnapproved'  ||
        s == 'returnpickedup'  ||
        s == 'returnshipping'  ||
        s == 'returndelivered' ||
        s == 'returncompleted';
  }
}