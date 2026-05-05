import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  final ScrollController _purchaseScrollController = ScrollController();
  final ScrollController _salesScrollController = ScrollController();

  late final TabController _tabController;

  static const int _pageSize = 10;

  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isLoadingMorePurchase = false;
  bool _isLoadingMoreSales = false;

  String? _error;
  String? _selectedStatus;

  DateTime? _fromDate;
  DateTime? _toDate;

  int _purchasePage = 1;
  int _salesPage = 1;

  bool _purchaseHasMore = false;
  bool _salesHasMore = false;

  List<OrderModel> _purchaseOrders = [];
  List<OrderModel> _salesOrders = [];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    _purchaseScrollController.addListener(() {
      if (!_purchaseScrollController.hasClients) {
        return;
      }

      if (_purchaseScrollController.position.pixels >=
          _purchaseScrollController.position.maxScrollExtent - 200) {
        _loadMorePurchases();
      }
    });

    _salesScrollController.addListener(() {
      if (!_salesScrollController.hasClients) {
        return;
      }

      if (_salesScrollController.position.pixels >=
          _salesScrollController.position.maxScrollExtent - 200) {
        _loadMoreSales();
      }
    });

    _loadOrders(showFullLoading: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _nameController.dispose();
    _purchaseScrollController.dispose();
    _salesScrollController.dispose();
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
      _purchasePage = 1;
      _salesPage = 1;

      final results = await Future.wait([
        _orderService.getPurchasesOrders(
          page: _purchasePage,
          pageSize: _pageSize,
          status: _selectedStatus,
          fromDate: _toUtcStartOfDay(_fromDate),
          toDate: _toUtcEndOfDay(_toDate),
          sellerName: _nameController.text,
          orderCode: _searchController.text,
        ),
        _orderService.getSalesOrders(
          page: _salesPage,
          pageSize: _pageSize,
          status: _selectedStatus,
          fromDate: _toUtcStartOfDay(_fromDate),
          toDate: _toUtcEndOfDay(_toDate),
          buyerName: _nameController.text,
          orderCode: _searchController.text,
        ),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _purchaseOrders = results[0].items;
        _salesOrders = results[1].items;

        _purchaseHasMore = results[0].hasMore;
        _salesHasMore = results[1].hasMore;
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

  Future<void> _loadMorePurchases() async {
    if (_isLoadingMorePurchase || !_purchaseHasMore) {
      return;
    }

    setState(() {
      _isLoadingMorePurchase = true;
    });

    try {
      final nextPage = _purchasePage + 1;

      final result = await _orderService.getPurchasesOrders(
        page: nextPage,
        pageSize: _pageSize,
        status: _selectedStatus,
        fromDate: _toUtcStartOfDay(_fromDate),
        toDate: _toUtcEndOfDay(_toDate),
        sellerName: _nameController.text,
        orderCode: _searchController.text,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _purchasePage = nextPage;
        _purchaseOrders.addAll(result.items);
        _purchaseHasMore = result.hasMore;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_normalizeError(e))),
      );
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingMorePurchase = false;
      });
    }
  }

  Future<void> _loadMoreSales() async {
    if (_isLoadingMoreSales || !_salesHasMore) {
      return;
    }

    setState(() {
      _isLoadingMoreSales = true;
    });

    try {
      final nextPage = _salesPage + 1;

      final result = await _orderService.getSalesOrders(
        page: nextPage,
        pageSize: _pageSize,
        status: _selectedStatus,
        fromDate: _toUtcStartOfDay(_fromDate),
        toDate: _toUtcEndOfDay(_toDate),
        buyerName: _nameController.text,
        orderCode: _searchController.text,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _salesPage = nextPage;
        _salesOrders.addAll(result.items);
        _salesHasMore = result.hasMore;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_normalizeError(e))),
      );
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingMoreSales = false;
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

    final vietnamTime = date.isUtc
        ? date.toLocal()
        : DateTime.utc(
      date.year,
      date.month,
      date.day,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    ).add(const Duration(hours: 7));

    return DateFormat('dd/MM/yyyy HH:mm').format(vietnamTime);
  }

  DateTime? _toUtcStartOfDay(DateTime? date) {
    if (date == null) {
      return null;
    }

    final vietnamStart = DateTime(
      date.year,
      date.month,
      date.day,
    );

    return vietnamStart.subtract(const Duration(hours: 7));
  }

  DateTime? _toUtcEndOfDay(DateTime? date) {
    if (date == null) {
      return null;
    }

    final vietnamEnd = DateTime(
      date.year,
      date.month,
      date.day,
      23,
      59,
      59,
      999,
    );

    return vietnamEnd.subtract(const Duration(hours: 7));
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
        return const Color(0xFFE29400);
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

  Future<DateTime?> _pickDate(DateTime? initialDate) async {
    return await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
  }

  bool _hasFilter() {
    return _selectedStatus != null ||
        _fromDate != null ||
        _toDate != null ||
        _searchController.text.trim().isNotEmpty ||
        _nameController.text.trim().isNotEmpty;
  }

  void _resetFilters() {
    setState(() {
      _selectedStatus = null;
      _fromDate = null;
      _toDate = null;
      _searchController.clear();
      _nameController.clear();
    });

    _loadOrders(showFullLoading: true);
  }

  void _applySearch() {
    FocusScope.of(context).unfocus();
    _loadOrders(showFullLoading: true);
  }

  bool _currentTabHasMore(bool isPurchase) {
    return isPurchase ? _purchaseHasMore : _salesHasMore;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'ORDERS',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 17,
            letterSpacing: 0,
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
                color: Colors.black,
              ),
            )
                : const Icon(
              Icons.refresh_rounded,
              color: Colors.black,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            height: 44,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.black.withOpacity(0.05),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.black54,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 0,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 0,
              ),
              tabs: const [
                Tab(text: 'Purchases'),
                Tab(text: 'Sales'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Colors.black),
      )
          : _error != null
          ? _buildError()
          : Column(
        children: [
          _buildFilterArea(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(
                  orders: _purchaseOrders,
                  isPurchase: true,
                  scrollController: _purchaseScrollController,
                  isLoadingMore: _isLoadingMorePurchase,
                  hasMore: _currentTabHasMore(true),
                ),
                _buildOrderList(
                  orders: _salesOrders,
                  isPurchase: false,
                  scrollController: _salesScrollController,
                  isLoadingMore: _isLoadingMoreSales,
                  hasMore: _currentTabHasMore(false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterArea() {
    return Container(
      color: const Color(0xFFF5F5F5),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _applySearch(),
            onChanged: (_) {
              setState(() {});
            },
            decoration: InputDecoration(
              hintText: 'Search order code...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.trim().isEmpty
                  ? null
                  : IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                  _loadOrders(showFullLoading: true);
                },
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.black.withOpacity(0.06),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.black.withOpacity(0.06),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.black),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _applySearch(),
                  onChanged: (_) {
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    hintText: _tabController.index == 0
                        ? 'Seller name'
                        : 'Buyer name',
                    prefixIcon: const Icon(Icons.person_search_rounded),
                    suffixIcon: _nameController.text.trim().isEmpty
                        ? null
                        : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _nameController.clear();
                        setState(() {});
                        _loadOrders(showFullLoading: true);
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.black.withOpacity(0.06),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.black.withOpacity(0.06),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.black),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildFilterButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton() {
    final hasFilter = _hasFilter();

    return InkWell(
      onTap: _showFilterSheet,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: hasFilter ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.black.withOpacity(0.06),
          ),
        ),
        child: Icon(
          Icons.tune_rounded,
          color: hasFilter ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Future<void> _showFilterSheet() async {
    String? tempStatus = _selectedStatus;
    DateTime? tempFromDate = _fromDate;
    DateTime? tempToDate = _toDate;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).padding.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Filter Orders',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Status',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildStatusChoice(
                        label: 'All',
                        value: null,
                        selectedValue: tempStatus,
                        onTap: () {
                          setModalState(() {
                            tempStatus = null;
                          });
                        },
                      ),
                      _buildStatusChoice(
                        label: 'Pending Payment',
                        value: 'PENDING_PAYMENT',
                        selectedValue: tempStatus,
                        onTap: () {
                          setModalState(() {
                            tempStatus = 'PENDING_PAYMENT';
                          });
                        },
                      ),
                      _buildStatusChoice(
                        label: 'Processing',
                        value: 'PROCESSING',
                        selectedValue: tempStatus,
                        onTap: () {
                          setModalState(() {
                            tempStatus = 'PROCESSING';
                          });
                        },
                      ),
                      _buildStatusChoice(
                        label: 'Shipping',
                        value: 'SHIPPING',
                        selectedValue: tempStatus,
                        onTap: () {
                          setModalState(() {
                            tempStatus = 'SHIPPING';
                          });
                        },
                      ),
                      _buildStatusChoice(
                        label: 'Delivered',
                        value: 'DELIVERED',
                        selectedValue: tempStatus,
                        onTap: () {
                          setModalState(() {
                            tempStatus = 'DELIVERED';
                          });
                        },
                      ),
                      _buildStatusChoice(
                        label: 'Completed',
                        value: 'COMPLETED',
                        selectedValue: tempStatus,
                        onTap: () {
                          setModalState(() {
                            tempStatus = 'COMPLETED';
                          });
                        },
                      ),
                      _buildStatusChoice(
                        label: 'Cancelled',
                        value: 'CANCELLED',
                        selectedValue: tempStatus,
                        onTap: () {
                          setModalState(() {
                            tempStatus = 'CANCELLED';
                          });
                        },
                      ),
                      _buildStatusChoice(
                        label: 'Refunding',
                        value: 'REFUNDING',
                        selectedValue: tempStatus,
                        onTap: () {
                          setModalState(() {
                            tempStatus = 'REFUNDING';
                          });
                        },
                      ),
                      _buildStatusChoice(
                        label: 'Refunded',
                        value: 'REFUNDED',
                        selectedValue: tempStatus,
                        onTap: () {
                          setModalState(() {
                            tempStatus = 'REFUNDED';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Date',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateButton(
                          label: tempFromDate == null
                              ? 'From date'
                              : DateFormat('dd/MM/yyyy').format(tempFromDate!),
                          onTap: () async {
                            final picked = await _pickDate(tempFromDate);

                            if (picked != null) {
                              setModalState(() {
                                tempFromDate = picked;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildDateButton(
                          label: tempToDate == null
                              ? 'To date'
                              : DateFormat('dd/MM/yyyy').format(tempToDate!),
                          onTap: () async {
                            final picked = await _pickDate(tempToDate);

                            if (picked != null) {
                              setModalState(() {
                                tempToDate = picked;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  if (tempFromDate != null || tempToDate != null) ...[
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () {
                        setModalState(() {
                          tempFromDate = null;
                          tempToDate = null;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          'Clear date filter',
                          style: TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _resetFilters();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: Colors.black.withOpacity(0.16),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'RESET',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (tempFromDate != null &&
                                tempToDate != null &&
                                tempFromDate!.isAfter(tempToDate!)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'From date cannot be later than to date.',
                                  ),
                                ),
                              );
                              return;
                            }

                            setState(() {
                              _selectedStatus = tempStatus;
                              _fromDate = tempFromDate;
                              _toDate = tempToDate;
                            });

                            Navigator.pop(context);
                            _loadOrders(showFullLoading: true);
                          },
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
                            'APPLY',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusChoice({
    required String label,
    required String? value,
    required String? selectedValue,
    required VoidCallback onTap,
  }) {
    final selected = value == selectedValue;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: selected ? Colors.black : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? Colors.black : Colors.black.withOpacity(0.06),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black54,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.black.withOpacity(0.06),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: Colors.black54,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
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
          decoration: BoxDecoration(
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
          ),
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
                'Failed to load orders',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
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
                  onPressed: () => _loadOrders(showFullLoading: true),
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

  Widget _buildOrderList({
    required List<OrderModel> orders,
    required bool isPurchase,
    required ScrollController scrollController,
    required bool isLoadingMore,
    required bool hasMore,
  }) {
    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshOrders,
        color: Colors.black,
        backgroundColor: Colors.white,
        child: ListView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.18),
            Icon(
              isPurchase
                  ? Icons.shopping_bag_outlined
                  : Icons.storefront_outlined,
              color: Colors.black12,
              size: 76,
            ),
            const SizedBox(height: 16),
            Text(
              isPurchase
                  ? 'NO PURCHASE ORDERS FOUND'
                  : 'NO SALES ORDERS FOUND',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black26,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try changing your filters or search keyword.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black38,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshOrders,
      color: Colors.black,
      backgroundColor: Colors.white,
      child: ListView.separated(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        itemCount: orders.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          if (index >= orders.length) {
            if (isLoadingMore) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.black,
                    strokeWidth: 2,
                  ),
                ),
              );
            }

            if (!hasMore) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Text(
                    'No more orders',
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.35),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }

            return const SizedBox.shrink();
          }

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
    final statusColor = _statusColor(order.status);

    return InkWell(
      onTap: () {
        _openOrderDetail(
          order: order,
          isPurchase: isPurchase,
        );
      },
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
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
        ),
        child: Column(
          children: [
            Row(
              children: [
                _buildOrderImage(firstDetail?.imageUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 86,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.orderCode,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          firstDetail?.itemName ?? 'Unknown item',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (itemCount > 1) ...[
                          const SizedBox(height: 3),
                          Text(
                            '+ ${itemCount - 1} more item(s)',
                            style: const TextStyle(
                              color: Colors.black38,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          isPurchase
                              ? 'Seller: ${order.sellerName}'
                              : 'Buyer: ${order.buyerName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black45,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.black12,
                  size: 14,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.black.withOpacity(0.04),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatPrice(order.totalAmount),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  _buildStatusChip(order.status, statusColor),
                ],
              ),
            ),
            if (order.createdAt != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: Colors.black26,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _formatDate(order.createdAt),
                    style: const TextStyle(
                      color: Colors.black38,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
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
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        imageUrl,
        width: 86,
        height: 86,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return _buildImagePlaceholder();
        },
        loadingBuilder: (context, child, progress) {
          if (progress == null) {
            return child;
          }

          return Container(
            width: 86,
            height: 86,
            color: Colors.white,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.black,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black.withOpacity(0.04),
        ),
      ),
      child: const Icon(
        Icons.checkroom_outlined,
        color: Colors.black26,
      ),
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
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
          fontSize: 9,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}