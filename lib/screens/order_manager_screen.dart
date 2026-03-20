import 'package:flutter/material.dart';
import '../models/account_model.dart';
import '../models/order_detail_model.dart';
import '../models/order_model.dart';
import '../widgets/order_skeleton.dart';
import '../widgets/notification_overlay.dart';
import 'order_detail_screen.dart';

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

  List<OrderModel> _salesOrders = [];
  List<OrderModel> _purchasesOrders = [];

  bool _isLoadingSales = true;
  bool _isLoadingMoreSales = false;
  bool _isLoadingPurchases = true;
  bool _isLoadingMorePurchases = false;

  final int _pageSize = 10;
  int _salesPage = 1;
  int _purchasesPage = 1;

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
    _listenToRealtimeOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _salesScrollController.dispose();
    _purchasesScrollController.dispose();
    super.dispose();
  }

  void _listenToRealtimeOrders() {
    Future.delayed(const Duration(seconds: 10), () {
      if (!mounted) return;
      final newMockOrder = OrderModel(
        orderId: 999,
        buyerId: 1,
        sellerId: 2,
        subTotal: 150000,
        serviceFee: 5000,
        totalAmount: 155000,
        status: 'PENDING',
        createdAt: DateTime.now(),
        seller: AccountModel(accountId: 2, name: 'Nguyễn Văn A'),
        orderDetails: [
          OrderDetailModel(
            orderDetailId: 1,
            orderId: 999,
            quantity: 1,
            unitPrice: 150000,
            itemName: 'Áo thun phong cách',
            itemImage: 'https://via.placeholder.com/150',
          )
        ],
      );

      setState(() {
        _purchasesOrders.insert(0, newMockOrder);
      });
      NotificationOverlay.showNewOrderNotification(context, newMockOrder);
    });
  }

  Future<void> _fetchInitialData() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _salesOrders = _generateMockOrders(isSale: true, count: _pageSize);
      _purchasesOrders = _generateMockOrders(isSale: false, count: _pageSize);
      _isLoadingSales = false;
      _isLoadingPurchases = false;
    });
  }

  Future<void> _loadMoreSales() async {
    if (_isLoadingMoreSales) return;
    setState(() => _isLoadingMoreSales = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _salesPage++;
      _salesOrders.addAll(_generateMockOrders(isSale: true, count: _pageSize));
      _isLoadingMoreSales = false;
    });
  }

  Future<void> _loadMorePurchases() async {
    if (_isLoadingMorePurchases) return;
    setState(() => _isLoadingMorePurchases = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _purchasesPage++;
      _purchasesOrders.addAll(_generateMockOrders(isSale: false, count: _pageSize));
      _isLoadingMorePurchases = false;
    });
  }

  List<OrderModel> _generateMockOrders({required bool isSale, required int count}) {
    return List.generate(count, (index) {
      return OrderModel(
        orderId: DateTime.now().millisecondsSinceEpoch + index,
        buyerId: isSale ? 2 : 1,
        sellerId: isSale ? 1 : 2,
        subTotal: 200000,
        serviceFee: 10000,
        totalAmount: 210000,
        status: index % 3 == 0 ? 'PENDING' : 'COMPLETED',
        createdAt: DateTime.now().subtract(Duration(days: index)),
        updatedAt: DateTime.now().subtract(Duration(hours: index)),
        buyer: AccountModel(accountId: 2, name: 'Khách hàng ${index + 1}'),
        seller: AccountModel(accountId: 1, name: 'Người bán ${index + 1}'),
        orderDetails: [
          OrderDetailModel(
            orderDetailId: index,
            orderId: 1,
            quantity: 1,
            unitPrice: 200000,
            itemName: 'Sản phẩm thời trang ${index + 1}',
            itemImage: 'https://via.placeholder.com/150',
          )
        ],
      );
    });
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String text;

    switch (status) {
      case 'PENDING':
        bgColor = Colors.orange.withOpacity(0.2);
        textColor = Colors.orangeAccent;
        text = 'Chờ xử lý';
        break;
      case 'COMPLETED':
        bgColor = Colors.green.withOpacity(0.2);
        textColor = Colors.greenAccent;
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
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "#${order.orderId}",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                _buildStatusBadge(order.status),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 12),
            if (order.orderDetails.isNotEmpty)
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      order.orderDetails.first.itemImage,
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
                        Text(
                          order.orderDetails.first.itemName,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "$accountLabel: ${displayAccount?.name ?? 'Ẩn danh'}",
                          style: const TextStyle(color: Colors.white54, fontSize: 13),
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
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Cập nhật: ${order.formattedUpdatedAt}",
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
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
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
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
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
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
    return _isLoadingPurchases
        ? ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (_, __) => const OrderSkeleton(),
    )
        : ListView.builder(
      controller: _purchasesScrollController,
      padding: const EdgeInsets.all(16),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text('Quản lý đơn hàng', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.pink,
          labelColor: Colors.pink,
          unselectedLabelColor: Colors.white54,
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