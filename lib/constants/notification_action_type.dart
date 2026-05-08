class NotificationActionType {
  static const String orderCreated = 'OrderCreated';
  static const String orderPaid = 'OrderPaid';
  static const String orderShipping = 'OrderShipping';
  static const String orderDelivered = 'OrderDelivered';
  static const String orderCompleted = 'OrderCompleted';
  static const String orderCancelled = 'OrderCancelled';

  static const String refundRequested = 'RefundRequested';
  static const String refundApproved = 'RefundApproved';
  static const String refundRejected = 'RefundRejected';

  static bool isOrderType(String? type) {
    return type == orderCreated ||
        type == orderPaid ||
        type == orderShipping ||
        type == orderDelivered ||
        type == orderCompleted ||
        type == orderCancelled ||
        type == refundRequested ||
        type == refundApproved ||
        type == refundRejected;
  }
}