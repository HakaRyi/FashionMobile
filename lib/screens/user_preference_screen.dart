import 'package:flutter/material.dart';
import '../services/user_profile_service.dart';
import 'main_screen.dart';

class UserPreferenceScreen extends StatefulWidget {
  final Map<String, dynamic> physicalData;
  const UserPreferenceScreen({super.key, required this.physicalData});

  @override
  State<UserPreferenceScreen> createState() => _UserPreferenceScreenState();
}

class _UserPreferenceScreenState extends State<UserPreferenceScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;

  late AnimationController _animationController;
  final TextEditingController _valCtrl = TextEditingController();

  // Khai báo các loại sở thích
  final List<String> _preferenceTypes = ["Style", "Color", "Material", "Brand"];
  String _selectedType = "Style";

  // Cập nhật đúng: 7 màu cơ bản, 5 brand lớn
  final Map<String, List<String>> _defaultValues = {
    "Style": ["Minimalist", "Streetwear", "Vintage", "Casual", "Formal", "Sporty"],
    "Color": ["Black", "White", "Red", "Blue", "Green", "Yellow", "Gray"], // 7 màu
    "Material": ["Cotton", "Silk", "Denim", "Leather", "Linen"], // 5 chất liệu
    "Brand": ["Nike", "Adidas", "Zara", "H&M", "Uniqlo"] // 5 thương hiệu
  };

  // Mảng lưu trữ tất cả các sở thích user đã chọn
  final List<Map<String, String>> _userPreferences = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _valCtrl.dispose();
    super.dispose();
  }

  void _addPreference(String type, String value) {
    String val = value.trim();
    if (val.isEmpty) return;

    // Fix lỗi Null Safety ở đây bằng cách thêm ?? ''
    bool exists = _userPreferences.any((p) => p['type'] == type && (p['value'] ?? '').toLowerCase() == val.toLowerCase());
    if (!exists) {
      setState(() {
        _userPreferences.add({"type": type, "value": val});
        _valCtrl.clear();
      });
    }
  }

  Future<void> _submitData(bool isSkipped) async {
    setState(() => _isLoading = true);

    Map<String, dynamic> finalPayload = Map.from(widget.physicalData);

    if (isSkipped) {
      finalPayload["favoriteStyles"] = [];
      finalPayload["favoriteColors"] = [];
    } else {
      // Tách dữ liệu ra để map ĐÚNG với JSON API yêu cầu hiện tại
      List<String> favStyles = _userPreferences.where((p) => p['type'] == 'Style').map((p) => p['value']!).toList();
      List<String> favColors = _userPreferences.where((p) => p['type'] == 'Color').map((p) => p['value']!).toList();

      finalPayload["favoriteStyles"] = favStyles;
      finalPayload["favoriteColors"] = favColors;

      // Đẩy thêm Brand và Material lót sẵn, Backend C# có hứng thì hứng, không hứng thì nó tự Ignore
      finalPayload["favoriteMaterials"] = _userPreferences.where((p) => p['type'] == 'Material').map((p) => p['value']!).toList();
      finalPayload["favoriteBrands"] = _userPreferences.where((p) => p['type'] == 'Brand').map((p) => p['value']!).toList();
    }

    final success = await UserProfileService().completeOnboarding(finalPayload);

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
            (route) => false,
      );
    }
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    double start = index * 0.15;
    double end = start + 0.5;
    if (end > 1.0) end = 1.0;

    Animation<Offset> slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    ));

    Animation<double> fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(start, end, curve: Curves.easeOut),
    ));

    return SlideTransition(position: slideAnimation, child: FadeTransition(opacity: fadeAnimation, child: child));
  }

  @override
  Widget build(BuildContext context) {
    List<String> currentSuggestions = _defaultValues[_selectedType] ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () => _submitData(true),
            child: const Text("SKIP", style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAnimatedItem(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("STEP 2 OF 2", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black38)),
                        SizedBox(height: 8),
                        Text("Your Preferences", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black)),
                        SizedBox(height: 10),
                        Text("Build your profile by adding favorite styles, colors, materials, and brands.", style: TextStyle(color: Colors.black54)),
                        SizedBox(height: 30),
                      ],
                    ),
                    0,
                  ),

                  // KHU VỰC NHẬP LIỆU
                  _buildAnimatedItem(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Dropdown chọn Loại (Type)
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                value: _selectedType,
                                isExpanded: true,
                                dropdownColor: Colors.white,
                                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 13),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 2.0)),
                                ),
                                items: _preferenceTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedType = val!;
                                    _valCtrl.clear();
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            // TextField nhập tay
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: _valCtrl,
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                                decoration: InputDecoration(
                                  // Chỉnh lại Hint Text cho rõ ràng ý đồ Custom
                                  hintText: "Or type custom...",
                                  hintStyle: const TextStyle(color: Colors.black38, fontSize: 12),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 2.0)),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.add_circle, color: Colors.black),
                                    onPressed: () => _addPreference(_selectedType, _valCtrl.text),
                                  ),
                                ),
                                onSubmitted: (val) => _addPreference(_selectedType, val),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // THANH GỢI Ý (SUGGESTIONS)
                        const Text("Quick Add (Tap to select):", style: TextStyle(color: Colors.black38, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: currentSuggestions.map((suggestion) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ActionChip(
                                  label: Text(suggestion, style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600)),
                                  backgroundColor: Colors.grey.shade100,
                                  side: const BorderSide(color: Colors.black12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  // Khi user bấm vào thẻ, tự động gọi hàm Add luôn (không cần bấm dấu +)
                                  onPressed: () => _addPreference(_selectedType, suggestion),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                    1,
                  ),

                  const SizedBox(height: 40),

                  // KHU VỰC HIỂN THỊ CÁC SỞ THÍCH ĐÃ CHỌN
                  _buildAnimatedItem(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("ADDED PREFERENCES", style: TextStyle(color: Colors.black38, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                        const SizedBox(height: 12),
                        if (_userPreferences.isEmpty)
                          const Text("You haven't added any preferences yet.", style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic))
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 10,
                            children: _userPreferences.map((pref) {
                              Color chipColor = Colors.black;
                              if (pref['type'] == 'Color') chipColor = const Color(0xFF3B3B3B);
                              if (pref['type'] == 'Material') chipColor = const Color(0xFF5C5C5C);
                              if (pref['type'] == 'Brand') chipColor = const Color(0xFF7A7A7A);

                              return Chip(
                                label: RichText(
                                  text: TextSpan(
                                      children: [
                                        TextSpan(text: "${pref['type']}: ", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w600)),
                                        TextSpan(text: pref['value'], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                      ]
                                  ),
                                ),
                                backgroundColor: chipColor,
                                deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white70),
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                onDeleted: () {
                                  setState(() {
                                    _userPreferences.remove(pref);
                                  });
                                },
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                    2,
                  ),
                ],
              ),
            ),
          ),

          // NÚT FINISH
          _buildAnimatedItem(
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    onPressed: _isLoading ? null : () => _submitData(false),
                    child: _isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("FINISH", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.5)),
                  ),
                ),
              ),
            ),
            3,
          ),
        ],
      ),
    );
  }
}