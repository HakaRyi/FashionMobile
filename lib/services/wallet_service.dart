// lib/services/wallet_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/api_constants.dart';

class WalletService {
  Future<double> getMyWalletBalance() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/wallets/me'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
        "ngrok-skip-browser-warning": "69420",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['balance'] ?? 0).toDouble();
    }
    throw Exception('Failed to load wallet');
  }
}