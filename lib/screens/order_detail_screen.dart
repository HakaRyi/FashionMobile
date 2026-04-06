import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
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
      Navigator.pop(context);
      setState(() {
        _order = updatedOrder;
      });
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
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
            child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isHighlight ? Colors.pinkAccent : Colors.white,
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

  String _getDisplayStatus(String status) {
    switch (status) {
      case 'PENDING':
        return 'Chờ xác nhận';
      case 'CONFIRMED':
        return 'Đã xác nhận';
      case 'PREPARED':
        return 'Đã chuẩn bị';
      case 'PAID':
        return 'Đã thanh toán';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  Widget _buildActionButtons() {
    if (_order == null) return const SizedBox.shrink();

    final String status = _order!.status;

    if (widget.isSeller) {
      if (status == 'PENDING') {
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
                onPressed: () => {}, //thay bằng hàm cập nhật đơn hàng ở đây
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
      } else if (status == 'PAID' || status == 'CONFIRMED') {
        return ElevatedButton(
          onPressed: () => _updateOrderStatus('PROCESSING'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orangeAccent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Đã chuẩn bị hàng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        );
      }
    } else {
      if (status == 'PENDING') {
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
            const SizedBox(width: 10,),
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
      } else if (status == 'CONFIRMED') {
        return ElevatedButton(
          onPressed: _navigateToPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pink,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Thanh toán ngay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        );
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        'Trạng thái: ${_getDisplayStatus(status)}',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text('Chi tiết đơn hàng', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Padding(padding: EdgeInsets.all(16), child: OrderSkeleton())
          : _order == null
          ? const Center(child: Text('Không tìm thấy đơn hàng', style: TextStyle(color: Colors.white54)))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
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
            const Text('Thông tin nhận hàng', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
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
            const Text('Danh sách sản phẩm', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._order!.orderDetails.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
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
                        width: 60, height: 60, color: Colors.grey[800],
                        child: const Icon(Icons.image, color: Colors.white54),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.itemName, style: const TextStyle(color: Colors.white, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text('Số lượng: ${item.quantity}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text(
                    '${NumberFormat.decimalPattern('vi_VN').format(item.totalPrice)}đ',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildInfoRow('Tạm tính:', '${NumberFormat.decimalPattern('vi_VN').format(_order!.subTotal)}đ'),
                  _buildInfoRow('Phí dịch vụ:', '${NumberFormat.decimalPattern('vi_VN').format(_order!.serviceFee)}đ'),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng cộng', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
          color: Color(0xFF1E1E1E),
          border: Border(top: BorderSide(color: Colors.white10)),
        ),
        child: SafeArea(
          child: _buildActionButtons(),
        ),
      ),
    );
  }
}