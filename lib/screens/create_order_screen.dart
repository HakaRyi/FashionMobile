import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../services/order_service.dart';
import '../../services/wardrobe_service.dart';
import '../../models/wardrobe_item_model.dart';

import '../../services/follow_service.dart';
import '../models/search_model.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _receiverNameController = TextEditingController();
  final TextEditingController _receiverPhoneController = TextEditingController();
  final TextEditingController _shippingAddressController = TextEditingController();

  bool _isLoading = false;
  final OrderService _orderService = OrderService();
  final WardrobeService _wardrobeService = WardrobeService();
  final NumberFormat _formatter = NumberFormat.decimalPattern('vi_VN');

  List<WardrobeItemModel> _selectedItems = [];
  UserSuggestionModel? _selectedBuyer;
  final FollowService _followService = FollowService();

  Future<void> _submitOrder() async {
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất một sản phẩm từ tủ đồ', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_selectedBuyer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn người mua từ danh sách Follower', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final subTotal = double.parse(_priceController.text.replaceAll('.', ''));
      // ---> BẮT ĐẦU SỬA
      final unitPricePerItem = subTotal / _selectedItems.length;

      final requestBody = {
        "buyerId": int.parse(_selectedBuyer!.accountId.toString()),
        "subTotal": subTotal,
        "note": _selectedItems.length == 1 ? _selectedItems.first.itemName : "Đơn hàng ${_selectedItems.length} sản phẩm",
        "receiverName": _receiverNameController.text,
        "receiverPhone": _receiverPhoneController.text,
        "shippingAddress": _shippingAddressController.text,
        "details": _selectedItems.map((item) => {
          "productId": item.itemId,
          "quantity": 1,
          "unitPrice": unitPricePerItem,
          "imageUrl": item.imageUrl ?? "",
          "itemName": item.itemName
        }).toList()
      };
      // <--- KẾT THÚC SỬA

      await _orderService.createOrder(requestBody);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tạo đơn hàng thành công!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showItemSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _ItemSelectionSheet(
          wardrobeService: _wardrobeService,
          // ---> BẮT ĐẦU SỬA
          initialSelectedItems: _selectedItems,
          onSelectionConfirmed: (List<WardrobeItemModel> items) {
            setState(() {
              _selectedItems = items;
            });
            Navigator.pop(context);
          },
          // <--- KẾT THÚC SỬA
        );
      },
    );
  }

  void _showBuyerSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _BuyerSelectionSheet(
          followService: _followService,
          onBuyerSelected: (UserSuggestionModel buyer) {
            setState(() {
              _selectedBuyer = buyer;
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  // ---> BẮT ĐẦU SỬA
  void _removeItem(int index) {
    setState(() {
      _selectedItems.removeAt(index);
    });
  }
  // <--- KẾT THÚC SỬA

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text('Tạo đơn bán hàng', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSectionTitle("Sản phẩm giao dịch"),
            // ---> BẮT ĐẦU SỬA
            if (_selectedItems.isNotEmpty)
              ..._selectedItems.asMap().entries.map((entry) {
                int idx = entry.key;
                WardrobeItemModel item = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.imageUrl != null && item.imageUrl!.isNotEmpty
                              ? item.imageUrl!
                              : 'https://via.placeholder.com/150',
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
                              item.itemName,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(item.brand ?? 'Không có thương hiệu', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                        onPressed: () => _removeItem(idx),
                      ),
                    ],
                  ),
                );
              }),

            GestureDetector(
              onTap: _showItemSelectionSheet,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedItems.isEmpty ? Colors.pinkAccent.withOpacity(0.5) : Colors.white10,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline, color: Colors.pinkAccent),
                    SizedBox(width: 8),
                    Text("Thêm sản phẩm từ tủ đồ", style: TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            // <--- KẾT THÚC SỬA
            const SizedBox(height: 24),

            _buildSectionTitle("Thông tin giao dịch"),
            _buildTextField(_priceController, 'Giá bán toàn bộ đơn (VND)', TextInputType.number, isCurrency: true),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _showBuyerSelectionSheet,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedBuyer == null ? Colors.pinkAccent.withOpacity(0.5) : Colors.white10,
                  ),
                ),
                child: Row(
                  children: [
                    if (_selectedBuyer != null) ...[
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white10,
                        backgroundImage: NetworkImage(
                            _selectedBuyer!.avatarUrl.isNotEmpty
                                ? _selectedBuyer!.avatarUrl
                                : 'https://i.pravatar.cc/150?u=${_selectedBuyer!.accountId}'
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                _selectedBuyer!.fullName.isNotEmpty ? _selectedBuyer!.fullName : _selectedBuyer!.username,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)
                            ),
                            const SizedBox(height: 2),
                            Text(
                                '@${_selectedBuyer!.username}',
                                style: const TextStyle(color: Colors.pinkAccent, fontSize: 13, fontWeight: FontWeight.w500)
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.swap_horiz, color: Colors.white54),
                    ] else ...[
                      const Icon(Icons.person_add_alt_1, color: Colors.pinkAccent),
                      const SizedBox(width: 8),
                      const Text("Chọn người mua từ Follower", style: TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.pinkAccent),
                    ]
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            _buildSectionTitle("Thông tin người nhận"),
            _buildTextField(_receiverNameController, 'Tên người nhận', TextInputType.text),
            const SizedBox(height: 16),
            _buildTextField(_receiverPhoneController, 'Số điện thoại', TextInputType.phone),
            const SizedBox(height: 16),
            _buildTextField(_shippingAddressController, 'Địa chỉ giao hàng', TextInputType.streetAddress),

            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Tạo đơn và gửi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, TextInputType type, {bool isCurrency = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      onChanged: isCurrency ? (value) {
        if (value.isEmpty) return;
        final n = num.tryParse(value.replaceAll('.', ''));
        if (n != null) {
          final formatted = _formatter.format(n);
          controller.value = TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
          );
        }
      } : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        suffixText: isCurrency ? 'đ' : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) => value!.isEmpty ? 'Vui lòng nhập $label' : null,
    );
  }
}

