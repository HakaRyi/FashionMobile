import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../managers/item_manager.dart';
import '../models/item_variant_model.dart';
import '../utils/app_toast.dart';

class ManageItemVariantsScreen extends StatefulWidget {
  final int itemId;
  final String itemName;

  const ManageItemVariantsScreen({
    super.key,
    required this.itemId,
    required this.itemName,
  });

  @override
  State<ManageItemVariantsScreen> createState() =>
      _ManageItemVariantsScreenState();
}

class _ManageItemVariantsScreenState extends State<ManageItemVariantsScreen> {
  static const Color _pageBackground = Color(0xFFFAF8F5);
  static const Color _cardBackground = Colors.white;
  static const Color _softBackground = Color(0xFFF4F1ED);
  static const Color _darkText = Color(0xFF111111);
  static const Color _mutedText = Color(0xFF6F6A64);
  static const Color _borderColor = Color(0xFFE8E1D8);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<ItemManager>().loadItemVariants(widget.itemId);
    });
  }

  String _formatPrice(double value) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return '${formatter.format(value)} VND';
  }

  int _safeStatus(ItemVariantModel variant) {
    return variant.status;
  }

  String _statusText(int status) {
    switch (status) {
      case 0:
        return 'Inactive';
      case 1:
        return 'Active';
      case 2:
        return 'Out of stock';
      case 3:
        return 'Archived';
      case 4:
        return 'Deleted';
      default:
        return 'Unknown';
    }
  }

  Color _statusColor(int status) {
    switch (status) {
      case 1:
        return const Color(0xFF1F9D55);
      case 2:
        return const Color(0xFFE88B00);
      case 0:
        return Colors.black45;
      case 3:
      case 4:
        return Colors.redAccent;
      default:
        return Colors.black38;
    }
  }

  bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  Future<void> _openVariantForm({ItemVariantModel? variant}) async {
    final manager = context.read<ItemManager>();

    final bool? saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _VariantFormSheet(
          itemId: widget.itemId,
          variant: variant,
          manager: manager,
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (saved == true) {
      AppToast.show(
        context,
        variant == null
            ? 'Variant has been created.'
            : 'Variant has been updated.',
      );
    }
  }

  Future<void> _deleteVariant(ItemVariantModel variant) async {
    final bool hasReserved = variant.reservedQuantity > 0;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Delete variant?',
            style: TextStyle(
              color: _darkText,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            hasReserved
                ? 'This variant has reserved quantity. The server may block deletion until related orders are completed or cancelled.'
                : 'This will remove ${variant.sizeCode ?? 'Default'}'
                '${_hasText(variant.color) ? ' - ${variant.color}' : ''} from this item.',
            style: const TextStyle(
              color: _mutedText,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'CANCEL',
                style: TextStyle(
                  color: Colors.black38,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'DELETE',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final manager = context.read<ItemManager>();
    final success = await manager.deleteVariant(variant.itemVariantId);

    if (!mounted) {
      return;
    }

    if (success) {
      AppToast.show(context, 'Variant has been deleted.');
      return;
    }

    AppToast.show(
      context,
      manager.errorMessage ?? 'Failed to delete variant.',
      isError: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<ItemManager>();

    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: _pageBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: const Text(
          'VARIANTS',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 0.4,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: manager.isLoading ? null : () => _openVariantForm(),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 5,
        icon: const Icon(Icons.add),
        label: const Text(
          'ADD VARIANT',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => manager.loadItemVariants(widget.itemId),
        color: Colors.black,
        backgroundColor: Colors.white,
        child: manager.isLoading && manager.variants.isEmpty
            ? const Center(
          child: CircularProgressIndicator(
            color: Colors.black,
          ),
        )
            : manager.errorMessage != null && manager.variants.isEmpty
            ? _buildError(manager)
            : manager.variants.isEmpty
            ? _buildEmpty()
            : ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            _buildHeaderCard(manager.variants),
            const SizedBox(height: 14),
            ...manager.variants.map(_buildVariantCard),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(List<ItemVariantModel> variants) {
    final totalStock = variants.fold<int>(
      0,
          (sum, variant) => sum + variant.stockQuantity,
    );

    final totalAvailable = variants.fold<int>(
      0,
          (sum, variant) => sum + variant.availableQuantity,
    );

    final activeCount = variants.where((variant) => variant.status == 1).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MANAGE VARIANTS',
            style: TextStyle(
              color: _darkText,
              fontWeight: FontWeight.w900,
              fontSize: 15,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            widget.itemName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _mutedText,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildSummaryBox(
                  label: 'Variants',
                  value: variants.length.toString(),
                  icon: Icons.category_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryBox(
                  label: 'Active',
                  value: activeCount.toString(),
                  icon: Icons.check_circle_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSummaryBox(
                  label: 'Stock',
                  value: totalStock.toString(),
                  icon: Icons.inventory_2_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryBox(
                  label: 'Available',
                  value: totalAvailable.toString(),
                  icon: Icons.shopping_bag_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBox({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _softBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.black,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: _darkText,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black45,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantCard(ItemVariantModel variant) {
    final status = _safeStatus(variant);
    final available = variant.availableQuantity;
    final bool isBlockedDelete = variant.reservedQuantity > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(15, 14, 15, 12),
            decoration: BoxDecoration(
              color: status == 1
                  ? Colors.white
                  : status == 2
                  ? const Color(0xFFFFF7E8)
                  : const Color(0xFFF7F7F7),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    variant.sizeCode ?? '-',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${variant.sizeCode ?? 'Default'}'
                            '${_hasText(variant.color) ? ' - ${variant.color}' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _darkText,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _hasText(variant.sku)
                            ? 'SKU: ${variant.sku}'
                            : 'SKU: N/A',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black45,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildStatusBadge(status),
                          if (isBlockedDelete) ...[
                            const SizedBox(width: 6),
                            _buildSmallBadge(
                              text: 'Reserved',
                              color: Colors.redAccent,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _openVariantForm(variant: variant),
                  icon: const Icon(Icons.edit_outlined),
                  color: Colors.black,
                  tooltip: 'Edit variant',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 13, 15, 15),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        label: 'SKU',
                        value: _hasText(variant.sku) ? variant.sku : 'N/A',
                        icon: Icons.qr_code_2_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Price',
                        value: _formatPrice(variant.price),
                        icon: Icons.payments_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Available',
                        value: available.toString(),
                        icon: Icons.shopping_bag_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Stock',
                        value: variant.stockQuantity.toString(),
                        icon: Icons.inventory_2_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Reserved',
                        value: variant.reservedQuantity.toString(),
                        icon: Icons.lock_outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openVariantForm(variant: variant),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text(
                          'UPDATE',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black,
                          side: const BorderSide(
                            color: Colors.black,
                            width: 1.1,
                          ),
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _deleteVariant(variant),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text(
                          'DELETE',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isBlockedDelete
                              ? Colors.redAccent.withOpacity(0.55)
                              : Colors.redAccent,
                          side: BorderSide(
                            color: isBlockedDelete
                                ? Colors.redAccent.withOpacity(0.35)
                                : Colors.redAccent,
                            width: 1.1,
                          ),
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(int status) {
    return _buildSmallBadge(
      text: _statusText(status),
      color: _statusColor(status),
    );
  }

  Widget _buildSmallBadge({
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withOpacity(0.35),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: _softBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.black54,
            size: 17,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _darkText,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black45,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ItemManager manager) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.black,
                size: 46,
              ),
              const SizedBox(height: 12),
              const Text(
                'Failed to load variants',
                style: TextStyle(
                  color: _darkText,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                manager.errorMessage ?? 'Unknown error.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _mutedText,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => manager.loadItemVariants(widget.itemId),
                  style: _primaryButtonStyle(),
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
      ],
    );
  }

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              const Icon(
                Icons.category_outlined,
                color: Colors.black,
                size: 46,
              ),
              const SizedBox(height: 12),
              const Text(
                'No variants yet',
                style: TextStyle(
                  color: _darkText,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add at least one variant before publishing this item for sale.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _mutedText,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openVariantForm(),
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'ADD VARIANT',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                  style: _primaryButtonStyle(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      disabledBackgroundColor: const Color(0xFFE6E1DA),
      disabledForegroundColor: Colors.black38,
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: _cardBackground,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: _borderColor,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.045),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}

class _VariantFormSheet extends StatefulWidget {
  final int itemId;
  final ItemVariantModel? variant;
  final ItemManager manager;

  const _VariantFormSheet({
    required this.itemId,
    required this.variant,
    required this.manager,
  });

  @override
  State<_VariantFormSheet> createState() => _VariantFormSheetState();
}

class _VariantFormSheetState extends State<_VariantFormSheet> {
  static const Color _softBackground = Color(0xFFF4F1ED);
  static const Color _darkText = Color(0xFF111111);
  static const Color _mutedText = Color(0xFF6F6A64);
  static const Color _borderColor = Color(0xFFE8E1D8);

  static const double _minPrice = 1000;
  static const double _maxPrice = 100000000;
  static const int _maxStock = 999;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _colorController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;

  String _selectedSize = 'Free Size';
  int _selectedStatus = 1;

  bool _isSubmitting = false;
  bool _showSizeOptions = true;
  bool _showColorOptions = false;

  final List<String> _sizeOptions = const [
    'Free Size',
    'XS',
    'S',
    'M',
    'L',
    'XL',
    'XXL',
    'XXXL',
    '35',
    '36',
    '37',
    '38',
    '39',
    '40',
    '41',
    '42',
    '43',
    '44',
    '45',
  ];

  final List<String> _colorOptions = const [
    'Black',
    'White',
    'Gray',
    'Blue',
    'Navy',
    'Brown',
    'Beige',
    'Cream',
    'Red',
    'Pink',
    'Green',
    'Yellow',
    'Purple',
    'Orange',
    'Denim',
    'Multi-color',
  ];

  final Map<String, Color> _colorPreviewMap = const {
    'Black': Colors.black,
    'White': Colors.white,
    'Gray': Colors.grey,
    'Blue': Colors.blue,
    'Navy': Color(0xFF0B1F4D),
    'Brown': Color(0xFF795548),
    'Beige': Color(0xFFD8C3A5),
    'Cream': Color(0xFFFFF2CC),
    'Red': Colors.red,
    'Pink': Colors.pinkAccent,
    'Green': Colors.green,
    'Yellow': Colors.amber,
    'Purple': Colors.purple,
    'Orange': Colors.orange,
    'Denim': Color(0xFF315B8C),
    'Multi-color': Colors.black54,
  };

  bool get _isEdit => widget.variant != null;

  @override
  void initState() {
    super.initState();

    final variant = widget.variant;

    _selectedSize = _normalizeSize(variant?.sizeCode);
    _selectedStatus = _isEdit ? variant!.status : 1;

    if (_selectedStatus == 2 || _selectedStatus == 3 || _selectedStatus == 4) {
      _selectedStatus = 1;
    }

    _colorController = TextEditingController(
      text: variant?.color ?? '',
    );

    _priceController = TextEditingController(
      text: _isEdit ? variant!.price.toStringAsFixed(0) : '',
    );

    _stockController = TextEditingController(
      text: _isEdit ? variant!.stockQuantity.toString() : '1',
    );
  }

  @override
  void dispose() {
    _colorController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  String _formatPrice(double value) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return '${formatter.format(value)} VND';
  }

  String _normalizeSize(String? value) {
    final text = value?.trim();

    if (text == null || text.isEmpty) {
      return 'Free Size';
    }

    if (_sizeOptions.contains(text)) {
      return text;
    }

    return 'Free Size';
  }

  String _normalizeTextKey(String? value) {
    return (value ?? '')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .toLowerCase();
  }

  double? _parsePrice(String value) {
    final normalized = value.trim().replaceAll(',', '');
    return double.tryParse(normalized);
  }

  int? _parseStock(String value) {
    return int.tryParse(value.trim());
  }

  bool _isDuplicateVariant({
    required String sizeCode,
    required String color,
    int? ignoredVariantId,
  }) {
    final newSize = _normalizeTextKey(sizeCode);
    final newColor = _normalizeTextKey(color);

    return widget.manager.variants.any((variant) {
      if (ignoredVariantId != null &&
          variant.itemVariantId == ignoredVariantId) {
        return false;
      }

      final oldSize = _normalizeTextKey(variant.sizeCode);
      final oldColor = _normalizeTextKey(variant.color);

      return oldSize == newSize && oldColor == newColor;
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final variant = widget.variant;
    final color = _colorController.text.trim();
    final price = _parsePrice(_priceController.text);
    final stock = _parseStock(_stockController.text);

    if (color.length > 30) {
      AppToast.show(
        context,
        'Color must not exceed 30 characters.',
        isError: true,
      );
      return;
    }

    if (color.isNotEmpty &&
        !RegExp(r"^[a-zA-ZÀ-ỹ0-9\s\-\/]+$").hasMatch(color)) {
      AppToast.show(
        context,
        'Color contains invalid characters.',
        isError: true,
      );
      return;
    }

    if (price == null || price < _minPrice) {
      AppToast.show(
        context,
        'Price must be at least ${_formatPrice(_minPrice)}.',
        isError: true,
      );
      return;
    }

    if (price > _maxPrice) {
      AppToast.show(
        context,
        'Price must not exceed ${_formatPrice(_maxPrice)}.',
        isError: true,
      );
      return;
    }

    if (stock == null || stock < 0) {
      AppToast.show(
        context,
        'Stock quantity cannot be negative.',
        isError: true,
      );
      return;
    }

    if (stock > _maxStock) {
      AppToast.show(
        context,
        'Stock cannot exceed $_maxStock.',
        isError: true,
      );
      return;
    }

    if (_isEdit &&
        variant!.reservedQuantity > 0 &&
        stock < variant.reservedQuantity) {
      AppToast.show(
        context,
        'Stock cannot be less than reserved quantity.',
        isError: true,
      );
      return;
    }

    if (_isDuplicateVariant(
      sizeCode: _selectedSize,
      color: color,
      ignoredVariantId: variant?.itemVariantId,
    )) {
      AppToast.show(
        context,
        'Duplicate variant size and color.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    bool success;

    if (_isEdit) {
      success = await widget.manager.updateVariant(
        itemVariantId: variant!.itemVariantId,
        sizeCode: _selectedSize,
        color: color.isEmpty ? null : color,
        price: price,
        stockQuantity: stock,
        status: _selectedStatus,
      );
    } else {
      success = await widget.manager.createVariant(
        itemId: widget.itemId,
        sizeCode: _selectedSize,
        color: color.isEmpty ? null : color,
        price: price,
        stockQuantity: stock,
      );
    }

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.pop(context, true);
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    AppToast.show(
      context,
      widget.manager.errorMessage ?? 'Failed to save variant.',
      isError: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSubmitting,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(30),
              ),
            ),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 46,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildFormHeader(),
                    const SizedBox(height: 20),

                    _buildOptionToggleHeader(
                      title: 'Choose size',
                      subtitle: 'Current: $_selectedSize',
                      icon: Icons.straighten_outlined,
                      isOpen: _showSizeOptions,
                      onTap: () {
                        setState(() {
                          _showSizeOptions = !_showSizeOptions;
                        });
                      },
                    ),
                    AnimatedCrossFade(
                      firstChild: const SizedBox(width: double.infinity),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: _buildSizeOptions(),
                      ),
                      crossFadeState: _showSizeOptions
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 180),
                    ),

                    const SizedBox(height: 16),

                    _buildOptionToggleHeader(
                      title: 'Choose color',
                      subtitle: _colorController.text.trim().isEmpty
                          ? 'No color selected'
                          : 'Current: ${_colorController.text.trim()}',
                      icon: Icons.palette_outlined,
                      isOpen: _showColorOptions,
                      onTap: () {
                        setState(() {
                          _showColorOptions = !_showColorOptions;
                        });
                      },
                    ),
                    AnimatedCrossFade(
                      firstChild: const SizedBox(width: double.infinity),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: _buildColorOptions(),
                      ),
                      crossFadeState: _showColorOptions
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 180),
                    ),

                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _colorController,
                      label: 'Custom color',
                      icon: Icons.edit_outlined,
                      hint: 'Example: Black/White',
                      enabled: !_isSubmitting,
                      maxLength: 30,
                      onChanged: (_) {
                        setState(() {});
                      },
                      validator: (value) {
                        final color = value?.trim() ?? '';

                        if (color.length > 30) {
                          return 'Max 30 characters.';
                        }

                        if (color.isNotEmpty &&
                            !RegExp(r"^[a-zA-ZÀ-ỹ0-9\s\-\/]+$")
                                .hasMatch(color)) {
                          return 'Invalid color.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    _buildFormSectionTitle(
                      title: 'Price and stock',
                      icon: Icons.inventory_2_outlined,
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _priceController,
                            label: 'Price',
                            icon: Icons.payments_outlined,
                            hint: '150000',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(9),
                            ],
                            enabled: !_isSubmitting,
                            validator: (value) {
                              final price = _parsePrice(value ?? '');

                              if (price == null) {
                                return 'Invalid price.';
                              }

                              if (price < _minPrice) {
                                return 'Min 1,000.';
                              }

                              if (price > _maxPrice) {
                                return 'Too high.';
                              }

                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTextField(
                            controller: _stockController,
                            label: 'Stock',
                            icon: Icons.inventory_2_outlined,
                            hint: '1',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(3),
                            ],
                            enabled: !_isSubmitting,
                            validator: (value) {
                              final stock = _parseStock(value ?? '');

                              if (stock == null) {
                                return 'Invalid stock.';
                              }

                              if (stock < 0) {
                                return 'Stock >= 0.';
                              }

                              if (stock > _maxStock) {
                                return 'Max $_maxStock.';
                              }

                              if (_isEdit &&
                                  widget.variant!.reservedQuantity > 0 &&
                                  stock < widget.variant!.reservedQuantity) {
                                return 'Min ${widget.variant!.reservedQuantity}.';
                              }

                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    if (_isEdit) ...[
                      const SizedBox(height: 18),
                      _buildStatusSwitch(),
                    ],

                    const SizedBox(height: 22),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: _primaryButtonStyle(),
                        child: _isSubmitting
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          _isEdit ? 'SAVE CHANGES' : 'CREATE VARIANT',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormHeader() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            _isEdit ? Icons.edit_outlined : Icons.add_box_outlined,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEdit ? 'Edit variant' : 'Add variant',
                style: const TextStyle(
                  color: _darkText,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _isEdit
                    ? 'Update size, color, price, stock or status.'
                    : 'Create a sellable option for this item.',
                style: const TextStyle(
                  color: _mutedText,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOptionToggleHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isOpen,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isSubmitting ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: _softBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _borderColor,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _borderColor,
                ),
              ),
              child: Icon(
                icon,
                color: Colors.black,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _darkText,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black45,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isOpen
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: Colors.black,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSectionTitle({
    required String title,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _softBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _borderColor,
            ),
          ),
          child: Icon(
            icon,
            color: Colors.black,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _darkText,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSizeOptions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _sizeOptions.map((size) {
        final bool selected = _selectedSize == size;

        return GestureDetector(
          onTap: _isSubmitting
              ? null
              : () {
            setState(() {
              _selectedSize = size;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: selected ? Colors.black : _softBackground,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? Colors.black : _borderColor,
                width: 1.1,
              ),
            ),
            child: Text(
              size,
              style: TextStyle(
                color: selected ? Colors.white : _darkText,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildColorOptions() {
    final currentColor = _normalizeTextKey(_colorController.text);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _colorOptions.map((colorName) {
        final bool selected = currentColor == _normalizeTextKey(colorName);
        final previewColor = _colorPreviewMap[colorName] ?? Colors.black45;
        final bool needsBorder = colorName == 'White' ||
            colorName == 'Cream' ||
            colorName == 'Beige';

        return GestureDetector(
          onTap: _isSubmitting
              ? null
              : () {
            setState(() {
              _colorController.text = colorName;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: selected ? Colors.black : _softBackground,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? Colors.black : _borderColor,
                width: 1.1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: previewColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: needsBorder ? Colors.black26 : Colors.transparent,
                    ),
                  ),
                  child: colorName == 'Multi-color'
                      ? const Icon(
                    Icons.auto_awesome,
                    size: 10,
                    color: Colors.white,
                  )
                      : null,
                ),
                const SizedBox(width: 7),
                Text(
                  colorName,
                  style: TextStyle(
                    color: selected ? Colors.white : _darkText,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusSwitch() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _softBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _selectedStatus == 1
                  ? const Color(0xFF1F9D55).withOpacity(0.12)
                  : Colors.black.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _selectedStatus == 1
                  ? Icons.check_circle_outline
                  : Icons.pause_circle_outline,
              color: _selectedStatus == 1
                  ? const Color(0xFF1F9D55)
                  : Colors.black45,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedStatus == 1 ? 'Active' : 'Inactive',
                  style: const TextStyle(
                    color: _darkText,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _selectedStatus == 1
                      ? 'This variant can be shown for sale if it has available stock.'
                      : 'This variant is hidden from sale.',
                  style: const TextStyle(
                    color: Colors.black45,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _selectedStatus == 1,
            activeColor: Colors.black,
            inactiveThumbColor: Colors.black45,
            inactiveTrackColor: Colors.black12,
            onChanged: _isSubmitting
                ? null
                : (value) {
              setState(() {
                _selectedStatus = value ? 1 : 0;
              });
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
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
    bool enabled = true,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      enabled: enabled,
      maxLength: maxLength,
      style: const TextStyle(
        color: _darkText,
        fontWeight: FontWeight.w600,
      ),
      decoration: _inputDecoration(
        label: label,
        icon: icon,
        hint: hint,
      ),
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
      counterText: '',
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
      fillColor: _softBackground,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: _borderColor,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: _borderColor,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.black,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      disabledBackgroundColor: const Color(0xFFE6E1DA),
      disabledForegroundColor: Colors.black38,
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}