// lib/utils/payment_manager.dart
import 'package:fashion_mobile/services/payment_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

import '../screens/vnpay_webview_screen.dart';

class PaymentManager {
  final PaymentService _service = PaymentService();

  Future<void> processPayment(double amount) async {
    final url = await _service.createTopUpVnPay(amount);

    if (url == null || url.isEmpty) {
      throw Exception("Không tạo được giao dịch VNPAY");
    }

    final uri = Uri.parse(url);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.inAppBrowserView,
      );
      if (!launched) {
        throw Exception("Không thể mở trang thanh toán");
      }
      print("Result: $launched");
    } catch (e) {
      print("ERROR: $e");
    }
  }
  // Future<void> processPayment(BuildContext context, double amount) async {
  //   final url = await _service.createTopUpVnPay(amount);
  //
  //   if (url == null || url.isEmpty) {
  //     throw Exception("Không tạo được giao dịch VNPAY");
  //   }
  //
  //   if (!context.mounted) return;
  //
  //   final resultUrl = await Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => VnPayWebViewScreen(url: url),
  //     ),
  //   );
  //
  //   if (resultUrl != null) {
  //     print("Kết quả giao dịch: $resultUrl");
  //   }
  }