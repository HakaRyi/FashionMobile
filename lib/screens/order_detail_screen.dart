import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initScreen();
  }

  Future<void> _initScreen() async {
    await _loadCurrentUserId();
    await _loadOrder(showFullLoading: true);
  }

  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();

    final rawUserId = prefs.getString('userId') ??
        prefs.getInt('userId')?.toString();

    _currentUserId = int.tryParse(rawUserId ?? '');
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

  bool _isBuyerView(OrderModel order) {
    if (_currentUserId == null) {
      return widget.isPurchase;
    }

    return order.buyerId == _currentUserId;
  }

  bool _isSellerView(OrderModel order) {
    if (_currentUserId == null) {
      return !widget.isPurchase;
    }

    return order.sellerId == _currentUserId;
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

    final utcDate = date.isUtc
        ? date
        : DateTime.utc(
      date.year,
      date.month,
      date.day,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );

    final vietnamTime = utcDate.add(const Duration(hours: 7));

    return DateFormat('dd/MM/yyyy HH:mm').format(vietnamTime);
  }

  String _displayStatus(String status) {
    switch (_normalizeStatus(status)) {
      case 'pendingpayment':
        return 'Pending Payment';
      case 'confirmed':
        return 'Confirmed';
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
        return const Color(0xFFE29400);
      case 'confirmed':
        return const Color(0xFF0F766E);
      case 'processing':
        return const Color(0xFF2563EB);
      case 'shipping':
        return const Color(0xFF0284C7);
      case 'delivered':
        return const Color(0xFF7C3AED);
      case 'completed':
        return const Color(0xFF16A34A);
      case 'cancelled':
        return const Color(0xFFDC2626);
      case 'refunding':
        return const Color(0xFFD97706);
      case 'refunded':
        return const Color(0xFF0891B2);
      default:
        return Colors.black54;
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

      AppToast.showSuccess(context, successMessage);

      await _refreshOrder();
    } catch (e) {
      if (!mounted) {
        return;
      }

      AppToast.showError(
        context,
        _normalizeError(e),
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
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.black54,
              height: 1.4,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'NO',
                style: TextStyle(
                  color: Colors.black38,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'YES',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
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
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF5F5F5),
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black,
              size: 20,
            ),
            onPressed: _back,
          ),
          title: const Text(
            'ORDER DETAIL',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 17,
              letterSpacing: 0,
            ),
          ),
          actions: [
            IconButton(
              onPressed: _isActionLoading ? null : _refreshOrder,
              icon: const Icon(
                Icons.refresh_rounded,
                color: Colors.black,
              ),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
          child: CircularProgressIndicator(color: Colors.black),
        )
            : _error != null
            ? _buildError()
            : order == null
            ? _buildEmpty()
            : RefreshIndicator(
          onRefresh: _refreshOrder,
          color: Colors.black,
          backgroundColor: Colors.white,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
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
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: _cardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.black,
                size: 48,
              ),
              const SizedBox(height: 12),
              const Text(
                'Failed to load order detail',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? 'An unexpected error occurred.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _loadOrder(showFullLoading: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'TRY AGAIN',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Text(
        'Order data is empty.',
        style: TextStyle(
          color: Colors.black54,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildHeader(OrderModel order) {
    final Color color = _statusColor(order.status);
    final isBuyerView = _isBuyerView(order);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ORDER CODE',
            style: TextStyle(
              color: Colors.black38,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            order.orderCode,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 14),
          _buildStatusChip(order.status, color),
          const SizedBox(height: 16),
          _infoRow(
            isBuyerView ? 'Seller' : 'Buyer',
            isBuyerView ? order.sellerName : order.buyerName,
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
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('ITEMS', Icons.checkroom_outlined),
          const SizedBox(height: 14),
          if (order.orderDetails.isEmpty)
            const Text(
              'No items in this order.',
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            ...order.orderDetails.map(_buildItemRow),
        ],
      ),
    );
  }

  Widget _buildItemRow(OrderDetailModel detail) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black.withOpacity(0.04),
        ),
      ),
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
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                if (detail.variantSnapshot != null &&
                    detail.variantSnapshot!.trim().isNotEmpty)
                  Text(
                    detail.variantSnapshot!,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (detail.skuSnapshot != null &&
                    detail.skuSnapshot!.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    'SKU: ${detail.skuSnapshot}',
                    style: const TextStyle(
                      color: Colors.black38,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  '${_formatPrice(detail.unitPrice)} x ${detail.quantity}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Line total: ${_formatPrice(detail.totalPrice)}',
                  style: const TextStyle(
                    color: Colors.black45,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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
        width: 76,
        height: 76,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return _imagePlaceholder();
        },
        loadingBuilder: (context, child, progress) {
          if (progress == null) {
            return child;
          }

          return Container(
            width: 76,
            height: 76,
            color: Colors.white,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                color: Colors.black,
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
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.black.withOpacity(0.05),
        ),
      ),
      child: const Icon(
        Icons.checkroom_outlined,
        color: Colors.black26,
      ),
    );
  }

  Widget _buildReceiverSection(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('RECEIVER INFORMATION', Icons.location_on_outlined),
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
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _priceRow('Subtotal', order.subTotal),
          const SizedBox(height: 9),
          _priceRow('Service fee', order.serviceFee),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              color: Color(0xFFEDEDED),
              height: 1,
            ),
          ),
          _priceRow('Total', order.totalAmount, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildTimelineSection(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('TIMELINE', Icons.timeline_rounded),
          const SizedBox(height: 16),
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
                color: active ? Colors.black : Colors.black12,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 1,
                height: 30,
                color: const Color(0xFFEDEDED),
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
                    color: active ? Colors.black : Colors.black38,
                    fontWeight: active ? FontWeight.w900 : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  time,
                  style: const TextStyle(
                    color: Colors.black38,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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

    final isBuyerView = _isBuyerView(order);
    final isSellerView = _isSellerView(order);

    if (isBuyerView && status == 'pendingpayment') {
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

    final canBuyerCancel =
        isBuyerView && (status == 'pendingpayment' || status == 'processing');

    final canSellerCancel = isSellerView && status == 'processing';

    if (canBuyerCancel || canSellerCancel) {
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

    if (isSellerView && status == 'processing') {
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

    if (isBuyerView && status == 'delivered') {
      buttons.add(
        _mainButton(
          text: 'Confirm Received',
          icon: Icons.check_circle_outline,
          onPressed: () {
            _confirmAction(
              title: 'Confirm received',
              message: 'Have you received the item successfully?',
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
          color: const Color(0xFFD97706),
          onPressed: _openRefundScreen,
        ),
      );
    }

    if (buttons.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: const Text(
          'No available action for this order.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black45,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Column(
      children: [
        if (_isActionLoading)
          const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: CircularProgressIndicator(color: Colors.black),
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
          text.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFEDEDED),
          disabledForegroundColor: Colors.black38,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 15),
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
          text.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          disabledForegroundColor: Colors.black38,
          side: BorderSide(color: color.withOpacity(0.7)),
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
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
                color: Colors.black45,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w700,
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
              color: isTotal ? Colors.black : Colors.black54,
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ),
        Text(
          _formatPrice(value),
          style: TextStyle(
            color: Colors.black,
            fontSize: isTotal ? 17 : 14,
            fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.black,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withOpacity(0.25),
        ),
      ),
      child: Text(
        _displayStatus(status).toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 10,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: Colors.black.withOpacity(0.05),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}