import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import '../../constants/app_colors.dart';
import '../../services/order_service.dart';
import '../../services/wardrobe_service.dart';
import '../../services/follow_service.dart';
import '../../services/location_service.dart';
import '../../models/wardrobe_item_model.dart';
import '../constants/notification_type.dart';
import '../models/search_model.dart';
import '../widgets/create_order/item_selection_sheet.dart';
import '../widgets/create_order/buyer_selection_sheet.dart';
import '../utils/app_notification.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _receiverNameController = TextEditingController();
  final TextEditingController _receiverPhoneController = TextEditingController();
  final TextEditingController _shippingAddressController =
  TextEditingController();

  final OrderService _orderService = OrderService();
  final WardrobeService _wardrobeService = WardrobeService();
  final FollowService _followService = FollowService();
  final LocationService _locationService = LocationService();

  final NumberFormat _formatter = NumberFormat.decimalPattern('vi_VN');

  bool _isLoading = false;
  List<WardrobeItemModel> _selectedItems = [];
  UserSuggestionModel? _selectedBuyer;

  @override
  void dispose() {
    _priceController.dispose();
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    _shippingAddressController.dispose();
    super.dispose();
  }

  String? _validatePrice(String? value) {
    final rawValue = (value ?? '').replaceAll('.', '').trim();

    if (rawValue.isEmpty) {
      return 'Please enter the total order price';
    }

    if (!RegExp(r'^\d+$').hasMatch(rawValue)) {
      return 'Price must contain digits only';
    }

    final amount = double.tryParse(rawValue);
    if (amount == null) {
      return 'Invalid price';
    }

    if (amount <= 0) {
      return 'Price must be greater than 0';
    }

    if (amount < 1000) {
      return 'Price must be at least 1,000 VND';
    }

    if (amount > 100000000) {
      return 'Price is too large';
    }

    return null;
  }

  String? _validateReceiverName(String? value) {
    final text = (value ?? '').trim();

    if (text.isEmpty) {
      return 'Please enter the receiver name';
    }

    if (text.length < 2) {
      return 'Receiver name is too short';
    }

    if (text.length > 50) {
      return 'Receiver name is too long';
    }

    if (!RegExp(r"^[a-zA-ZÀ-ỹ\s'.-]+$").hasMatch(text)) {
      return 'Receiver name contains invalid characters';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    final text = (value ?? '').replaceAll(RegExp(r'\s+'), '').trim();

    if (text.isEmpty) {
      return 'Please enter the phone number';
    }

    if (!RegExp(r'^\d+$').hasMatch(text)) {
      return 'Phone number must contain digits only';
    }

    if (!RegExp(r'^(03|05|07|08|09)\d{8}$').hasMatch(text)) {
      return 'Invalid Vietnamese phone number';
    }

    return null;
  }

  String? _validateAddress(String? value) {
    final text = (value ?? '').trim();

    if (text.isEmpty) {
      return 'Please enter the shipping address';
    }

    if (text.length < 10) {
      return 'Shipping address is too short';
    }

    if (text.length > 255) {
      return 'Shipping address is too long';
    }

    if (!RegExp(r'[a-zA-ZÀ-ỹ]').hasMatch(text)) {
      return 'Shipping address must contain letters';
    }

    if (!RegExp(r'\d').hasMatch(text)) {
      return 'Shipping address should include a house number or street number';
    }

    return null;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Future<void> _submitOrder() async {
    if (_selectedItems.isEmpty) {
      _showErrorSnackBar('Please select at least one item from your wardrobe');
      return;
    }

    if (_selectedBuyer == null) {
      _showErrorSnackBar('Please select a buyer from your followers');
      return;
    }

    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final rawPrice = _priceController.text.replaceAll('.', '').trim();
    final subTotal = double.tryParse(rawPrice);

    if (subTotal == null || subTotal <= 0) {
      NotificationService.show(
        context,
        title: 'Invalid data',
        message: 'The total order price is invalid.',
        type: NotificationType.error,
      );
      return;
    }

    final receiverName = _receiverNameController.text.trim();
    final receiverPhone = _receiverPhoneController.text
        .replaceAll(RegExp(r'\s+'), '')
        .trim();
    final shippingAddress = _shippingAddressController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      final double unitPricePerItem = subTotal / _selectedItems.length;

      final requestBody = {
        'buyerId': _selectedBuyer!.accountId,
        'subTotal': subTotal,
        'note': _selectedItems.length == 1
            ? _selectedItems.first.itemName
            : 'Order with ${_selectedItems.length} items',
        'receiverName': receiverName,
        'receiverPhone': receiverPhone,
        'shippingAddress': shippingAddress,
        'details': _selectedItems.map((item) {
          return {
            'productId': item.itemId,
            'quantity': 1,
            'unitPrice': unitPricePerItem,
            'imageUrl': item.imageUrl ?? '',
            'itemName': item.itemName,
          };
        }).toList(),
      };

      await _orderService.createOrder(
        _selectedBuyer!.accountId,
        requestBody,
      );

      if (!mounted) return;

      NotificationService.show(
        context,
        title: 'Success',
        message: 'Order created successfully.',
        type: NotificationType.success,
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      NotificationService.show(
        context,
        title: 'Error',
        message: 'Failed to create order.',
        type: NotificationType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
              _receiverNameController.text = buyer.fullName.trim();
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

  void _formatCurrencyInput(String value) {
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.isEmpty) {
      _priceController.value = const TextEditingValue(text: '');
      return;
    }

    final number = num.tryParse(digitsOnly);
    if (number == null) {
      return;
    }

    final formatted = _formatter.format(number);

    _priceController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
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
        title: const Text(
          'Create Sales Order',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSectionTitle('Selected Items'),

            if (_selectedItems.isNotEmpty)
              ..._selectedItems.asMap().entries.map((entry) {
                final int index = entry.key;
                final WardrobeItemModel item = entry.value;

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
                          errorBuilder: (_, __, ___) {
                            return Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[800],
                              child: const Icon(
                                Icons.image,
                                color: Colors.white54,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.itemName,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.brand != null &&
                                  item.brand!.trim().isNotEmpty
                                  ? item.brand!.trim()
                                  : 'No brand',
                              style: const TextStyle(
                                color: Colors.pinkAccent,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.redAccent,
                        ),
                        onPressed: () => _removeItem(index),
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
                    color: _selectedItems.isEmpty
                        ? Colors.pinkAccent.withOpacity(0.5)
                        : Colors.white10,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline, color: Colors.pinkAccent),
                    SizedBox(width: 8),
                    Text(
                      'Add items from wardrobe',
                      style: TextStyle(
                        color: Colors.pinkAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            _buildSectionTitle('Order Information'),

            _buildTextField(
              controller: _priceController,
              label: 'Total order price (VND)',
              type: TextInputType.number,
              isCurrency: true,
              validator: _validatePrice,
            ),

            const SizedBox(height: 16),

            GestureDetector(
              onTap: _showBuyerSelectionSheet,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedBuyer == null
                        ? Colors.pinkAccent.withOpacity(0.5)
                        : Colors.white10,
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
                              : 'https://i.pravatar.cc/150?u=${_selectedBuyer!.accountId}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedBuyer!.fullName.isNotEmpty
                                  ? _selectedBuyer!.fullName
                                  : _selectedBuyer!.username,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '@${_selectedBuyer!.username}',
                              style: const TextStyle(
                                color: Colors.pinkAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.swap_horiz, color: Colors.black),
                    ] else ...[
                      const Icon(
                        Icons.person_add_alt_1,
                        color: Colors.pinkAccent,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Select buyer from followers',
                        style: TextStyle(
                          color: Colors.pinkAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.pinkAccent,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            _buildSectionTitle('Receiver Information'),

            _buildTextField(
              controller: _receiverNameController,
              label: 'Receiver name',
              type: TextInputType.text,
              validator: _validateReceiverName,
            ),

            const SizedBox(height: 16),

            _buildTextField(
              controller: _receiverPhoneController,
              label: 'Phone number',
              type: TextInputType.phone,
              validator: _validatePhone,
            ),

            const SizedBox(height: 16),

            TypeAheadField<String>(
              controller: _shippingAddressController,
              debounceDuration: const Duration(milliseconds: 500),
              suggestionsCallback: (pattern) async {
                final keyword = pattern.trim();

                if (keyword.length < 3) {
                  return [];
                }

                return await _locationService.searchAddress(keyword);
              },
              itemBuilder: (context, String suggestion) {
                return ListTile(
                  tileColor: AppColors.background,
                  leading: const Icon(
                    Icons.location_on_outlined,
                    color: Colors.pinkAccent,
                  ),
                  title: Text(
                    suggestion,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                    ),
                  ),
                );
              },
              onSelected: (String selection) {
                _shippingAddressController.text = selection.trim();
              },
              loadingBuilder: (context) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.pinkAccent,
                    ),
                  ),
                );
              },
              emptyBuilder: (context) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No matching address found',
                    style: TextStyle(color: Colors.black54),
                  ),
                );
              },
              builder: (context, controller, focusNode) {
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Shipping address',
                    labelStyle: const TextStyle(color: Colors.black54),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.05),
                    prefixIcon: const Icon(
                      Icons.map_outlined,
                      color: Colors.black54,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.pinkAccent,
                        width: 1.5,
                      ),
                    ),
                  ),
                  validator: _validateAddress,
                );
              },
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: _isLoading ? null : _submitOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Text(
                'Create and send order',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
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
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required TextInputType type,
    bool isCurrency = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      style: const TextStyle(color: Colors.black),
      onChanged: isCurrency ? _formatCurrencyInput : null,
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.pinkAccent,
            width: 1.5,
          ),
        ),
      ),
      validator: validator,
    );
  }
}