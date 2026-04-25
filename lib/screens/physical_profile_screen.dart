import 'package:fashion_mobile/screens/user_preference_screen.dart';
import 'package:flutter/material.dart';

import '../utils/route_transitions.dart';

class PhysicalProfileScreen extends StatefulWidget {
  const PhysicalProfileScreen({super.key});

  @override
  State<PhysicalProfileScreen> createState() => _PhysicalProfileScreenState();
}

// BƯỚC 1: Thêm SingleTickerProviderStateMixin
class _PhysicalProfileScreenState extends State<PhysicalProfileScreen> with SingleTickerProviderStateMixin {
  // Các Controllers
  final TextEditingController _heightCtrl = TextEditingController();
  final TextEditingController _weightCtrl = TextEditingController();
  final TextEditingController _waistCtrl = TextEditingController();
  final TextEditingController _hipCtrl = TextEditingController();
  final TextEditingController _bustCtrl = TextEditingController();

  int _selectedGender = 0; // Giả sử 0: Nữ, 1: Nam, 2: Unisex
  String _selectedBodyShape = "Unknown";
  String _selectedSkinTone = "Unknown";

  final List<String> _bodyShapes = ["Hourglass", "Rectangle", "Triangle", "Inverted Triangle", "Apple", "Unknown"];
  final List<String> _skinTones = ["Light", "Medium", "Dark", "Unknown"];

  // BƯỚC 2: Khai báo AnimationController
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // BƯỚC 3: Khởi tạo Animation chạy trong 800ms
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    // BƯỚC 4: Nhớ dọn dẹp controller
    _animationController.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _waistCtrl.dispose();
    _hipCtrl.dispose();
    _bustCtrl.dispose();
    super.dispose();
  }

  void _onNext() {
    Map<String, dynamic> physicalData = {
      "gender": _selectedGender,
      "height": double.tryParse(_heightCtrl.text) ?? 0,
      "weight": double.tryParse(_weightCtrl.text) ?? 0,
      "waist": double.tryParse(_waistCtrl.text) ?? 0,
      "hip": double.tryParse(_hipCtrl.text) ?? 0,
      "bust": double.tryParse(_bustCtrl.text) ?? 0,
      "bodyShape": _selectedBodyShape,
      "skinTone": _selectedSkinTone,
    };

    Navigator.push(context, SlideRoute(page: UserPreferenceScreen(physicalData: physicalData)));
  }

  void _onSkip() {
    Map<String, dynamic> emptyData = {
      "gender": 0,
      "height": 0, "weight": 0, "waist": 0, "hip": 0, "bust": 0,
      "bodyShape": "Unknown", "skinTone": "Unknown"
    };
    Navigator.push(context, SlideRoute(page: UserPreferenceScreen(physicalData: emptyData)));
  }
  Widget _buildAnimatedItem(Widget child, int index) {
    double start = index * 0.15;
    double end = start + 0.5;
    if (end > 1.0) end = 1.0;

    Animation<Offset> slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
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

    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: child,
      ),
    );
  }
  String _getGenderString(int genderValue) {
    switch (genderValue) {
      case 1: return "Male";
      case 2: return "Female";
      case 3: return "Other";
      default: return "Unknown";
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _onSkip,
            child: const Text("SKIP", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
                  // CỤM 0: Tiêu đề
                  _buildAnimatedItem(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("STEP 1 OF 2", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black38)),
                        SizedBox(height: 8),
                        Text("Your Body Profile", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black)),
                        SizedBox(height: 10),
                        Text("Help us recommend clothes that fit you perfectly.", style: TextStyle(color: Colors.black54)),
                        SizedBox(height: 30),
                      ],
                    ),
                    0, // Index 0
                  ),

                  // CỤM 1: Basic Info
                  _buildAnimatedItem(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle("BASIC INFO"),
                        const SizedBox(height: 16),
                        _buildDropdown(
                          "Gender",
                          ["Unknown", "Male", "Female", "Other"],
                          _getGenderString(_selectedGender),
                              (val) {
                            setState(() {
                              if (val == "Male") _selectedGender = 1;
                              else if (val == "Female") _selectedGender = 2;
                              else if (val == "Other") _selectedGender = 3;
                              else _selectedGender = 0; // Unknown
                            });
                          },
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                    1,
                  ),

                  // CỤM 2: Measurements
                  _buildAnimatedItem(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle("MEASUREMENTS"),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildNumberField("Height (cm)", _heightCtrl)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildNumberField("Weight (kg)", _weightCtrl)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildNumberField("Bust (cm)", _bustCtrl)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildNumberField("Waist (cm)", _waistCtrl)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildNumberField("Hip (cm)", _hipCtrl)),
                          ],
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                    2, // Index 2
                  ),

                  // CỤM 3: Appearance
                  _buildAnimatedItem(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle("APPEARANCE"),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdown("Body Shape", _bodyShapes, _selectedBodyShape, (val) {
                                setState(() => _selectedBodyShape = val!);
                              }),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildDropdown("Skin Tone", _skinTones, _selectedSkinTone, (val) {
                                setState(() => _selectedSkinTone = val!);
                              }),
                            ),
                          ],
                        ),
                      ],
                    ),
                    3, // Index 3
                  ),
                ],
              ),
            ),
          ),

          // CỤM 4: Nút NEXT (Luôn nổi ở dưới cùng)
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
                    onPressed: _onNext,
                    child: const Text("NEXT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.5)),
                  ),
                ),
              ),
            ),
            4, // Index 4
          ),
        ],
      ),
    );
  }

  // --- HÀM HỖ TRỢ XÂY DỰNG UI CHO GỌN ---

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black38, letterSpacing: 1.2),
    );
  }

  Widget _buildNumberField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black, width: 2.0),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String currentValue, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: currentValue,
      isExpanded: true,
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 2.0)),
      ),
      items: items.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value,
            style: const TextStyle(color: Colors.black),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}