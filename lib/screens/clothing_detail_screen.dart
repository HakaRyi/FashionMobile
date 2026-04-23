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
  bool _isEditing = false;
  bool _isSaving = false;
  late Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _controllers = {
      'itemName': TextEditingController(text: widget.itemData['itemName']?.toString() ?? ""),
      'itemType': TextEditingController(text: widget.itemData['itemType']?.toString() ?? ""),
      'category': TextEditingController(text: widget.itemData['category']?.toString() ?? ""),
      'subCategory': TextEditingController(text: widget.itemData['subCategory']?.toString() ?? ""),
      'gender': TextEditingController(text: widget.itemData['gender']?.toString() ?? ""),
      'size': TextEditingController(text: widget.itemData['size']?.toString() ?? ""),
      'mainColor': TextEditingController(text: widget.itemData['mainColor']?.toString() ?? ""),
      'subColor': TextEditingController(text: widget.itemData['subColor']?.toString() ?? ""),
      'material': TextEditingController(text: widget.itemData['material']?.toString() ?? ""),
      'pattern': TextEditingController(text: widget.itemData['pattern']?.toString() ?? ""),
      'style': TextEditingController(text: widget.itemData['style']?.toString() ?? ""),
      'fit': TextEditingController(text: widget.itemData['fit']?.toString() ?? ""),
      'neckline': TextEditingController(text: widget.itemData['neckline']?.toString() ?? ""),
      'sleeveLength': TextEditingController(text: widget.itemData['sleeveLength']?.toString() ?? ""),
      'length': TextEditingController(text: widget.itemData['length']?.toString() ?? ""),
      'placement': TextEditingController(text: widget.itemData['placement']?.toString() ?? ""),
      'brand': TextEditingController(text: widget.itemData['brand']?.toString() ?? ""),
      'description': TextEditingController(text: widget.itemData['description']?.toString() ?? ""),
      'texture': TextEditingController(text: widget.itemData['texture']?.toString() ?? ""),
      'isPublic': TextEditingController(text: widget.itemData['isPublic']?.toString() ?? "false"),
      'status': TextEditingController(text: widget.itemData['status']?.toString() ?? "1"),
    };
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // Chức năng Hủy: Khôi phục lại dữ liệu như ban đầu
  void _handleCancel() {
    setState(() {
      _isEditing = false;
      _controllers.forEach((key, controller) {
        controller.text = widget.itemData[key]?.toString() ?? "";
      });
    });
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    final Map<String, dynamic> updateData = {};

    _controllers.forEach((key, controller) {
      updateData[key] = controller.text;
    });

    updateData["status"] = int.tryParse(_controllers['status']!.text) ?? 1;
    updateData["isPublic"] = _controllers['isPublic']!.text.toLowerCase() == "true";

    final success = await ItemService().updateItem(widget.itemData['itemId'], updateData);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        _showModernSnackBar("Updated successfully!", Icons.check_circle, Colors.greenAccent);
        setState(() {
          updateData.forEach((key, value) {
            widget.itemData[key] = value;
          });
          _isEditing = false;
        });
      } else {
        _showModernSnackBar("Update failed!", Icons.error_outline, Colors.redAccent);
      }
    }
  }

  // Custom Snackbar đẹp mắt hơn
  void _showModernSnackBar(String message, IconData icon, Color iconColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 10),
            Text(
              message,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2C2C2C), // Xám đen sang trọng
        behavior: SnackBarBehavior.floating, // Làm snackbar nổi lên
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr == "N/A") return "N/A";
    try {
      String timeStr = dateStr;
      if (!timeStr.endsWith('Z') && !timeStr.contains('+')) {
        timeStr += 'Z';
      }
      final DateTime date = DateTime.parse(timeStr).toLocal();
      return DateFormat('MMM dd, yyyy • HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        // Chuyển nút Hủy sang vị trí Leading khi đang edit
        leading: _isEditing
            ? IconButton(
          onPressed: _handleCancel,
          icon: const Icon(Icons.close, color: AppColors.textPrimary, size: 24),
          tooltip: "Cancel",
        )
            : IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
        ),
        centerTitle: true,
        title: Text(
          _isEditing ? "EDIT DETAILS" : "CLOTHING INFO",
          style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
              color: AppColors.textPrimary
          ),
        ),
        actions: [
          if (widget.showEditButton)
            _isSaving
                ? const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 20),
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)
                ),
              ),
            )
                : _isEditing
                ? TextButton(
              onPressed: _handleSave,
              child: const Text(
                "SAVE",
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0),
              ),
            )
                : TextButton(
              onPressed: () => setState(() => _isEditing = true),
              child: const Text(
                "EDIT",
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0),
              ),
            ),
        ],
      ),
      body: SafeArea(
        maintainBottomViewPadding: true,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            RepaintBoundary(child: _buildImageCard()),
            const SizedBox(height: 32),

            Row(
              children: [
                Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4)
                    )
                ),
                const SizedBox(width: 10),
                const Text(
                    "ATTRIBUTES",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    )
                ),
              ],
            ),
            const SizedBox(height: 8),

            ..._buildInfoWidgets(),

            const SizedBox(height: 24),
            _buildTimelineSection(),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard() {
    return Container(
      width: double.infinity,
      height: 400,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.stroke),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8)
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.network(
              widget.itemData['primaryImageUrl'] ?? '',
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.contain,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.image_not_supported_outlined, color: AppColors.textSecondary, size: 40)
              ),
            ),
          ),
          if (!_isEditing)
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(12)
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.amber, size: 14),
                    SizedBox(width: 6),
                    Text("AI Tagged", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildInfoWidgets() {
    return [
      _buildGroupTitle("BASIC INFO"),
      _buildTwoColumnRow([
        _buildItemTile("Category", "category", Icons.category_outlined),
        _buildItemTile("Sub Category", "subCategory", Icons.account_tree_outlined),
      ]),
      _buildTwoColumnRow([
        _buildItemTile("Item Type", "itemType", Icons.merge_type_outlined),
        _buildItemTile("Gender", "gender", Icons.wc),
      ]),
      _buildItemTile("Item Name", "itemName", Icons.shopping_bag_outlined),

      const SizedBox(height: 16),

      _buildGroupTitle("DESIGN DETAILS"),
      _buildTwoColumnRow([
        _buildItemTile("Color", "mainColor", Icons.palette_outlined),
        _buildItemTile("SubColor", "subColor", Icons.palette_outlined),
        _buildItemTile("Size", "size", Icons.format_size),
      ]),
      _buildTwoColumnRow([
        _buildItemTile("Style", "style", Icons.style_outlined),
        _buildItemTile("Fit", "fit", Icons.accessibility_new_outlined),
      ]),
      _buildTwoColumnRow([
        _buildItemTile("Material", "material", Icons.texture_outlined),
        _buildItemTile("Pattern", "pattern", Icons.grid_view_rounded),
      ]),
      _buildTwoColumnRow([
        _buildItemTile("Neckline", "neckline", Icons.line_weight),
        _buildItemTile("Brand", "brand", Icons.branding_watermark_outlined),
      ]),
      _buildTwoColumnRow([
        _buildItemTile("Length", "length", Icons.filter_tilt_shift_rounded),
        _buildItemTile("Sleeve", "sleeveLength", Icons.type_specimen_outlined),
      ]),

      const SizedBox(height: 16),

      _buildGroupTitle("STATUS & SETTINGS"),
      Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _isEditing ? AppColors.textPrimary : AppColors.stroke),
        ),
        child: Column(
          children: [
            _buildSwitchTile("Public Item", "isPublic", Icons.visibility_outlined),
            const Divider(color: AppColors.divider, height: 1, indent: 50),
            _buildStatusDropdownTile(),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _buildDescriptionField(),
    ];
  }

  Widget _buildDescriptionField() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isEditing ? AppColors.background : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isEditing ? AppColors.textPrimary : AppColors.stroke,
          width: _isEditing ? 1.0 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes_rounded, size: 18, color: _isEditing ? AppColors.textPrimary : AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                  "Description",
                  style: TextStyle(
                      color: _isEditing ? AppColors.textPrimary : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700
                  )
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controllers['description'],
            enabled: _isEditing,
            maxLines: null,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.5),
            decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: "No description provided",
                hintStyle: TextStyle(color: AppColors.textSecondary)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTwoColumnRow(List<Widget> children) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children.map((w) => Expanded(child: w)).toList(),
    );
  }

  Widget _buildGroupTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 16),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }

  Widget _buildItemTile(String label, String key, IconData icon) {
    if (!_controllers.containsKey(key)) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
      child: FashionAutocompleteField(
        label: label,
        icon: icon,
        enabled: _isEditing,
        controller: _controllers[key]!,
        options: FashionConstants.categories[key] ?? [],
      ),
    );
  }

  Widget _buildSwitchTile(String label, String key, IconData icon) {
    bool val = _controllers[key]!.text.toLowerCase() == "true";
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(icon, size: 20, color: AppColors.textPrimary),
      title: const Text("Public Item", style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
      trailing: _isEditing
          ? SizedBox(
        height: 30,
        child: Switch(
          value: val,
          activeColor: AppColors.background,
          activeTrackColor: AppColors.primary,
          inactiveThumbColor: AppColors.textSecondary,
          inactiveTrackColor: AppColors.stroke,
          onChanged: (bool newValue) {
            setState(() => _controllers[key]!.text = newValue.toString());
          },
        ),
      )
          : Text(
          val ? "YES" : "NO",
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w800)
      ),
    );
  }

  Widget _buildStatusDropdownTile() {
    final statusMap = { "0": "Draft", "1": "Active", "2": "Inactive", "3": "Archived", "4": "Deleted" };
    String currentStatus = _controllers['status']!.text;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: const Icon(Icons.check_box_outlined, size: 20, color: AppColors.textPrimary),
      title: const Text("Status", style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
      trailing: _isEditing
          ? DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: statusMap.containsKey(currentStatus) ? currentStatus : "1",
          dropdownColor: AppColors.background,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.textPrimary),
          items: statusMap.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
          onChanged: (val) => setState(() => _controllers['status']!.text = val!),
        ),
      )
          : Text(
          statusMap[currentStatus] ?? "Active",
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w800)
      ),
    );
  }

  Widget _buildTimelineSection() {
    final String owner = widget.itemData['ownerUsername']?.toString() ?? "Unknown";
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface, // Nền xám nhạt
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildTimeRow("Owned by", owner, isOwner: true),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: AppColors.divider, height: 1),
          ),
          _buildTimeRow("Registered on", _formatDate(widget.itemData['createdAt'])),
          const SizedBox(height: 12),
          _buildTimeRow("Last update", _formatDate(widget.itemData['updateAt'])),
        ],
      ),
    );
  }

  Widget _buildTimeRow(String label, String value,{bool isOwner = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(color: isOwner ? AppColors.primary : AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
      ],
    );
  }
}