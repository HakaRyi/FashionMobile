import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';
import '../models/order_detail_model.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../utils/app_toast.dart';
import 'refund_request_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  final bool isPurchase;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    required this.isPurchase,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final OrderService _orderService = OrderService();

  bool _isLoading = true;
  bool _isActionLoading = false;
  String? _error;
  OrderModel? _order;
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _loadOrder(showFullLoading: true);
  }

  Future<void> _loadOrder({bool showFullLoading = false}) async {
    if (showFullLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else {
      setState(() {
        _error = null;
      });
    }

    try {
      final result = await _orderService.getOrderById(widget.orderId);

      if (!mounted) {
        return;
      }

      setState(() {
        _order = result;
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
      });
    }
  }

  Future<void> _refreshOrder() async {
    await _loadOrder(showFullLoading: false);
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
      return 'N/A';
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

  Future<void> _runAction({
    required Future<OrderModel> Function() action,
    String successMessage = 'Order updated successfully.',
  }) async {
    setState(() {
      _isActionLoading = true;
    });

    try {
      final result = await action();

      if (!mounted) {
        return;
      }

      setState(() {
        _order = result;
        _hasChanged = true;
      });

      AppToast.show(context, successMessage);

      await _refreshOrder();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_normalizeError(e)),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _isActionLoading = false;
      });
    }
  }

  Future<void> _confirmAction({
    required String title,
    required String message,
    required Future<OrderModel> Function() action,
    String successMessage = 'Order updated successfully.',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textPink,
                foregroundColor: Colors.white,
              ),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _runAction(
        action: action,
        successMessage: successMessage,
      );
    }
  }

  Future<void> _openRefundScreen() async {
    final order = _order;

    if (order == null) {
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RefundRequestScreen(
          orderId: order.orderId,
        ),
      ),
    );

    if (result == true) {
      _hasChanged = true;
      await _refreshOrder();
    }
  }

  void _back() {
    Navigator.pop(context, _hasChanged);
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;

    return WillPopScope(
      onWillPop: () async {
        _back();
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.text),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: _back,
          ),
          title: const Text(
            'Order Detail',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: _isActionLoading ? null : _refreshOrder,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
          child: CircularProgressIndicator(
            color: AppColors.textPink,
          ),
        )
            : _error != null
            ? _buildError()
            : order == null
            ? _buildEmpty()
            : RefreshIndicator(
          onRefresh: _refreshOrder,
          color: AppColors.textPink,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _buildHeader(order),
              const SizedBox(height: 14),
              _buildItemsSection(order),
              const SizedBox(height: 14),
              _buildReceiverSection(order),
              const SizedBox(height: 14),
              _buildPriceSection(order),
              const SizedBox(height: 14),
              _buildTimelineSection(order),
              const SizedBox(height: 22),
              _buildActionButtons(order),
            ],
          ),
        ),
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
              'Failed to load order detail',
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.bold,
                fontSize: 16,
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
              onPressed: () => _loadOrder(showFullLoading: true),
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

  Widget _buildEmpty() {
    return const Center(
      child: Text(
        'Order data is empty.',
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildHeader(OrderModel order) {
    final Color color = _statusColor(order.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            order.orderCode,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.16),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: color.withOpacity(0.35)),
            ),
            child: Text(
              _displayStatus(order.status),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _infoRow(
            widget.isPurchase ? 'Seller' : 'Buyer',
            widget.isPurchase ? order.sellerName : order.buyerName,
          ),
          _infoRow('Created', _formatDate(order.createdAt)),
          if (order.updatedAt != null)
            _infoRow('Updated', _formatDate(order.updatedAt)),
        ],
      ),
    );
  }

  Widget _buildItemsSection(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Items',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 14),
          if (order.orderDetails.isEmpty)
            const Text(
              'No items in this order.',
              style: TextStyle(color: AppColors.textSecondary),
            )
          else
            ...order.orderDetails.map(_buildItemRow),
        ],
      ),
    );
  }

  Widget _buildItemRow(OrderDetailModel detail) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildItemImage(detail.imageUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.itemName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                if (detail.variantSnapshot != null &&
                    detail.variantSnapshot!.trim().isNotEmpty)
                  Text(
                    detail.variantSnapshot!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                if (detail.skuSnapshot != null &&
                    detail.skuSnapshot!.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    'SKU: ${detail.skuSnapshot}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  '${_formatPrice(detail.unitPrice)} x ${detail.quantity}',
                  style: const TextStyle(
                    color: AppColors.textPink,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Line total: ${_formatPrice(detail.totalPrice)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return _imagePlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        imageUrl,
        width: 74,
        height: 74,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return _imagePlaceholder();
        },
        loadingBuilder: (context, child, progress) {
          if (progress == null) {
            return child;
          }

          return Container(
            width: 74,
            height: 74,
            color: AppColors.surface,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                color: AppColors.textPink,
                strokeWidth: 2,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 74,
      height: 74,
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

  Widget _buildReceiverSection(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Receiver Information',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 14),
          _infoRow('Name', order.receiverName ?? 'N/A'),
          _infoRow('Phone', order.receiverPhone ?? 'N/A'),
          _infoRow('Address', order.shippingAddress ?? 'N/A'),
          if (order.note != null && order.note!.trim().isNotEmpty)
            _infoRow('Note', order.note!),
          if (order.cancelReason != null &&
              order.cancelReason!.trim().isNotEmpty)
            _infoRow('Cancel reason', order.cancelReason!),
        ],
      ),
    );
  }

  Widget _buildPriceSection(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _priceRow('Subtotal', order.subTotal),
          const SizedBox(height: 8),
          _priceRow('Service fee', order.serviceFee),
          const Divider(color: AppColors.divider, height: 24),
          _priceRow('Total', order.totalAmount, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildTimelineSection(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Timeline',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 14),
          _timelineRow(
            title: 'Created',
            time: _formatDate(order.createdAt),
            active: order.createdAt != null,
          ),
          _timelineRow(
            title: 'Paid',
            time: _formatDate(order.paidAt),
            active: order.paidAt != null,
          ),
          _timelineRow(
            title: 'Delivered',
            time: _formatDate(order.deliveredAt),
            active: order.deliveredAt != null,
          ),
          _timelineRow(
            title: 'Completed',
            time: _formatDate(order.completedAt),
            active: order.completedAt != null,
          ),
          _timelineRow(
            title: 'Cancelled',
            time: _formatDate(order.cancelledAt),
            active: order.cancelledAt != null,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _timelineRow({
    required String title,
    required String time,
    required bool active,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: active ? AppColors.textPink : AppColors.textSecondary,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 1,
                height: 28,
                color: AppColors.divider,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: active ? AppColors.text : AppColors.textSecondary,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  time,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(OrderModel order) {
    final status = _normalizeStatus(order.status);
    final buttons = <Widget>[];

    if (widget.isPurchase && status == 'pendingpayment') {
      buttons.add(
        _mainButton(
          text: 'Pay Now',
          icon: Icons.account_balance_wallet_outlined,
          onPressed: () {
            _confirmAction(
              title: 'Pay order',
              message: 'Do you want to pay this order using your wallet?',
              action: () => _orderService.payOrder(order.orderId),
              successMessage: 'Payment successful.',
            );
          },
        ),
      );
    }

    if (status == 'pendingpayment' || status == 'processing') {
      buttons.add(
        _outlineButton(
          text: 'Cancel Order',
          icon: Icons.cancel_outlined,
          color: Colors.redAccent,
          onPressed: () {
            _confirmAction(
              title: 'Cancel order',
              message: status == 'processing'
                  ? 'This order has been paid. Cancelling it will refund the buyer. Do you want to continue?'
                  : 'Are you sure you want to cancel this order?',
              action: () => _orderService.updateOrderStatus(
                order.orderId,
                'CANCELLED',
              ),
              successMessage: 'Order cancelled.',
            );
          },
        ),
      );
    }

    if (!widget.isPurchase && status == 'processing') {
      buttons.add(
        _mainButton(
          text: 'Mark as Shipping',
          icon: Icons.local_shipping_outlined,
          onPressed: () {
            _confirmAction(
              title: 'Ship order',
              message: 'Do you want to mark this order as shipping?',
              action: () => _orderService.updateOrderStatus(
                order.orderId,
                'SHIPPING',
              ),
              successMessage: 'Order marked as shipping.',
            );
          },
        ),
      );
    }

    if (widget.isPurchase && status == 'delivered') {
      buttons.add(
        _mainButton(
          text: 'Confirm Received',
          icon: Icons.check_circle_outline,
          onPressed: () {
            _confirmAction(
              title: 'Confirm received',
              message:
              'Have you received the item successfully? This will complete the order and release payment to the seller.',
              action: () => _orderService.updateOrderStatus(
                order.orderId,
                'COMPLETED',
              ),
              successMessage: 'Order completed.',
            );
          },
        ),
      );

      buttons.add(
        _outlineButton(
          text: 'Request Refund',
          icon: Icons.assignment_return_outlined,
          color: Colors.amber,
          onPressed: _openRefundScreen,
        ),
      );
    }

    if (buttons.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Text(
          'No available action for this order.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      );
    }

    return Column(
      children: [
        if (_isActionLoading)
          const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: CircularProgressIndicator(
              color: AppColors.textPink,
            ),
          ),
        ...buttons.map(
              (button) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: button,
          ),
        ),
      ],
    );
  }

  Widget _mainButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isActionLoading ? null : onPressed,
        icon: Icon(icon),
        label: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.textPink,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.surface,
          disabledForegroundColor: AppColors.textSecondary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _outlineButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isActionLoading ? null : onPressed,
        icon: Icon(icon),
        label: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          disabledForegroundColor: AppColors.textSecondary,
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(
      String label,
      double value, {
        bool isTotal = false,
      }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isTotal ? AppColors.text : AppColors.textSecondary,
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          _formatPrice(value),
          style: TextStyle(
            color: isTotal ? AppColors.textPink : AppColors.text,
            fontSize: isTotal ? 17 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.backgroundSecondary,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.divider),
    );
  }
}