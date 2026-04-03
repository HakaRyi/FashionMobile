import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../models/order_model.dart';
import 'api_client.dart';

class OrderService {
  Future<OrderModel> getOrderById(int orderId) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/orders/$orderId');

    final response = await ApiClient.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return OrderModel.fromJson(data);
    } else {
      throw Exception('Lỗi tải dữ liệu đơn hàng: ${response.statusCode}');
    }
  }

  Future<OrderModel> createOrder(Map<String, dynamic> requestBody) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/orders');

    final response = await ApiClient.post(url, body: requestBody);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return OrderModel.fromJson(data);
    } else {
      throw Exception('Lỗi tạo đơn: ${response.body}');
    }
  }

  Future<List<OrderModel>> getSalesOrders() async {
    final url = Uri.parse('${ApiConstants.baseUrl}/orders/sales');

    final response = await ApiClient.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => OrderModel.fromJson(json)).toList();
    } else {
      throw Exception('Lỗi tải danh sách đơn bán');
    }
  }

  Future<List<OrderModel>> getPurchasesOrders() async {
    final url = Uri.parse('${ApiConstants.baseUrl}/orders/purchases');

    final response = await ApiClient.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => OrderModel.fromJson(json)).toList();
    } else {
      throw Exception('Lỗi tải danh sách đơn mua');
    }
  }

  Future<OrderModel> updateOrderStatus(int orderId, String status) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/orders/$orderId/status');

    final response = await ApiClient.put(url, body: {"status": status});

    if (response.statusCode == 200) {
      return OrderModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Lỗi cập nhật trạng thái: ${jsonDecode(response.body)['message'] ?? response.statusCode}');
    }
  }

  Future<OrderModel> payOrder(int orderId) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/orders/$orderId/pay');

    final response = await ApiClient.post(url);

    if (response.statusCode == 200) {
      return OrderModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Lỗi thanh toán: ${jsonDecode(response.body)['message'] ?? response.statusCode}');
    }
  }
}