import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';
import '../core/api_exception.dart';
import '../models/order_model.dart';
import 'api_client.dart';

class OrderService {
  ApiException _buildApiException(
      int statusCode,
      String responseBody,
      String fallbackMessage,
      ) {
    try {
      final data = jsonDecode(responseBody);

      if (data is Map<String, dynamic>) {
        final message = data['message']?.toString();

        if (message != null && message.trim().isNotEmpty) {
          return ApiException(
            message,
            statusCode: statusCode,
          );
        }

        final error = data['error']?.toString();

        if (error != null && error.trim().isNotEmpty) {
          return ApiException(
            error,
            statusCode: statusCode,
          );
        }

        final title = data['title']?.toString();

        if (title != null && title.trim().isNotEmpty) {
          return ApiException(
            title,
            statusCode: statusCode,
          );
        }
      }

      if (data is String && data.trim().isNotEmpty) {
        return ApiException(
          data,
          statusCode: statusCode,
        );
      }
    } catch (_) {
      if (responseBody.trim().isNotEmpty) {
        return ApiException(
          responseBody,
          statusCode: statusCode,
        );
      }
    }

    return ApiException(
      fallbackMessage,
      statusCode: statusCode,
    );
  }

  dynamic _decodeJson(String responseBody) {
    try {
      return jsonDecode(responseBody);
    } catch (_) {
      throw ApiException('Invalid server response.');
    }
  }

  Future<Map<String, String>> _buildMultipartHeaders() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token') ??
        prefs.getString('accessToken') ??
        prefs.getString('jwt') ??
        '';

    final headers = <String, String>{
      'ngrok-skip-browser-warning': '69420',
    };

    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<OrderModel> getOrderById(int orderId) async {
    final url = Uri.parse(
      ApiConstants.baseUrl + ApiConstants.getOrderById(orderId),
    );

    final response = await ApiClient.get(url);

    if (response.statusCode == 200) {
      return OrderModel.fromJson(_decodeJson(response.body));
    }

    throw _buildApiException(
      response.statusCode,
      response.body,
      'Failed to load order.',
    );
  }

  Future<OrderModel> createOrder(
      int sellerId,
      Map<String, dynamic> body,
      ) async {
    final url = Uri.parse(
      ApiConstants.baseUrl + ApiConstants.createOrder(sellerId),
    );

    final response = await ApiClient.post(
      url,
      body: body,
    );

    if (response.statusCode == 200) {
      return OrderModel.fromJson(_decodeJson(response.body));
    }

    throw _buildApiException(
      response.statusCode,
      response.body,
      'Create order failed.',
    );
  }

  Future<List<OrderModel>> getSalesOrders() async {
    final url = Uri.parse(
      ApiConstants.baseUrl + ApiConstants.getMySales,
    );

    final response = await ApiClient.get(url);

    if (response.statusCode == 200) {
      final data = _decodeJson(response.body);

      if (data is! List) {
        throw ApiException('Invalid sales order data.');
      }

      return data
          .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    throw _buildApiException(
      response.statusCode,
      response.body,
      'Load sales orders failed.',
    );
  }

  Future<List<OrderModel>> getPurchasesOrders() async {
    final url = Uri.parse(
      ApiConstants.baseUrl + ApiConstants.getMyPurchases,
    );

    final response = await ApiClient.get(url);

    if (response.statusCode == 200) {
      final data = _decodeJson(response.body);

      if (data is! List) {
        throw ApiException('Invalid purchase order data.');
      }

      return data
          .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    throw _buildApiException(
      response.statusCode,
      response.body,
      'Load purchase orders failed.',
    );
  }

  Future<OrderModel> updateOrderStatus(
      int orderId,
      String status,
      ) async {
    final url = Uri.parse(
      ApiConstants.baseUrl + ApiConstants.updateOrderStatus(orderId, status),
    );

    final response = await ApiClient.put(url);

    if (response.statusCode == 200) {
      return OrderModel.fromJson(_decodeJson(response.body));
    }

    throw _buildApiException(
      response.statusCode,
      response.body,
      'Update order status failed.',
    );
  }

  Future<OrderModel> payOrder(int orderId) async {
    final url = Uri.parse(
      ApiConstants.baseUrl + ApiConstants.payOrder(orderId),
    );

    final response = await ApiClient.post(url);

    if (response.statusCode == 200) {
      return OrderModel.fromJson(_decodeJson(response.body));
    }

    throw _buildApiException(
      response.statusCode,
      response.body,
      'Payment failed.',
    );
  }

  Future<OrderModel> createRefundRequest({
    required int orderId,
    required String reason,
    required File proofImage1,
    File? proofImage2,
  }) async {
    final url = Uri.parse(
      ApiConstants.baseUrl + ApiConstants.createRefund(orderId),
    );

    final request = http.MultipartRequest('POST', url);

    request.headers.addAll(await _buildMultipartHeaders());

    request.fields['Reason'] = reason;

    request.files.add(
      await http.MultipartFile.fromPath(
        'ProofImage1',
        proofImage1.path,
        filename: path.basename(proofImage1.path),
      ),
    );

    if (proofImage2 != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'ProofImage2',
          proofImage2.path,
          filename: path.basename(proofImage2.path),
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return OrderModel.fromJson(_decodeJson(response.body));
    }

    throw _buildApiException(
      response.statusCode,
      response.body,
      'Refund request failed.',
    );
  }

  Future<List<dynamic>> getMyRefunds() async {
    final url = Uri.parse(
      ApiConstants.baseUrl + ApiConstants.getMyRefunds,
    );

    final response = await ApiClient.get(url);

    if (response.statusCode == 200) {
      final data = _decodeJson(response.body);

      if (data is! List) {
        throw ApiException('Invalid refund data.');
      }

      return data;
    }

    throw _buildApiException(
      response.statusCode,
      response.body,
      'Load refund failed.',
    );
  }
}