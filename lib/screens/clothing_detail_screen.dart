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
      'size': TextEditingController(text: widget.itemData['size']),
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
    if (dateStr == null || dateStr == "N/A") return "N/A";
    try {
      String timeStr = dateStr;
      if (!timeStr.endsWith('Z') && !timeStr.contains('+')) {
        timeStr += 'Z';
      }
      final DateTime date = DateTime.parse(timeStr).toLocal();

      return DateFormat('MMM dd, yyyy • HH:mm').format(date);
    } catch (e) {
      debugPrint("Error parsing date: $e");
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
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
        ),
        centerTitle: true,
        title: Text(
          _isEditing ? "EDIT DETAILS" : "CLOTHING INFO",
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 2, color: Colors.black),
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
                const Text("Attributes", style: TextStyle(color: Colors.pinkAccent, fontSize: 18, fontWeight: FontWeight.bold)),
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
        color: AppColors.menu,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // NHÓM 1: THÔNG TIN CƠ BẢN
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

        const SizedBox(height: 20),

        // NHÓM 2: ĐẶC ĐIỂM THIẾT KẾ
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

        const SizedBox(height: 20),

        // NHÓM 3: TRẠNG THÁI & MÔ TẢ
        _buildGroupTitle("STATUS & SETTINGS"),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              _buildSwitchTile("Public Item", "isPublic", Icons.visibility_outlined),
              const Divider(color: Colors.white, height: 1, indent: 50),
              _buildStatusDropdownTile(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildDescriptionField(),
      ],
    );
  }
  Widget _buildDescriptionField() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // NỀN CỦA CẢ KHỐI DESCRIPTION
        color: _isEditing ? Colors.pinkAccent.withOpacity(0.02) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
            color: _isEditing ? Colors.pinkAccent.withOpacity(0.3) : Colors.black.withOpacity(0.1)
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes_rounded, size: 18, color: _isEditing ? Colors.pinkAccent : Colors.black26),
              const SizedBox(width: 8),
              Text(
                  "Description",
                  style: TextStyle(color: Colors.black.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.bold)
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controllers['description'],
            enabled: _isEditing,
            maxLines: null,
            style: const TextStyle(color: Colors.black, fontSize: 14, height: 1.5),
            decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: "No description provided",
                hintStyle: TextStyle(color: Colors.black26)
            ),
          ),
        ],
      ),
    );
  }
  // Hàm bổ trợ chia 2 cột
  Widget _buildTwoColumnRow(List<Widget> children) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children.map((w) => Expanded(child: w)).toList(),
    );
  }

  // Tiêu đề nhóm cho chuyên nghiệp
  Widget _buildGroupTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
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

  // Sửa lại _buildItemTile để tối ưu không gian khi chia cột
  Widget _buildItemTile(String label, String key, IconData icon, {bool isLast = false}) {
    if (!_controllers.containsKey(key)) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(4.0), // Giảm padding để khít hơn khi chia 2 cột
      child: FashionAutocompleteField(
        label: label,
        icon: icon,
        enabled: _isEditing,
        controller: _controllers[key]!,
        options: FashionConstants.categories[key] ?? [],
      ),
    );
  }

  // Giữ nguyên logic _buildSwitchTile của bạn nhưng tui căn chỉnh lại UI xíu cho đẹp
  Widget _buildSwitchTile(String label, String key, IconData icon) {
    bool val = _controllers[key]!.text.toLowerCase() == "true";
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(icon, size: 20, color: Colors.pinkAccent.withOpacity(0.7)),
      title: Text(label, style: TextStyle(color: Colors.black.withOpacity(0.5), fontSize: 13)),
      trailing: _isEditing
          ? SizedBox(
        height: 30,
        child: Switch(
          value: val,
          activeColor: Colors.pinkAccent,
          onChanged: (bool newValue) {
            setState(() => _controllers[key]!.text = newValue.toString());
          },
        ),
      )
          : Text(val ? "YES" : "NO", style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
    );
  }

  // Giữ nguyên logic _buildStatusDropdownTile của bạn
  Widget _buildStatusDropdownTile() {
    final statusMap = { "0": "Draft", "1": "Active", "2": "Inactive", "3": "Archived", "4": "Deleted" };
    String currentStatus = _controllers['status']!.text;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(Icons.check_box_outlined, size: 20, color: Colors.pinkAccent.withOpacity(0.7)),
      title:  Text("Status", style: TextStyle(color: Colors.black.withOpacity(0.5), fontSize: 13)),
      trailing: _isEditing
          ? DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: statusMap.containsKey(currentStatus) ? currentStatus : "1",
          dropdownColor: AppColors.surface,
          style: const TextStyle(color: Colors.black, fontSize: 14),
          items: statusMap.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
          onChanged: (val) => setState(() => _controllers['status']!.text = val!),
        ),
      )
          : Text(statusMap[currentStatus] ?? "Active", style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
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
        Text(label, style: TextStyle(color: Colors.black.withOpacity(0.3), fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}