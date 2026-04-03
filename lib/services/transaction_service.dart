import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/api_constants.dart';
import '../models/transaction_model.dart';
import 'api_client.dart';

class TransactionService {
  Future<List<TransactionModel>> fetchTransactions() async {
    final url = Uri.parse('${ApiConstants.baseUrl}/transaction');

    try {
      final response = await ApiClient.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => TransactionModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load transactions: ${response.statusCode}');
      }
    } catch (e) {
      print("Lỗi fetchTransactions: $e");
      return [];
    }
  }
}