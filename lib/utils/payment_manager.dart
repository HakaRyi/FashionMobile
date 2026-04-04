// // lib/utils/payment_manager.dart
// import 'package:url_launcher/url_launcher.dart';
//
// import 'package:fashion_mobile/services/payment_service.dart';
//
//
// class PaymentManager {
//   final PaymentService _service = PaymentService();
//
//   Future<void> processPayment(double amount) async {
//     final url = await _service.createOrder(amount);
//
//     if (url != null) {
//       final Uri uri = Uri.parse(url);
//
//       bool canLaunch = await canLaunchUrl(uri);
//
//       if (canLaunch) {
//         await launchUrl(
//           uri,
//           mode: LaunchMode.externalApplication,
//         );
//       } else {
//         throw Exception("Không thể tìm thấy trình duyệt để mở cổng thanh toán");
//       }
//     } else {
//       throw Exception("Không tạo được đơn hàng VNPay");
//     }
//   }
// }