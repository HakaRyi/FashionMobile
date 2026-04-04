// lib/constants/order_status_values.dart
class OrderStatusValues {
  static const String pendingPayment = 'PendingPayment';
  static const String processing = 'Processing';
  static const String shipping = 'Shipping';
  static const String completed = 'Completed';
  static const String cancelled = 'Cancelled';
  static const String refunded = 'Refunded';

  static const List<String> all = [
    pendingPayment,
    processing,
    shipping,
    completed,
    cancelled,
    refunded,
  ];

  static bool isValid(String? status) {
    return status != null && all.contains(status);
  }
}