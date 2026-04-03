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

    // Phân loại Keys
    final manualKeys = ['size', 'brand', 'texture', 'placement'];
    final aiKeys = [
      'itemType', 'category', 'subCategory', 'gender', 'mainColor',
      'subColor', 'material', 'style', 'pattern', 'fit', 'neckline',
      'sleeveLength', 'length'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. CÀI ĐẶT CÔNG KHAI
        _buildIsPublicToggle(),
        const SizedBox(height: 24),

        // 2. THÔNG TIN CƠ BẢN
        _buildSectionHeader("THÔNG TIN CƠ BẢN"),
        const SizedBox(height: 12),
        _buildFieldWrapper('itemName'), // Tên món đồ chiếm 1 hàng

        // Chia đôi cho các trường manual còn lại
        _buildRow([
          _buildFieldWrapper('size'),
          _buildFieldWrapper('brand'),
        ]),
        _buildRow([
          _buildFieldWrapper('texture'),
          _buildFieldWrapper('placement'),
        ]),

        const Divider(color: Colors.white10, height: 40),

        // 3. KẾT QUẢ PHÂN TÍCH AI (Chia 2 cột)
        _buildSectionHeader("AI PHÂN TÍCH CHUYÊN SÂU"),
        const SizedBox(height: 12),
        _buildRow([
          _buildFieldWrapper('itemType'),
          _buildFieldWrapper('category'),
        ]),
        _buildRow([
          _buildFieldWrapper('subCategory'),
          _buildFieldWrapper('gender'),
        ]),
        _buildRow([
          _buildFieldWrapper('mainColor'),
          _buildFieldWrapper('subColor'),
        ]),
        _buildRow([
          _buildFieldWrapper('material'),
          _buildFieldWrapper('style'),
        ]),
        _buildRow([
          _buildFieldWrapper('pattern'),
          _buildFieldWrapper('fit'),
        ]),
        _buildRow([
          _buildFieldWrapper('neckline'),
          _buildFieldWrapper('length'),
        ]),
        _buildFieldWrapper('sleeveLength'),

        const Divider(color: Colors.white10, height: 40),

        // 4. MÔ TẢ SẢN PHẨM
        _buildSectionHeader("MÔ TẢ CHI TIẾT"),
        const SizedBox(height: 12),
        _buildDescriptionField(),

        const SizedBox(height: 20),
      ],
    );
  }

  // Hàm bổ trợ để tạo hàng 2 cột
  Widget _buildRow(List<Widget> children) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children.map((w) => Expanded(child: w)).toList(),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.white.withOpacity(0.4),
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildFieldWrapper(String key) {
    if (!_controllers.containsKey(key)) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(4.0), // Padding nhỏ để các ô sát nhau hơn khi chia 2
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(key),
          const SizedBox(height: 6),
          FashionAutocompleteField(
            label: "Nhập ${key}",
            options: FashionConstants.categories[key] ?? [],
            controller: _controllers[key]!,
            enabled: true,
            icon: _getIconForField(key),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: TextFormField(
        controller: _controllers['description'],
        maxLines: null,
        minLines: 4,
        keyboardType: TextInputType.multiline,
        style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
        decoration: InputDecoration(
          hintText: "Thêm mô tả chi tiết...",
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
          prefixIcon: const Icon(Icons.notes, color: Colors.pinkAccent, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
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
              widget.onAttributeSelected('isPublic', val.toString());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String key) {
    bool isAI = _isAIField(key);
    return Row(
      children: [
        Icon(
            isAI ? Icons.auto_awesome : Icons.edit_note,
            size: 13,
            color: isAI ? Colors.pinkAccent : Colors.white38
        ),
        const SizedBox(width: 6),
        Text(
          key.toUpperCase(),
          style: TextStyle(
              color: isAI ? Colors.pinkAccent : Colors.white38,
              fontSize: 9,
              fontWeight: FontWeight.bold
          ),
        ),
      ],
    );
  }

  bool _isAIField(String key) {
    final aiFields = [
      'itemType', 'category', 'subCategory', 'gender', 'mainColor',
      'subColor', 'material', 'style', 'pattern', 'fit', 'neckline',
      'sleeveLength', 'length'
    ];
    return aiFields.contains(key);
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
      case 'size': return Icons.straighten;
      default: return Icons.edit_note_outlined;
    }
  }
}