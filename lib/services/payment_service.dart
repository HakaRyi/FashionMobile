// lib/services/payment_service.dart
import 'dart:convert';
import 'package:fashion_mobile/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PaymentService {
  // Future<String?> createOrder(double amount) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final token = prefs.getString('token') ?? '';
  //
  //   final response = await http.post(
  //     Uri.parse(ApiConstants.baseUrl + ApiConstants.topUpWallet),
  //     headers: {
  //       "Content-Type": "application/json",
  //       "Authorization": "Bearer $token",
  //     },
  //     body: jsonEncode({
  //       "amount": amount,
  //     }),
  //   );
  //
  //   if (response.statusCode == 200) {
  //     final data = jsonDecode(response.body);
  //     return data["order_url"] ?? data["orderUrl"];
  //   }
  //
  //   print("Error: ${response.statusCode} - ${response.body}");
  //   return null;
  // }

  Future<String?> createOrder(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/payment/create-order-vnpay'),
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
      return data["order_url"];
    }

    throw Exception('Error: ${response.statusCode} - ${response.body}');
  }
}