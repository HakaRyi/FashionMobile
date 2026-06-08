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

  String get _normalizedStatus =>
      status.toLowerCase().replaceAll('_', '').replaceAll('-', '');

  bool get isPendingPayment  => _normalizedStatus == 'pendingpayment';
  bool get isProcessing      => _normalizedStatus == 'processing';
  bool get isShipping        => _normalizedStatus == 'shipping';
  bool get isDelivered       => _normalizedStatus == 'delivered';
  bool get isCompleted       => _normalizedStatus == 'completed';
  bool get isDone            => _normalizedStatus == 'done';
  bool get isCancelled       => _normalizedStatus == 'cancelled';
  bool get isRefunding       => _normalizedStatus == 'refunding';
  bool get isRefunded        => _normalizedStatus == 'refunded';
  bool get isReturnApproved  => _normalizedStatus == 'returnapproved';
  bool get isReturnPickedUp  => _normalizedStatus == 'returnpickedup';
  bool get isReturnShipping  => _normalizedStatus == 'returnshipping';
  bool get isReturnDelivered => _normalizedStatus == 'returndelivered';
  bool get isReturnCompleted => _normalizedStatus == 'returncompleted';

  bool get isAnyRefundState {
    final s = _normalizedStatus;
    return s == 'refunding'      ||
        s == 'refunded'       ||
        s == 'returnapproved' ||
        s == 'returnpickedup' ||
        s == 'returnshipping' ||
        s == 'returndelivered'||
        s == 'returncompleted';
  }
}