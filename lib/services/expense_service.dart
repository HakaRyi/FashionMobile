import 'dart:convert';

import '../constants/api_constants.dart';
import '../models/cashflow_point_model.dart';
import '../models/expense_by_reference_type_model.dart';
import '../models/expense_summary_model.dart';
import '../models/transaction_detail_model.dart';
import '../models/transaction_history_model.dart';
import 'api_client.dart';

class ExpenseService {
  Uri _buildUri(String path, [Map<String, dynamic>? queryParams]) {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');

    if (queryParams == null || queryParams.isEmpty) {
      return uri;
    }

    return uri.replace(
      queryParameters: queryParams.map(
            (key, value) => MapEntry(key, value?.toString()),
      ),
    );
  }

  Future<Map<String, dynamic>> getMyTransactions({
    int page = 1,
    int pageSize = 20,
    String? type,
    String? referenceType,
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
    double? minAmount,
    double? maxAmount,
    String? keyword,
  }) async {
    final uri = _buildUri('/expenses/me/transactions', {
      'page': page,
      'pageSize': pageSize,
      if (type != null && type.isNotEmpty) 'type': type,
      if (referenceType != null && referenceType.isNotEmpty)
        'referenceType': referenceType,
      if (status != null && status.isNotEmpty) 'status': status,
      if (fromDate != null) 'fromDate': fromDate.toIso8601String(),
      if (toDate != null) 'toDate': toDate.toIso8601String(),
      if (minAmount != null) 'minAmount': minAmount,
      if (maxAmount != null) 'maxAmount': maxAmount,
      if (keyword != null && keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
    });

    final response = await ApiClient.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Không thể tải danh sách giao dịch. Mã lỗi: ${response.statusCode}');
    }

    final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
    final itemsJson = (jsonData['items'] as List<dynamic>? ?? []);

    return {
      'items': itemsJson
          .map((e) => TransactionHistoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      'page': jsonData['page'] ?? 1,
      'pageSize': jsonData['pageSize'] ?? 20,
      'totalCount': jsonData['totalCount'] ?? 0,
      'hasMore': jsonData['hasMore'] ?? false,
    };
  }

  Future<TransactionDetailModel> getTransactionDetail(int transactionId) async {
    final uri = _buildUri('/expenses/me/transactions/$transactionId');

    final response = await ApiClient.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Không thể tải chi tiết giao dịch. Mã lỗi: ${response.statusCode}');
    }

    final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
    return TransactionDetailModel.fromJson(jsonData);
  }

  Future<ExpenseSummaryModel> getExpenseSummary({
    required int month,
    required int year,
  }) async {
    final uri = _buildUri('/expenses/me/expense-summary', {
      'month': month,
      'year': year,
    });

    final response = await ApiClient.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Không thể tải thống kê chi tiêu. Mã lỗi: ${response.statusCode}');
    }

    final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
    return ExpenseSummaryModel.fromJson(jsonData);
  }

  Future<List<ExpenseByReferenceTypeModel>> getExpenseByReferenceType({
    required int month,
    required int year,
    String type = 'Debit',
  }) async {
    final uri = _buildUri('/expenses/me/expense-by-reference-type', {
      'month': month,
      'year': year,
      'type': type,
    });

    final response = await ApiClient.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Không thể tải thống kê theo loại. Mã lỗi: ${response.statusCode}');
    }

    final jsonData = jsonDecode(response.body) as List<dynamic>;

    return jsonData
        .map((e) => ExpenseByReferenceTypeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CashflowPointModel>> getCashflow({
    required DateTime fromDate,
    required DateTime toDate,
    String groupBy = 'day',
  }) async {
    final uri = _buildUri('/expenses/me/cashflow', {
      'fromDate': fromDate.toIso8601String(),
      'toDate': toDate.toIso8601String(),
      'groupBy': groupBy,
    });

    final response = await ApiClient.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Không thể tải cashflow. Mã lỗi: ${response.statusCode}');
    }

    final jsonData = jsonDecode(response.body) as List<dynamic>;

    return jsonData
        .map((e) => CashflowPointModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}