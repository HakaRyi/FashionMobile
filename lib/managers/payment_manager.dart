// lib/utils/payment_manager.dart
import 'package:fashion_mobile/services/payment_service.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentManager {
  final PaymentService _service = PaymentService();

  Future<void> processPayment(double amount) async {
    final url = await _service.createTopUpVnPay(amount);

    if (url == null || url.isEmpty) {
      throw Exception("Không tạo được giao dịch VNPAY");
    }

    final uri = Uri.parse(url);

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.inAppBrowserView,
    );

    if (!launched) {
      throw Exception("Không thể mở trang thanh toán");
    }
  }
}