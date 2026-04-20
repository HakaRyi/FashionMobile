import 'package:fashion_mobile/screens/refund_request_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/notification_type.dart';
import '../models/order_model.dart';
import '../utils/app_notification.dart';
import '../services/order_service.dart';
import '../widgets/order_skeleton.dart';
import 'wallet_payment_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  final bool isSeller;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    required this.isSeller,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _isLoading = true;
  OrderModel? _order;
  final OrderService _orderService = OrderService();

  @override
  void initState() {
    super.initState();
    _fetchOrderDetail();
  }

  Future<void> _fetchOrderDetail() async {
    try {
      final orderData = await _orderService.getOrderById(widget.orderId);
      if (mounted) {
        setState(() {
          _order = orderData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        NotificationService.show(
          context,
          title: "Lỗi!",
          message: "Không lấy được thông tin đơn hàng",
          type: NotificationType.error,
        );
      }
    }
  }

  Future<void> _updateOrderStatus(String newStatus) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.pink)),
    );

    try {
      final updatedOrder = await _orderService.updateOrderStatus(widget.orderId, newStatus);
      if (!mounted) return;
      NotificationService.show(
        context,
        title: "Thành công",
        message: "Đơn hàng ở trạng thái $newStatus",
        type: NotificationType.info,
      );
      Navigator.pop(context);
      setState(() {
        _order = updatedOrder;
      });
    } catch (e) {
      if (!mounted) return;
      NotificationService.show(
        context,
        title: "Lỗi!",
        message: "Cập nhật đơn hàng thất bại",
        type: NotificationType.error,
      );
      Navigator.pop(context);
    }
  }

  void _navigateToPayment() async {
    if (_order == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WalletPaymentScreen(order: _order!),
      ),
    );

    if (result == true) {
      _fetchOrderDetail();
    }
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isHighlight ? Colors.pinkAccent : AppColors.textPrimary,
                fontSize: 14,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToRefund() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RefundRequestScreen(orderId: _order!.orderId),
      ),
    );
  }

  String _getDisplayStatus(String status) {
    switch (status) {
      case 'PENDING':
        return 'Chờ xác nhận';
      case 'CONFIRMED':
        return 'Chờ thanh toán';
      case 'PROCESSING':
        return 'Đang chuẩn bị hàng';
      case 'SHIPPING':
        return 'Đang giao hàng';
      case 'COMPLETED':
        return 'Đã giao hàng';
      case 'CANCELLED':
        return 'Đã hủy';
      case 'REFUNDING':
        return 'Đang hoàn đơn';
      case 'REFUNDED':
        return 'Đã hoàn đơn';
      case 'DONE':
        return 'Hoàn thành';
      default:
        return status;
    }
  }

  Widget _buildActionButtons() {
    if (_order == null) return const SizedBox.shrink();

    final String status = _order!.status;

    if (widget.isSeller) {
      switch (status) {
        case 'PENDING':
          return Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _updateOrderStatus('CANCELLED'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Hủy đơn', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _updateOrderStatus('CONFIRMED'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cập Nhật', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          );
        case 'PROCESSING':
          return ElevatedButton(
            onPressed: () => _updateOrderStatus('SHIPPING'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Đã chuẩn bị hàng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          );
        case 'REFUNDED':
          return ElevatedButton(
            onPressed: () => _updateOrderStatus('DONE'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Đã nhận lại hàng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          );
        default:
          break;
      }
    } else {
      switch (status) {
        case 'PENDING':
          return Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _updateOrderStatus('CANCELLED'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Hủy đơn', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _updateOrderStatus('CONFIRMED'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Xác nhận', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          );
        case 'CONFIRMED':
          return ElevatedButton(
            onPressed: _navigateToPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Thanh toán ngay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          );
        case 'COMPLETED':
          return Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _navigateToRefund,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Trả hàng', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _updateOrderStatus('DONE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Đã nhận hàng', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          );
        case 'REFUNDED':
          return ElevatedButton(
            onPressed: () => {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Đã được duyệt trả hàng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          );
        default:
          break;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSecondary),
      ),
      child: Text(
        'Trạng thái: ${_getDisplayStatus(status)}',
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Chi tiết đơn hàng', style: TextStyle(color: AppColors.textPrimary)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Padding(padding: EdgeInsets.all(16), child: OrderSkeleton())
          : _order == null
          ? const Center(child: Text('Không tìm thấy đơn hàng', style: TextStyle(color: AppColors.textPrimary)))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildInfoRow('Mã đơn hàng:', '#${_order!.orderId}'),
                  _buildInfoRow('Trạng thái:', _getDisplayStatus(_order!.status), isHighlight: true),
                  _buildInfoRow('Ngày tạo:', _order!.formattedCreatedAt),
                  if (_order!.updatedAt != null)
                    _buildInfoRow('Ngày cập nhật:', _order!.formattedUpdatedAt),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Thông tin nhận hàng', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildInfoRow('Người nhận:', _order!.receiverName ?? '---'),
                  _buildInfoRow('Số điện thoại:', _order!.receiverPhone ?? '---'),
                  _buildInfoRow('Địa chỉ:', _order!.shippingAddress ?? '---'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Danh sách sản phẩm', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._order!.orderDetails.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.itemImage.isNotEmpty ? item.itemImage : 'https://via.placeholder.com/150',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 60, height: 60, color: AppColors.textSecondary,
                        child: const Icon(Icons.image, color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.itemName, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text('Số lượng: ${item.quantity}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text(
                    '${NumberFormat.decimalPattern('vi_VN').format(item.totalPrice)}đ',
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildInfoRow('Tạm tính:', '${NumberFormat.decimalPattern('vi_VN').format(_order!.subTotal)}đ'),
                  _buildInfoRow('Phí dịch vụ:', '${NumberFormat.decimalPattern('vi_VN').format(_order!.serviceFee)}đ'),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng cộng', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                        '${_order!.formattedTotalAmount}đ',
                        style: const TextStyle(color: Colors.pinkAccent, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _order == null
          ? null
          : Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.backgroundSecondary,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: SafeArea(
          child: _buildActionButtons(),
        ),
      ),
    );
  }
}