import 'package:url_launcher/url_launcher.dart';

import 'package:fashion_mobile/services/payment_service.dart';


class PaymentManager {
  final PaymentService _service = PaymentService();

  Future<void> processPayment(double amount) async {
    final url = await _service.createOrder(amount);

    if (url != null) {
      final Uri uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.inAppBrowserView,
        );
      } else {
        throw Exception("Không thể mở trang thanh toán");
      }
    } else {
      throw Exception("Không tạo được đơn hàng ZaloPay");
    }
  }
}