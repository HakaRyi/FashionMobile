import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/order_service.dart';

class OrderManager {
  final OrderService _service = OrderService();

  Future<bool> submitRefundRequest(BuildContext context, int orderId, String reason, File image1, File image2) async {
    try {
      final bytes1 = await image1.readAsBytes();
      final String base64Image1 = "data:image/jpeg;base64,${base64Encode(bytes1)}";

      final bytes2 = await image2.readAsBytes();
      final String base64Image2 = "data:image/jpeg;base64,${base64Encode(bytes2)}";

      final success = await _service.createRefundRequest(orderId, reason, base64Image1, base64Image2);

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gửi yêu cầu trả hàng thành công')),
        );
        return true;
      }
      return false;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi gửi yêu cầu: $e')),
        );
      }
      return false;
    }
  }
}