import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../services/order_service.dart';
import '../../services/wardrobe_service.dart';
import '../../models/wardrobe_item_model.dart';
import '../../services/follow_service.dart';
import '../constants/notification_type.dart';
import '../models/search_model.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../services/location_service.dart';
import '../widgets/create_order/item_selection_sheet.dart';
import '../widgets/create_order/buyer_selection_sheet.dart';
import '../utils/app_notification.dart';

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
  final LocationService _locationService = LocationService();
  final NumberFormat _formatter = NumberFormat.decimalPattern('vi_VN');
  final NotificationService _notificationService = NotificationService();


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

      await _orderService.createOrder(requestBody);

      if (mounted) {
        NotificationService.show(
          context,
          title: "Thành công!",
          message: "Tạo đơn hàng thành công.",
          type: NotificationType.success,
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        NotificationService.show(
          context,
          title: "Đã xảy ra lỗi",
          message: "Tạo đơn thất bại",
          type: NotificationType.error,
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
        return ItemSelectionSheet(
          wardrobeService: _wardrobeService,
          initialSelectedItems: _selectedItems,
          onSelectionConfirmed: (List<WardrobeItemModel> items) {
            setState(() {
              _selectedItems = items;
            });
            Navigator.pop(context);
          },
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
        return BuyerSelectionSheet(
          followService: _followService,
          onBuyerSelected: (UserSuggestionModel buyer) {
            setState(() {
              _selectedBuyer = buyer;
              _receiverNameController.text = buyer.fullName;
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  void _removeItem(int index) {
    setState(() {
      _selectedItems.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Tạo đơn bán hàng', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSectionTitle("Sản phẩm giao dịch"),
            if (_selectedItems.isNotEmpty)
              ..._selectedItems.asMap().entries.map((entry) {
                int idx = entry.key;
                WardrobeItemModel item = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
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
                              style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(item.brand ?? 'Không có thương hiệu', style: const TextStyle(color: Colors.pinkAccent, fontSize: 12)),
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
            const SizedBox(height: 24),

            _buildSectionTitle("Thông tin giao dịch"),
            _buildTextField(_priceController, 'Giá bán toàn bộ đơn (VND)', TextInputType.number, isCurrency: true),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _showBuyerSelectionSheet,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.05),
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
                        backgroundColor: Colors.black12,
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
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)
                            ),
                            const SizedBox(height: 2),
                            Text(
                                '@${_selectedBuyer!.username}',
                                style: const TextStyle(color: Colors.pinkAccent, fontSize: 13, fontWeight: FontWeight.w500)
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.swap_horiz, color: Colors.black),
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
            TypeAheadField<String>(
              controller: _shippingAddressController,
              debounceDuration: const Duration(milliseconds: 500),
              suggestionsCallback: (pattern) async {
                return await _locationService.searchAddress(pattern);
              },
              itemBuilder: (context, String suggestion) {
                return ListTile(
                  tileColor: AppColors.background,
                  leading: const Icon(Icons.location_on_outlined, color: Colors.pinkAccent),
                  title: Text(
                    suggestion,
                    style: const TextStyle(color: Colors.black, fontSize: 14),
                  ),
                );
              },
              onSelected: (String selection) {
                _shippingAddressController.text = selection;
              },
              loadingBuilder: (context) => const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator(color: Colors.pinkAccent)),
              ),
              emptyBuilder: (context) => const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Không tìm thấy địa chỉ này', style: TextStyle(color: Colors.white54)),
              ),
              builder: (context, controller, focusNode) {
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Địa chỉ giao hàng',
                    labelStyle: const TextStyle(color: Colors.black54),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.05),
                    prefixIcon: const Icon(Icons.map_outlined, color: Colors.black54),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.pinkAccent, width: 1.5),
                    ),
                  ),
                  validator: (value) => value!.isEmpty ? 'Vui lòng nhập Địa chỉ giao hàng' : null,
                );
              },
            ),

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
      child: Text(title, style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, TextInputType type, {bool isCurrency = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      style: const TextStyle(color: Colors.black),
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
        labelStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: Colors.black.withOpacity(0.05),
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