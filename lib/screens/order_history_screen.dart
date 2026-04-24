import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import 'order_detail_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();

  late final TabController _tabController;

  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;

  List<OrderModel> _purchaseOrders = [];
  List<OrderModel> _salesOrders = [];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);
    _loadOrders(showFullLoading: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders({bool showFullLoading = false}) async {
    if (showFullLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else {
      setState(() {
        _isRefreshing = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait([
        _orderService.getPurchasesOrders(),
        _orderService.getSalesOrders(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _purchaseOrders = results[0];
        _salesOrders = results[1];
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = _normalizeError(e);
      });
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _refreshOrders() async {
    await _loadOrders(showFullLoading: false);
  }

  String _normalizeError(Object error) {
    final text = error.toString();

    if (text.startsWith('Exception: ')) {
      return text.replaceFirst('Exception: ', '').trim();
    }

    return text;
  }

  String _normalizeStatus(String status) {
    return status
        .toLowerCase()
        .trim()
        .replaceAll('_', '')
        .replaceAll('-', '')
        .replaceAll(' ', '');
  }

  String _formatPrice(double value) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return '${formatter.format(value)} VND';
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '';
    }

    return DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());
  }

  String _displayStatus(String status) {
    switch (_normalizeStatus(status)) {
      case 'pendingpayment':
        return 'Pending Payment';
      case 'processing':
        return 'Processing';
      case 'shipping':
        return 'Shipping';
      case 'delivered':
        return 'Delivered';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'refunding':
        return 'Refunding';
      case 'refunded':
        return 'Refunded';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (_normalizeStatus(status)) {
      case 'pendingpayment':
        return Colors.orange;
      case 'processing':
        return Colors.blueAccent;
      case 'shipping':
        return Colors.lightBlue;
      case 'delivered':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.redAccent;
      case 'refunding':
        return Colors.amber;
      case 'refunded':
        return Colors.cyan;
      default:
        return AppColors.textSecondary;
    }
  }

  Future<void> _openOrderDetail({
    required OrderModel order,
    required bool isPurchase,
  }) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(
          orderId: order.orderId,
          isPurchase: isPurchase,
        ),
      ),
    );

    if (result == true) {
      await _refreshOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.text),
        title: const Text(
          'Order History',
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _isRefreshing ? null : _refreshOrders,
            icon: _isRefreshing
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.textPink,
              ),
            )
                : const Icon(Icons.refresh),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.textPink,
          labelColor: AppColors.textPink,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(text: 'Purchases'),
            Tab(text: 'Sales'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: AppColors.textPink,
        ),
      )
          : _error != null
          ? _buildError()
          : TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList(
            orders: _purchaseOrders,
            isPurchase: true,
          ),
          _buildOrderList(
            orders: _salesOrders,
            isPurchase: false,
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.text,
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text(
              'Failed to load orders',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'An unexpected error occurred.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadOrders(showFullLoading: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textPink,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList({
    required List<OrderModel> orders,
    required bool isPurchase,
  }) {
    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshOrders,
        color: AppColors.textPink,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 160),
            Icon(
              isPurchase
                  ? Icons.shopping_bag_outlined
                  : Icons.storefront_outlined,
              color: AppColors.textSecondary,
              size: 68,
            ),
            const SizedBox(height: 14),
            Text(
              isPurchase
                  ? 'You have no purchase orders.'
                  : 'You have no sales orders.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshOrders,
      color: AppColors.textPink,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = orders[index];

          return _buildOrderCard(
            order: order,
            isPurchase: isPurchase,
          );
        },
      ),
    );
  }

  Widget _buildOrderCard({
    required OrderModel order,
    required bool isPurchase,
  }) {
    final firstDetail =
    order.orderDetails.isNotEmpty ? order.orderDetails.first : null;

    final itemCount = order.orderDetails.length;

    return InkWell(
      onTap: () {
        _openOrderDetail(
          order: order,
          isPurchase: isPurchase,
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderImage(firstDetail?.imageUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.orderCode,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    firstDetail?.itemName ?? 'Unknown item',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  if (itemCount > 1) ...[
                    const SizedBox(height: 3),
                    Text(
                      '+ ${itemCount - 1} more item(s)',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 7),
                  Text(
                    isPurchase
                        ? 'Seller: ${order.sellerName}'
                        : 'Buyer: ${order.buyerName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _formatPrice(order.totalAmount),
                    style: const TextStyle(
                      color: AppColors.textPink,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStatusChip(order.status),
                      const Spacer(),
                      if (order.createdAt != null)
                        Text(
                          _formatDate(order.createdAt),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return _buildImagePlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        imageUrl,
        width: 78,
        height: 78,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return _buildImagePlaceholder();
        },
        loadingBuilder: (context, child, progress) {
          if (progress == null) {
            return child;
          }

          return Container(
            width: 78,
            height: 78,
            color: AppColors.surface,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.textPink,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.checkroom_outlined,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        _displayStatus(status),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}