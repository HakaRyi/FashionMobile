import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<ItemManager>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        title: const Text(
          'Sell Item',
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _buildItemPreview(),
              const SizedBox(height: 20),
              _buildSaleInformationSection(),
              const SizedBox(height: 22),
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
                    backgroundColor: AppColors.textPink,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.white10,
                    disabledForegroundColor: Colors.white38,
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
                    'Publish for Sale',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
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
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: !_hasText(imageUrl)
                ? Container(
              width: 82,
              height: 82,
              color: AppColors.surface,
              child: const Icon(
                Icons.checkroom_outlined,
                color: Colors.white38,
                size: 34,
              ),
            )
                : Image.network(
              imageUrl!,
              width: 82,
              height: 82,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Container(
                  width: 82,
                  height: 82,
                  color: AppColors.surface,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white38,
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
                Text(
                  widget.item.itemName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 7),
                if (_hasText(widget.item.category))
                  Text(
                    widget.item.category!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                const SizedBox(height: 7),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sale Information',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
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
            dropdownColor: AppColors.backgroundSecondary,
            decoration: _inputDecoration(
              label: 'Condition',
              icon: Icons.verified_outlined,
            ),
            style: const TextStyle(color: AppColors.text),
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
          const SizedBox(height: 10),
          const Text(
            'This item will be visible in public marketplace after publishing.',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12,
              height: 1.4,
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
            'Variants',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: _addVariant,
          icon: const Icon(Icons.add),
          label: const Text('Add variant'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textPink,
          ),
        ),
      ],
    );
  }

  Widget _buildVariantCard(int index) {
    final controller = _variantControllers[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Variant ${index + 1}',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _removeVariant(index),
                icon: const Icon(Icons.delete_outline),
                color: Colors.redAccent,
              ),
            ],
          ),
          const SizedBox(height: 8),
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

              return Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Variant price: ${_formatPrice(price)}',
                  style: const TextStyle(
                    color: AppColors.textPink,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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
      style: const TextStyle(color: AppColors.text),
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
      labelStyle: const TextStyle(color: Colors.white60),
      hintStyle: const TextStyle(color: Colors.white30),
      prefixIcon: Icon(icon, color: AppColors.textPink),
      filled: true,
      fillColor: AppColors.surface,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.textPink),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  Widget _buildSmallTag(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.textPink.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.textPink.withOpacity(0.7)),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: AppColors.textPink,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
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