import 'dart:io';

import '../models/order_model.dart';
import '../services/order_service.dart';

class OrderManager {
  final OrderService _service = OrderService();

  List<OrderModel> sales = [];
  List<OrderModel> purchases = [];

  Future<void> loadAll() async {
    final results = await Future.wait([
      _service.getSalesOrders(),
      _service.getPurchasesOrders(),
    ]);

    sales = results[0].items;
    purchases = results[1].items;
  }

  Future<void> refreshSales() async {
    final result = await _service.getSalesOrders();
    sales = result.items;
  }

  Future<void> refreshPurchases() async {
    final result = await _service.getPurchasesOrders();
    purchases = result.items;
  }

  Future<OrderModel> getOrderById(int orderId) async {
    return await _service.getOrderById(orderId);
  }

  Future<OrderModel> createOrder(
      int sellerId,
      Map<String, dynamic> body,
      ) async {
    final order = await _service.createOrder(
      sellerId,
      body,
    );

    await refreshPurchases();

    return order;
  }

  Future<OrderModel> pay(int orderId) async {
    final order = await _service.payOrder(orderId);
    await refreshPurchases();

    return order;
  }

  Future<OrderModel> updateStatus(
      int orderId,
      String status,
      ) async {
    final order = await _service.updateOrderStatus(
      orderId,
      status,
    );

    await loadAll();

    return order;
  }

  Future<OrderModel> confirmReceived(int orderId) async {
    final order = await _service.updateOrderStatus(
      orderId,
      'COMPLETED',
    );

    await refreshPurchases();

    return order;
  }

  Future<OrderModel> markAsShipping(int orderId) async {
    final order = await _service.updateOrderStatus(
      orderId,
      'SHIPPING',
    );

    await refreshSales();

    return order;
  }

  Future<OrderModel> cancel(int orderId) async {
    final order = await _service.updateOrderStatus(
      orderId,
      'CANCELLED',
    );

    await loadAll();

    return order;
  }

  Future<void> refund(
      int orderId,
      String reason,
      File proofImage1,
      File? proofImage2,
      ) async {
    await _service.createRefundRequest(
      orderId: orderId,
      reason: reason,
      proofImage1: proofImage1,
      proofImage2: proofImage2,
    );

    await refreshPurchases();
  }

  Future<List<dynamic>> getMyRefunds() async {
    return await _service.getMyRefunds();
  }

  Future<OrderModel> confirmReturnReceived(int orderId) async {
    final order = await _service.confirmReturnReceived(orderId);
    await refreshSales();
    return order;
  }
}