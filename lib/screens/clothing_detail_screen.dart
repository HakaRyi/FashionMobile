import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../services/item_service.dart';
import '../constants/fashion_constants.dart';
import '../widgets/fashion_autocomplete_field.dart';

class ClothingDetailScreen extends StatefulWidget {
  final Map<String, dynamic> itemData;
  final bool showEditButton;

  const ClothingDetailScreen({super.key, required this.itemData,this.showEditButton = true,});

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
    _controllers = {
      'itemName': TextEditingController(text: widget.itemData['itemName']),
      'itemType': TextEditingController(text: widget.itemData['itemType']),
      'category': TextEditingController(text: widget.itemData['category']),
      'subCategory': TextEditingController(text: widget.itemData['subCategory']),
      'gender': TextEditingController(text: widget.itemData['gender']),
      'mainColor': TextEditingController(text: widget.itemData['mainColor']),
      'subColor': TextEditingController(text: widget.itemData['subColor']),
      'material': TextEditingController(text: widget.itemData['material']),
      'pattern': TextEditingController(text: widget.itemData['pattern']),
      'style': TextEditingController(text: widget.itemData['style']),
      'fit': TextEditingController(text: widget.itemData['fit']),
      'neckline': TextEditingController(text: widget.itemData['neckline']),
      'sleeveLength': TextEditingController(text: widget.itemData['sleeveLength']),
      'length': TextEditingController(text: widget.itemData['length']),
      'placement': TextEditingController(text: widget.itemData['placement']),
      'brand': TextEditingController(text: widget.itemData['brand']),
      'description': TextEditingController(text: widget.itemData['description']),
      'texture': TextEditingController(text: widget.itemData['texture']),

      'isPublic': TextEditingController(text: widget.itemData['isPublic']?.toString() ?? "false"),
      'status': TextEditingController(text: widget.itemData['status']?.toString() ?? "1"),
    };
  }

  @override
  void dispose() {
    _controllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    final Map<String, dynamic> updateData = {};
    _controllers.forEach((key, controller) {
      updateData[key] = controller.text;
    });

    updateData["status"] = int.tryParse(_controllers['status']!.text) ?? 1;
    updateData["isPublic"] = _controllers['isPublic']!.text.toLowerCase() == "true";
    print("DEBUG: Dữ liệu gửi đi -> $updateData");
    final success = await ItemService().updateItem(widget.itemData['itemId'], updateData);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Updated successfully!"),backgroundColor: Colors.green),
        );
        setState(() {
          widget.itemData['isPublic'] = updateData["isPublic"];
          widget.itemData['status'] = updateData["status"];
          _isEditing = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Update failed!"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return "N/A";
    try {
      final DateTime date = DateTime.parse(dateStr);
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _isEditing ? "EDIT DETAILS" : "CLOTHING INFO",
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 2),
        ),
        actions: [
          if (widget.showEditButton)
            _isSaving
                ? const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.pinkAccent)),
              ),
            )
                : TextButton(
              onPressed: () {
                if (_isEditing) {
                  _handleSave();
                } else {
                  setState(() => _isEditing = true);
                }
              },
              child: Text(
                _isEditing ? "SAVE" : "EDIT",
                style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold),
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

            // Info Header
            Row(
              children: [
                Container(width: 4, height: 20, decoration: BoxDecoration(color: Colors.pinkAccent, borderRadius: BorderRadius.circular(10))),
                const SizedBox(width: 10),
                const Text("Attributes", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),

            // Attributes Grid/List
            _buildInfoContainer(),

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
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Image.network(
              widget.itemData['primaryImageUrl'],
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.contain,
            ),
          ),
          if (!_isEditing)
            Positioned(
              bottom: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
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

  Widget _buildInfoContainer() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          _buildItemTile("Item Name", "itemName", Icons.shopping_bag_outlined),
          _buildItemTile("Item Type", "itemType", Icons.merge_type_outlined),
          _buildItemTile("Gender", "gender", Icons.wc),
          _buildItemTile("Category", "category", Icons.category_outlined),
          _buildItemTile("Sub Category", "subCategory", Icons.account_tree_outlined),
          _buildItemTile("Color", "mainColor", Icons.palette_outlined),
          _buildItemTile("Style", "style", Icons.style_outlined),
          _buildItemTile("Fit", "fit", Icons.accessibility_new_outlined),
          _buildItemTile("Neckline", "neckline", Icons.line_weight),
          _buildItemTile("Material", "material", Icons.texture_outlined),
          _buildItemTile("Pattern", "pattern", Icons.grid_view_rounded),
          _buildItemTile("Brand", "brand", Icons.branding_watermark_outlined),
          _buildItemTile("Length", "length", Icons.filter_tilt_shift_rounded),
          _buildItemTile("Sleeve Length", "sleeveLength", Icons.type_specimen_outlined),

          _buildSwitchTile("Public Item", "isPublic", Icons.visibility_outlined),
          _buildStatusDropdownTile(),
          _buildItemTile("Description", "description", Icons.notes_rounded, isLast: true),

        ],
      ),
    );
  }
  Widget _buildSwitchTile(String label, String key, IconData icon) {
    bool val = _controllers[key]!.text.toLowerCase() == "true";
    return ListTile(
      leading: Icon(icon, size: 18, color: Colors.pinkAccent.withOpacity(0.5)),
      title: Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
      trailing: _isEditing
          ? Switch(
        value: val,
        activeColor: Colors.pinkAccent,
        onChanged: (bool newValue) {
          setState(() => _controllers[key]!.text = newValue.toString());
        },
      )
          : Text(val ? "YES" : "NO", style: const TextStyle(color: Colors.white, fontSize: 14)),
    );
  }

  // Widget dành riêng cho Status Enum
  Widget _buildStatusDropdownTile() {
    final statusMap = { "0": "Draft", "1": "Active", "2": "Inactive", "3": "Archived", "4": "Deleted" };
    String currentStatus = _controllers['status']!.text;

    return ListTile(
      leading: Icon(Icons.check_box_outlined, size: 18, color: Colors.pinkAccent.withOpacity(0.5)),
      title: const Text("Status", style: TextStyle(color: Colors.white, fontSize: 12)),
      trailing: _isEditing
          ? DropdownButton<String>(
        value: statusMap.containsKey(currentStatus) ? currentStatus : "1",
        dropdownColor: AppColors.surface,
        style: const TextStyle(color: Colors.white),
        items: statusMap.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
        onChanged: (val) => setState(() => _controllers['status']!.text = val!),
      )
          : Text(statusMap[currentStatus] ?? "Active", style: const TextStyle(color: Colors.white, fontSize: 14)),
    );
  }
// Trong ClothingDetailScreen.dart
  Widget _buildItemTile(String label, String key, IconData icon, {bool isLast = false}) {
    if (!_controllers.containsKey(key)) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: FashionAutocompleteField(
        label: label,
        icon: icon,
        enabled: _isEditing,
        controller: _controllers[key]!,
        options: FashionConstants.categories[key] ?? [], // Lấy từ hằng số dùng chung
      ),
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
          _buildTimeRow("Registered on", _formatDate(widget.itemData['createdAt'])),
          const SizedBox(height: 10),
          _buildTimeRow("Last update", _formatDate(widget.itemData['updateAt'])),
        ],
      ),
    );
  }

  Widget _buildTimeRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}