import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../services/item_service.dart';
import '../constants/fashion_constants.dart';
import '../widgets/fashion_autocomplete_field.dart';

class ClothingDetailScreen extends StatefulWidget {
  final Map<String, dynamic> itemData;
  final bool showEditButton;

  const ClothingDetailScreen({
    super.key,
    required this.itemData,
    this.showEditButton = true,
  });

  @override
  State<ClothingDetailScreen> createState() => _ClothingDetailScreenState();
}

class _ClothingDetailScreenState extends State<ClothingDetailScreen> {
  final ItemService _itemService = ItemService();

  bool _isEditing = false;
  bool _isSaving = false;

  late Map<String, dynamic> _itemData;
  late Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();

    _itemData = Map<String, dynamic>.from(widget.itemData);

    _controllers = {
      'itemName': TextEditingController(
        text: _itemData['itemName']?.toString() ?? '',
      ),
      'itemType': TextEditingController(
        text: _itemData['itemType']?.toString() ?? '',
      ),
      'category': TextEditingController(
        text: _itemData['category']?.toString() ?? '',
      ),
      'subCategory': TextEditingController(
        text: _itemData['subCategory']?.toString() ?? '',
      ),
      'gender': TextEditingController(
        text: _itemData['gender']?.toString() ?? '',
      ),
      'size': TextEditingController(
        text: _itemData['size']?.toString() ?? '',
      ),
      'mainColor': TextEditingController(
        text: _itemData['mainColor']?.toString() ?? '',
      ),
      'subColor': TextEditingController(
        text: _itemData['subColor']?.toString() ?? '',
      ),
      'material': TextEditingController(
        text: _itemData['material']?.toString() ?? '',
      ),
      'pattern': TextEditingController(
        text: _itemData['pattern']?.toString() ?? '',
      ),
      'style': TextEditingController(
        text: _itemData['style']?.toString() ?? '',
      ),
      'fit': TextEditingController(
        text: _itemData['fit']?.toString() ?? '',
      ),
      'neckline': TextEditingController(
        text: _itemData['neckline']?.toString() ?? '',
      ),
      'sleeveLength': TextEditingController(
        text: _itemData['sleeveLength']?.toString() ?? '',
      ),
      'length': TextEditingController(
        text: _itemData['length']?.toString() ?? '',
      ),
      'placement': TextEditingController(
        text: _itemData['placement']?.toString() ?? '',
      ),
      'brand': TextEditingController(
        text: _itemData['brand']?.toString() ?? '',
      ),
      'description': TextEditingController(
        text: _itemData['description']?.toString() ?? '',
      ),
      'texture': TextEditingController(
        text: _itemData['texture']?.toString() ?? '',
      ),
      'isPublic': TextEditingController(
        text: _itemData['isPublic']?.toString() ?? 'false',
      ),
      'status': TextEditingController(
        text: _itemData['status']?.toString() ?? '1',
      ),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() {
      _isSaving = true;
    });

    final Map<String, dynamic> updateData = {};

    _controllers.forEach((key, controller) {
      updateData[key] = controller.text.trim();
    });

    updateData['status'] = int.tryParse(_controllers['status']!.text) ?? 1;
    updateData['isPublic'] =
        _controllers['isPublic']!.text.toLowerCase() == 'true';

