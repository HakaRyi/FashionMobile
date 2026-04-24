import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../managers/item_manager.dart';
import '../models/wardrobe_item_model.dart';
import '../utils/app_toast.dart';

class PublishItemForSaleScreen extends StatefulWidget {
  final WardrobeItemModel item;

  const PublishItemForSaleScreen({
    super.key,
    required this.item,
  });

  @override
  State<PublishItemForSaleScreen> createState() =>
      _PublishItemForSaleScreenState();
}

class _PublishItemForSaleScreenState extends State<PublishItemForSaleScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _listedPriceController = TextEditingController();
  final List<_VariantFormController> _variantControllers = [];

  String _selectedCondition = 'Used - Good';

  final List<String> _conditionOptions = const [
    'New',
    'Used - Like New',
    'Used - Good',
    'Used - Fair',
  ];

  @override
  void initState() {
    super.initState();

    if (widget.item.listedPrice != null && widget.item.listedPrice! > 0) {
      _listedPriceController.text = widget.item.listedPrice!.toStringAsFixed(0);
    }

    if (widget.item.condition != null &&
        widget.item.condition!.trim().isNotEmpty &&
        _conditionOptions.contains(widget.item.condition)) {
      _selectedCondition = widget.item.condition!;
    }

    _addVariant();
  }

  @override
  void dispose() {
    _listedPriceController.dispose();

    for (final controller in _variantControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  void _addVariant() {
    final int index = _variantControllers.length + 1;

    final controller = _VariantFormController(
      sku: 'ITEM-${widget.item.itemId}-$index',
      sizeCode: widget.item.size ?? '',
      color: widget.item.mainColor ?? '',
      stockQuantity: '1',
    );

    setState(() {
      _variantControllers.add(controller);
    });
  }

  void _removeVariant(int index) {
    if (_variantControllers.length <= 1) {
      AppToast.show(context, 'At least one variant is required.');
      return;
    }

    final removed = _variantControllers.removeAt(index);
    removed.dispose();

    setState(() {});
  }

  double? _parsePrice(String value) {
    final cleanedValue = value.trim().replaceAll(',', '');
    return double.tryParse(cleanedValue);
  }

  int? _parseStock(String value) {
    return int.tryParse(value.trim());
  }

  String _formatPrice(double? value) {
    if (value == null) {
      return '';
    }

    final formatter = NumberFormat('#,##0', 'en_US');
    return '${formatter.format(value)} VND';
  }

  bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  Future<void> _publishItem() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final double? listedPrice = _parsePrice(_listedPriceController.text);

    if (listedPrice == null || listedPrice <= 0) {
      AppToast.show(context, 'Listed price must be greater than 0.');
      return;
    }

    final List<Map<String, dynamic>> variantsPayload = [];

    for (final controller in _variantControllers) {
      final String sku = controller.skuController.text.trim();
      final String sizeCode = controller.sizeController.text.trim();
      final String color = controller.colorController.text.trim();
      final double? price = _parsePrice(controller.priceController.text);
      final int? stockQuantity = _parseStock(controller.stockController.text);

      if (sku.isEmpty) {
        AppToast.show(context, 'SKU is required.');
        return;
      }

      if (price == null || price <= 0) {
        AppToast.show(context, 'Variant price must be greater than 0.');
        return;
      }

      if (stockQuantity == null || stockQuantity < 0) {
        AppToast.show(context, 'Stock quantity cannot be negative.');
        return;
      }

      variantsPayload.add({
        'sku': sku,
        'sizeCode': sizeCode.isEmpty ? null : sizeCode,
        'color': color.isEmpty ? null : color,
        'price': price,
        'stockQuantity': stockQuantity,
      });
    }

    final List<String> skuList = variantsPayload
        .map((variant) => variant['sku'].toString().trim().toLowerCase())
        .toList();

    if (skuList.length != skuList.toSet().length) {
      AppToast.show(context, 'Duplicate SKU is not allowed.');
      return;
    }

    final manager = context.read<ItemManager>();

    final bool success = await manager.publishItem(
      itemId: widget.item.itemId,
      listedPrice: listedPrice,
      condition: _selectedCondition,
      variantsPayload: variantsPayload,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      AppToast.show(context, 'Item has been published for sale.');
      Navigator.pop(context, true);
      return;
    }

    AppToast.show(
      context,
      manager.errorMessage ?? 'Failed to publish item.',
      isError: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<ItemManager>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        surfaceTintColor: Colors.transparent,
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
          'SELL ITEM',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 17,
            letterSpacing: 0.4,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              _buildItemPreview(),
              const SizedBox(height: 16),
              _buildSaleInformationSection(),
              const SizedBox(height: 20),
              _buildVariantHeader(),
              const SizedBox(height: 12),
              ...List.generate(
                _variantControllers.length,
                    (index) => _buildVariantCard(index),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: manager.isLoading ? null : _publishItem,
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
                  child: manager.isLoading
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.3,
                    ),
                  )
                      : const Text(
                    'PUBLISH FOR SALE',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.4,
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

  Widget _buildItemPreview() {
    final String? imageUrl = widget.item.imageUrl;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: !_hasText(imageUrl)
                ? Container(
              width: 86,
              height: 86,
              color: const Color(0xFFF1F1F1),
              child: const Icon(
                Icons.checkroom_outlined,
                color: Colors.black26,
                size: 34,
              ),
            )
                : Image.network(
              imageUrl!,
              width: 86,
              height: 86,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Container(
                  width: 86,
                  height: 86,
                  color: const Color(0xFFF1F1F1),
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.black26,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ITEM',
                  style: TextStyle(
                    color: Colors.black38,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.item.itemName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 8),
                if (_hasText(widget.item.category))
                  Text(
                    widget.item.category!,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (_hasText(widget.item.size))
                      _buildSmallTag(widget.item.size!),
                    if (_hasText(widget.item.mainColor))
                      _buildSmallTag(widget.item.mainColor!),
                    if (_hasText(widget.item.brand))
                      _buildSmallTag(widget.item.brand!),
                    if (widget.item.isForSale) _buildSmallTag('For Sale'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleInformationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'SALE INFORMATION',
            Icons.storefront_outlined,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _listedPriceController,
            label: 'Listed price',
            hint: 'Example: 150000',
            icon: Icons.sell_outlined,
            keyboardType: TextInputType.number,
            validator: (value) {
              final price = _parsePrice(value ?? '');

              if (price == null) {
                return 'Please enter a valid price.';
              }

              if (price <= 0) {
                return 'Listed price must be greater than 0.';
              }

              return null;
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedCondition,
            dropdownColor: Colors.white,
            decoration: _inputDecoration(
              label: 'Condition',
              icon: Icons.verified_outlined,
            ),
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
            items: _conditionOptions.map((condition) {
              return DropdownMenuItem<String>(
                value: condition,
                child: Text(condition),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                _selectedCondition = value;
              });
            },
          ),
          const SizedBox(height: 12),
          const Text(
            'This item will be visible in the public marketplace after publishing.',
            style: TextStyle(
              color: Colors.black45,
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'VARIANTS',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: _addVariant,
          icon: const Icon(Icons.add),
          label: const Text(
            'Add variant',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
          style: TextButton.styleFrom(
            foregroundColor: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildVariantCard(int index) {
    final controller = _variantControllers[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _sectionTitle(
                  'VARIANT ${index + 1}',
                  Icons.category_outlined,
                ),
              ),
              IconButton(
                onPressed: () => _removeVariant(index),
                icon: const Icon(Icons.delete_outline),
                color: Colors.redAccent,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildTextField(
            controller: controller.skuController,
            label: 'SKU',
            hint: 'Example: ITEM-1-M',
            icon: Icons.qr_code_2_outlined,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'SKU is required.';
              }

              return null;
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: controller.sizeController,
                  label: 'Size',
                  hint: 'M',
                  icon: Icons.straighten_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTextField(
                  controller: controller.colorController,
                  label: 'Color',
                  hint: 'Black',
                  icon: Icons.palette_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: controller.priceController,
                  label: 'Price',
                  hint: '150000',
                  icon: Icons.payments_outlined,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final price = _parsePrice(value ?? '');

                    if (price == null) {
                      return 'Invalid price.';
                    }

                    if (price <= 0) {
                      return 'Price must be greater than 0.';
                    }

                    return null;
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTextField(
                  controller: controller.stockController,
                  label: 'Stock',
                  hint: '1',
                  icon: Icons.inventory_2_outlined,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final stock = _parseStock(value ?? '');

                    if (stock == null) {
                      return 'Invalid stock.';
                    }

                    if (stock < 0) {
                      return 'Stock cannot be negative.';
                    }

                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Builder(
            builder: (_) {
              final price = _parsePrice(controller.priceController.text);

              if (price == null || price <= 0) {
                return const SizedBox.shrink();
              }

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.black.withOpacity(0.04),
                  ),
                ),
                child: Text(
                  'Variant price: ${_formatPrice(price)}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w600,
      ),
      decoration: _inputDecoration(
        label: label,
        hint: hint,
        icon: icon,
      ),
      onChanged: (_) {
        setState(() {});
      },
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(
        color: Colors.black45,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: const TextStyle(
        color: Colors.black26,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(
        icon,
        color: Colors.black,
      ),
      filled: true,
      fillColor: const Color(0xFFF7F7F7),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.black.withOpacity(0.06),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.black,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
    );
  }

  Widget _buildSmallTag(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.black.withOpacity(0.05),
        ),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
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
            letterSpacing: 0.4,
          ),
        ),
      ],
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

class _VariantFormController {
  final TextEditingController skuController;
  final TextEditingController sizeController;
  final TextEditingController colorController;
  final TextEditingController priceController;
  final TextEditingController stockController;

  _VariantFormController({
    required String sku,
    required String sizeCode,
    required String color,
    required String stockQuantity,
  })  : skuController = TextEditingController(text: sku),
        sizeController = TextEditingController(text: sizeCode),
        colorController = TextEditingController(text: color),
        priceController = TextEditingController(),
        stockController = TextEditingController(text: stockQuantity);

  void dispose() {
    skuController.dispose();
    sizeController.dispose();
    colorController.dispose();
    priceController.dispose();
    stockController.dispose();
  }
}