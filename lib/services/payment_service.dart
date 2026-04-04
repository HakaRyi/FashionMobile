// lib/services/payment_service.dart
import 'dart:convert';

import 'package:fashion_mobile/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PaymentService {
  Future<String?> createTopUpVnPay(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.topUpWallet}'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
        "ngrok-skip-browser-warning": "69420",
      },
      body: jsonEncode({
        "amount": amount,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["data"]?["paymentUrl"];
    }

    throw Exception('Error: ${response.statusCode} - ${response.body}');
  }

  Future<Map<String, dynamic>> createTopUpZaloPay(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.topUpWalletZaloPay}'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
        "ngrok-skip-browser-warning": "69420",
      },
      body: jsonEncode({
        "amount": amount,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["data"] ?? {};
    }

    throw Exception('Error: ${response.statusCode} - ${response.body}');
  }
}