class _ItemSelectionSheet extends StatefulWidget {
  final WardrobeService wardrobeService;
  // ---> BẮT ĐẦU SỬA
  final List<WardrobeItemModel> initialSelectedItems;
  final Function(List<WardrobeItemModel>) onSelectionConfirmed;

  const _ItemSelectionSheet({
    required this.wardrobeService,
    required this.initialSelectedItems,
    required this.onSelectionConfirmed,
  });
  // <--- KẾT THÚC SỬA

  @override
  State<_ItemSelectionSheet> createState() => _ItemSelectionSheetState();
}

class _ItemSelectionSheetState extends State<_ItemSelectionSheet> {
  List<WardrobeItemModel> _allItems = [];
  List<WardrobeItemModel> _filteredItems = [];
  // ---> BẮT ĐẦU SỬA
  List<WardrobeItemModel> _currentSelected = [];
  // <--- KẾT THÚC SỬA
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // ---> BẮT ĐẦU SỬA
    _currentSelected = List.from(widget.initialSelectedItems);
    // <--- KẾT THÚC SỬA
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    try {
      final items = await widget.wardrobeService.getMyWardrobeItems();
      if (mounted) {
        setState(() {
          _allItems = items;
          _filteredItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = _allItems;
      } else {
        _filteredItems = _allItems.where((item) {
          return item.itemName.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  // ---> BẮT ĐẦU SỬA
  void _toggleSelection(WardrobeItemModel item) {
    setState(() {
      final isSelected = _currentSelected.any((element) => element.itemId == item.itemId);
      if (isSelected) {
        _currentSelected.removeWhere((element) => element.itemId == item.itemId);
      } else {
        _currentSelected.add(item);
      }
    });
  }
  // <--- KẾT THÚC SỬA

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                // ---> BẮT ĐẦU SỬA
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Chọn sản phẩm",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton(
                      onPressed: () => widget.onSelectionConfirmed(_currentSelected),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text("Xác nhận (${_currentSelected.length})", style: const TextStyle(color: Colors.white)),
                    )
                  ],
                ),
                // <--- KẾT THÚC SỬA
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  onChanged: _filterItems,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm tên sản phẩm...',
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
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.pinkAccent))
                    : _errorMessage.isNotEmpty
                    ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent)))
                    : _filteredItems.isEmpty
                    ? const Center(child: Text("Không tìm thấy sản phẩm nào.", style: TextStyle(color: Colors.white54)))
                    : ListView.separated(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  itemCount: _filteredItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _filteredItems[index];
                    // ---> BẮT ĐẦU SỬA
                    final isSelected = _currentSelected.any((element) => element.itemId == item.itemId);

                    return GestureDetector(
                      onTap: () => _toggleSelection(item),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.pink.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? Colors.pinkAccent : Colors.white10),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item.imageUrl != null && item.imageUrl!.isNotEmpty
                                    ? item.imageUrl!
                                    : 'https://via.placeholder.com/150',
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 50, height: 50, color: Colors.grey[800],
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
                                    item.itemName,
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.brand ?? 'Không có thương hiệu',
                                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              isSelected ? Icons.check_circle : Icons.circle_outlined,
                              color: isSelected ? Colors.pinkAccent : Colors.white54,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BuyerSelectionSheet extends StatefulWidget {
  final FollowService followService;
  final Function(UserSuggestionModel) onBuyerSelected;

  const _BuyerSelectionSheet({
    required this.followService,
    required this.onBuyerSelected,
  });

  @override
  State<_BuyerSelectionSheet> createState() => _BuyerSelectionSheetState();
}

class _BuyerSelectionSheetState extends State<_BuyerSelectionSheet> {
  List<UserSuggestionModel> _allFollowers = [];
  List<UserSuggestionModel> _filteredFollowers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFollowers();
  }

  Future<void> _fetchFollowers() async {
    try {
      final followers = await widget.followService.getFollowers();
      if (mounted) {
        setState(() {
          _allFollowers = followers;
          _filteredFollowers = followers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterFollowers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredFollowers = _allFollowers;
      } else {
        _filteredFollowers = _allFollowers.where((user) {
          return user.fullName.toLowerCase().contains(query.toLowerCase()) ||
              user.username.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Chọn người mua",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  onChanged: _filterFollowers,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm theo tên hoặc username...',
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
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.pinkAccent))
                    : _filteredFollowers.isEmpty
                    ? const Center(child: Text("Không có ai theo dõi bạn.", style: TextStyle(color: Colors.white54)))
                    : ListView.separated(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  itemCount: _filteredFollowers.length,
                  separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 24),
                  itemBuilder: (context, index) {
                    final user = _filteredFollowers[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      onTap: () => widget.onBuyerSelected(user),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white10,
                        backgroundImage: NetworkImage(
                            user.avatarUrl.isNotEmpty
                                ? user.avatarUrl
                                : 'https://i.pravatar.cc/150?u=${user.accountId}'
                        ),
                      ),
                      title: Text(
                        user.fullName.isNotEmpty ? user.fullName : user.username,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '@${user.username}',
                        style: const TextStyle(color: Colors.pinkAccent, fontSize: 13),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}