    try {
      await _itemService.updateItem(
        int.tryParse(_itemData['itemId'].toString()) ?? 0,
        updateData,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _itemData = {
          ..._itemData,
          ...updateData,
        };
        _isSaving = false;
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Updated successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_normalizeError(e)),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  String _normalizeError(Object error) {
    final text = error.toString();
    if (text.startsWith('Exception: ')) {
      return text.replaceFirst('Exception: ', '');
    }
    return text;
  }

  String _formatDate(dynamic rawDate) {
    if (rawDate == null) {
      return "N/A";
    }

    final dateStr = rawDate.toString().trim();
    if (dateStr.isEmpty || dateStr == "N/A") {
      return "N/A";
    }

    try {
      String timeStr = dateStr;
      if (!timeStr.endsWith('Z') && !timeStr.contains('+')) {
        timeStr = '${timeStr}Z';
      }

      final date = DateTime.parse(timeStr).toLocal();
      return DateFormat('MMM dd, yyyy • HH:mm').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildImageCard() {
    final imageUrl = _itemData['imageUrl']?.toString();

    return Container(
      width: double.infinity,
      height: 400,
      decoration: BoxDecoration(
        color: AppColors.menu,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
              imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) {
                return const Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    size: 64,
                    color: Colors.black38,
                  ),
                );
              },
            )
                : const Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                size: 64,
                color: Colors.black38,
              ),
            ),
          ),
          if (!_isEditing)
            Positioned(
              bottom: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: Colors.amber,
                      size: 14,
                    ),
                    SizedBox(width: 6),
                    Text(
                      "AI Tagged",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGroupTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 12,
        top: 8,
      ),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.pinkAccent.withOpacity(0.8),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildInfoRow(List<Widget> children) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children.map((widget) => Expanded(child: widget)).toList(),
    );
  }

  Widget _buildItemTile(
      String label,
      String key,
      IconData icon,
      ) {
    if (!_controllers.containsKey(key)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: FashionAutocompleteField(
        label: label,
        icon: icon,
        enabled: _isEditing,
        controller: _controllers[key]!,
        options: FashionConstants.categories[key] ?? [],
      ),
    );
  }

  Widget _buildSwitchTile(
      String label,
      String key,
      IconData icon,
      ) {
    final bool value = _controllers[key]!.text.toLowerCase() == "true";

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(
        icon,
        size: 20,
        color: Colors.pinkAccent.withOpacity(0.7),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: Colors.black.withOpacity(0.5),
          fontSize: 13,
        ),
      ),
      trailing: _isEditing
          ? SizedBox(
        height: 30,
        child: Switch(
          value: value,
          activeColor: Colors.pinkAccent,
          onChanged: (newValue) {
            setState(() {
              _controllers[key]!.text = newValue.toString();
            });
          },
        ),
      )
          : Text(
        value ? "YES" : "NO",
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusDropdownTile() {
    const statusMap = {
      "0": "Draft",
      "1": "Active",
      "2": "Inactive",
      "3": "Archived",
      "4": "Deleted",
    };

    final currentStatus = _controllers['status']!.text;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(
        Icons.check_box_outlined,
        size: 20,
        color: Colors.pinkAccent.withOpacity(0.7),
      ),
      title: Text(
        "Status",
        style: TextStyle(
          color: Colors.black.withOpacity(0.5),
          fontSize: 13,
        ),
      ),
      trailing: _isEditing
          ? DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: statusMap.containsKey(currentStatus)
              ? currentStatus
              : "1",
          dropdownColor: AppColors.surface,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
          ),
          items: statusMap.entries
              .map(
                (entry) => DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            ),
          )
              .toList(),
          onChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() {
              _controllers['status']!.text = value;
            });
          },
        ),
      )
          : Text(
        statusMap[currentStatus] ?? "Active",
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isEditing
            ? Colors.pinkAccent.withOpacity(0.02)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _isEditing
              ? Colors.pinkAccent.withOpacity(0.3)
              : Colors.black.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notes_rounded,
                size: 18,
                color: _isEditing
                    ? Colors.pinkAccent
                    : Colors.black26,
              ),
              const SizedBox(width: 8),
              Text(
                "Description",
                style: TextStyle(
                  color: Colors.black.withOpacity(0.4),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controllers['description'],
            enabled: _isEditing,
            maxLines: null,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              height: 1.5,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              hintText: "No description provided",
              hintStyle: TextStyle(color: Colors.black26),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoContainer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGroupTitle("BASIC INFO"),
        _buildInfoRow([
          _buildItemTile(
            "Category",
            "category",
            Icons.category_outlined,
          ),
          _buildItemTile(
            "Sub Category",
            "subCategory",
            Icons.account_tree_outlined,
          ),
        ]),
        _buildInfoRow([
          _buildItemTile(
            "Item Type",
            "itemType",
            Icons.merge_type_outlined,
          ),
          _buildItemTile(
            "Gender",
            "gender",
            Icons.wc,
          ),
        ]),
        _buildItemTile(
          "Item Name",
          "itemName",
          Icons.shopping_bag_outlined,
        ),
        const SizedBox(height: 20),
        _buildGroupTitle("DESIGN DETAILS"),
        _buildInfoRow([
          _buildItemTile(
            "Color",
            "mainColor",
            Icons.palette_outlined,
          ),
          _buildItemTile(
            "Sub Color",
            "subColor",
            Icons.palette_outlined,
          ),
          _buildItemTile(
            "Size",
            "size",
            Icons.format_size,
          ),
        ]),
        _buildInfoRow([
          _buildItemTile(
            "Style",
            "style",
            Icons.style_outlined,
          ),
          _buildItemTile(
            "Fit",
            "fit",
            Icons.accessibility_new_outlined,
          ),
        ]),
        _buildInfoRow([
          _buildItemTile(
            "Material",
            "material",
            Icons.texture_outlined,
          ),
          _buildItemTile(
            "Pattern",
            "pattern",
            Icons.grid_view_rounded,
          ),
        ]),
        _buildInfoRow([
          _buildItemTile(
            "Neckline",
            "neckline",
            Icons.line_weight,
          ),
          _buildItemTile(
            "Brand",
            "brand",
            Icons.branding_watermark_outlined,
          ),
        ]),
        _buildInfoRow([
          _buildItemTile(
            "Length",
            "length",
            Icons.filter_tilt_shift_rounded,
          ),
          _buildItemTile(
            "Sleeve",
            "sleeveLength",
            Icons.type_specimen_outlined,
          ),
        ]),
        const SizedBox(height: 20),
        _buildGroupTitle("STATUS & SETTINGS"),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.05),
            ),
          ),
          child: Column(
            children: [
              _buildSwitchTile(
                "Public Item",
                "isPublic",
                Icons.visibility_outlined,
              ),
              const Divider(
                color: Colors.white,
                height: 1,
                indent: 50,
              ),
              _buildStatusDropdownTile(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildDescriptionField(),
      ],
    );
  }

  Widget _buildTimelineSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _buildTimeRow(
            "Registered on",
            _formatDate(_itemData['createdAt']),
          ),
          const SizedBox(height: 10),
          _buildTimeRow(
            "Last update",
            _formatDate(_itemData['updateAt']),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.black.withOpacity(0.3),
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.w500,
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        title: Text(
          _isEditing ? "EDIT DETAILS" : "CLOTHING INFO",
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            color: Colors.black,
          ),
        ),
        actions: [
          if (widget.showEditButton)
            _isSaving
                ? const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.pinkAccent,
                  ),
                ),
              ),
            )
                : TextButton(
              onPressed: () {
                if (_isEditing) {
                  _handleSave();
                } else {
                  setState(() {
                    _isEditing = true;
                  });
                }
              },
              child: Text(
                _isEditing ? "SAVE" : "EDIT",
                style: const TextStyle(
                  color: Colors.pinkAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            _buildImageCard(),
            const SizedBox(height: 30),
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.pinkAccent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  "Attributes",
                  style: TextStyle(
                    color: Colors.pinkAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoContainer(),
            const SizedBox(height: 24),
            _buildTimelineSection(),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}