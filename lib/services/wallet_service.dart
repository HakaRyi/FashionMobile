// lib/services/wallet_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/api_constants.dart';
import 'api_client.dart';

class WalletService {
  Future<double> getMyWalletBalance() async {
    final url = Uri.parse('${ApiConstants.baseUrl}/wallets/me');

    try {
      final response = await ApiClient.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['balance'] ?? 0).toDouble();
      }

      throw Exception('Failed to load wallet: ${response.statusCode}');
    } catch (e) {
      print("Lỗi getMyWalletBalance: $e");
      rethrow;
    }
  }
}