import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/fashion_constants.dart';
import 'fashion_autocomplete_field.dart';

class AIResultPanel extends StatefulWidget {
  final Map<dynamic, dynamic>? aiData;
  final Map<String, String> selectedAttributes;
  final Function(String key, String value) onAttributeSelected;

  const AIResultPanel({
    super.key,
    required this.aiData,
    required this.selectedAttributes,
    required this.onAttributeSelected,
  });

  @override
  State<AIResultPanel> createState() => _AIResultPanelState();
}

class _AIResultPanelState extends State<AIResultPanel> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    FashionConstants.categories.keys.forEach((key) {
      _controllers[key] = TextEditingController(text: widget.selectedAttributes[key] ?? "");
      _controllers[key]!.addListener(() {
        widget.onAttributeSelected(key, _controllers[key]!.text);
      });
    });
  }

  @override
  void didUpdateWidget(AIResultPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // QUAN TRỌNG: Khi AI trả về data mới, cập nhật text cho Controller ngay lập tức
    widget.selectedAttributes.forEach((key, value) {
      if (_controllers.containsKey(key) && _controllers[key]!.text != value) {
        _controllers[key]!.text = value;
      }
    });
  }

  @override
  void dispose() {
    _controllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.aiData == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(color: Colors.pinkAccent),
        ),
      );
    }

    // Lọc danh sách: Bỏ 'status' và 'isPublic' ra khỏi vòng lặp Autocomplete thông thường
    final displayKeys = FashionConstants.categories.keys
        .where((k) => k != 'status' && k != 'isPublic')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. HIỂN THỊ IS PUBLIC TRƯỚC (Widget đẹp)
        _buildIsPublicToggle(),
        const SizedBox(height: 10),
        const Divider(color: Colors.white10),
        const SizedBox(height: 20),

        // 2. HIỂN THỊ CÁC TRƯỜNG NHẬP LIỆU KHÁC
        ...displayKeys.map((key) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(key),
                const SizedBox(height: 12),
                FashionAutocompleteField(
                  label: "Edit ${key}",
                  options: FashionConstants.categories[key] ?? [],
                  controller: _controllers[key]!,
                  enabled: true,
                  icon: _getIconForField(key),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
  Widget _buildIsPublicToggle() {
    bool isTrue = widget.selectedAttributes['isPublic'] == "true";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isTrue ? Colors.pinkAccent.withOpacity(0.3) : Colors.white10),
      ),
      child: Row(
        children: [
          Icon(
            isTrue ? Icons.public : Icons.public_off,
            color: isTrue ? Colors.pinkAccent : Colors.white38,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Public Visibility",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(
                  isTrue ? "Anyone can see this item" : "Only you can see this item",
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: isTrue,
            activeColor: Colors.pinkAccent,
            onChanged: (val) {
              // Cập nhật thông qua callback để đồng bộ State cha
              widget.onAttributeSelected('isPublic', val.toString());
            },
          ),
        ],
      ),
    );
  }
  Widget _buildHeader(String key) {
    return Row(
      children: [
        const Icon(Icons.auto_awesome, size: 14, color: Colors.pinkAccent),
        const SizedBox(width: 8),
        Text(
          key.toUpperCase(),
          style: const TextStyle(color: Colors.pinkAccent, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
  IconData _getIconForField(String key) {
    switch (key) {
      case 'itemName': return Icons.label_outline;
      case 'mainColor': return Icons.palette_outlined;
      case 'subColor': return Icons.palette_outlined;
      case 'style': return Icons.style_outlined;
      case 'material': return Icons.texture_outlined;
      case 'pattern': return Icons.grid_view_rounded;
      case 'brand': return Icons.verified_outlined;
      case 'texture': return Icons.waves_outlined;
      case 'placement': return Icons.layers_outlined;
      case 'category': return Icons.category_outlined;
      case 'subCategory': return Icons.account_tree_outlined;
      case 'gender': return Icons.wc_outlined;
      case 'fit': return Icons.screenshot_outlined;
      case 'neckline': return Icons.stairs_outlined;
      default: return Icons.edit_note_outlined;
    }
  }
}