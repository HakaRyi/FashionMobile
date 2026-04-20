import 'package:fashion_mobile/constants/app_colors.dart';
import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../widgets/order_skeleton.dart';
import '../widgets/notification_overlay.dart';
import '../services/signalr_service.dart';
import '../services/order_service.dart';
import 'order_detail_screen.dart';
import 'create_order_screen.dart';
import 'refund_history_screen.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  final ScrollController _salesScrollController = ScrollController();
  final ScrollController _purchasesScrollController = ScrollController();

  final OrderService _orderService = OrderService();

  List<OrderModel> _salesOrders = [];
  List<OrderModel> _purchasesOrders = [];

  bool _isLoadingSales = true;
  bool _isLoadingMoreSales = false;
  bool _isLoadingPurchases = true;
  bool _isLoadingMorePurchases = false;

  final SignalRService _signalRService = SignalRService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _salesScrollController.addListener(() {
      if (_salesScrollController.position.pixels == _salesScrollController.position.maxScrollExtent) {
        _loadMoreSales();
      }
    });

    _purchasesScrollController.addListener(() {
      if (_purchasesScrollController.position.pixels == _purchasesScrollController.position.maxScrollExtent) {
        _loadMorePurchases();
      }
    });

    _fetchInitialData();
    _initRealtimeConnection();
  }

  void _initRealtimeConnection() async {
    _signalRService.onNewOrderReceived = (orderData) {
      if (!mounted) return;

      final newOrder = OrderModel.fromJson(orderData as Map<String, dynamic>);

      setState(() {
        _purchasesOrders.insert(0, newOrder);
      });

      NotificationOverlay.showNewOrderNotification(context, newOrder);
      // sửa chỗ này để thông báo hiện lên ở toàn app chứ không riêng trong
      // context này
    };

    await _signalRService.initSignalR();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _salesScrollController.dispose();
    _purchasesScrollController.dispose();
    _signalRService.stopSignalR();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoadingSales = true;
      _isLoadingPurchases = true;
    });

    try {
      final results = await Future.wait([
        _orderService.getSalesOrders(),
        _orderService.getPurchasesOrders(),
      ]);

      if (mounted) {
        setState(() {
          _salesOrders = results[0];
          _purchasesOrders = results[1];
          _isLoadingSales = false;
          _isLoadingPurchases = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSales = false;
          _isLoadingPurchases = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadMoreSales() async {}

  Future<void> _loadMorePurchases() async {}

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color? textColor;
    String text;

    switch (status) {
      case 'PENDING':
        bgColor = Colors.orange.withOpacity(0.2);
        textColor = Colors.orangeAccent;
        text = 'Chờ xử lý';
        break;
      case 'COMPLETED':
        bgColor = Colors.blue.withOpacity(0.3);
        textColor = Color(0xFF01BBFF);
        text = 'Giao hàng thành công';
        break;
      case 'DONE':
        bgColor = Colors.green.withOpacity(0.2);
        textColor = Color(0xFF31D832);
        text = 'Hoàn thành';
        break;
      default:
        bgColor = Colors.grey.withOpacity(0.2);
        textColor = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order, bool isSale) {
    final displayAccount = isSale ? order.buyer : order.seller;
    final accountLabel = isSale ? 'Người mua' : 'Người bán';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderDetailScreen(
            orderId: order.orderId,
            isSeller: isSale,
          ),
        ),
      ).then((_) => _fetchInitialData()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSecondary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "#${order.orderId}",
                  style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                _buildStatusBadge(order.status),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 12),
            if (order.orderDetails.isNotEmpty)
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      order.firstItemImage.isNotEmpty
                          ? order.firstItemImage
                          : 'https://via.placeholder.com/150',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 60,
                        height: 60,
                        color: AppColors.backgroundTertiary,
                        child: const Icon(Icons.image, color: AppColors.text),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.displayItemName,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "$accountLabel: ${displayAccount?.name ?? 'Ẩn danh'}",
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tạo: ${order.formattedCreatedAt}",
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Cập nhật: ${order.formattedUpdatedAt}",
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                    ),
                  ],
                ),
                Text(
                  "${order.formattedTotalAmount}đ",
                  style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm đơn hàng...',
                    hintStyle: const TextStyle(color: AppColors.textPrimary),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textPrimary),
                    filled: true,
                    fillColor: AppColors.textPrimary.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CreateOrderScreen()),
                  ).then((value) {
                    if (value == true) {
                      _fetchInitialData();
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoadingSales
              ? ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 5,
            itemBuilder: (_, __) => const OrderSkeleton(),
          )
              : _salesOrders.isEmpty
              ? const Center(child: Text('Chưa có đơn hàng nào', style: TextStyle(color: Colors.black54)))
              : ListView.builder(
            controller: _salesScrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _salesOrders.length + (_isLoadingMoreSales ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _salesOrders.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator(color: Colors.pink)),
                );
              }
              return _buildOrderCard(_salesOrders[index], true);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPurchasesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RefundHistoryScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.history, color: Colors.pinkAccent, size: 20),
                label: const Text(
                  'Lịch sử trả hàng',
                  style: TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.pinkAccent),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoadingPurchases
              ? ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 5,
            itemBuilder: (_, __) => const OrderSkeleton(),
          )
              : _purchasesOrders.isEmpty
              ? const Center(
            child: Text(
              'Chưa có đơn hàng nào',
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
          )
              : ListView.builder(
            controller: _purchasesScrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _purchasesOrders.length + (_isLoadingMorePurchases ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _purchasesOrders.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator(color: Colors.pink)),
                );
              }
              return _buildOrderCard(_purchasesOrders[index], false);
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.createHeader,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Quản lý đơn hàng', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.pink,
          labelColor: Colors.pink,
          unselectedLabelColor: Colors.black54,
          tabs: const [
            Tab(text: 'Đơn hàng đã tạo'),
            Tab(text: 'Đơn hàng đã mua'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSalesTab(),
          _buildPurchasesTab(),
        ],
      ),
    );
  }
}