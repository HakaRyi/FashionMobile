import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/user_profile_service.dart';

class EditPersonalInformationScreen extends StatefulWidget {
  const EditPersonalInformationScreen({super.key});

  @override
  State<EditPersonalInformationScreen> createState() => _EditPersonalInformationScreenState();
}

class _EditPersonalInformationScreenState extends State<EditPersonalInformationScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  // Controllers
  final TextEditingController _heightCtrl = TextEditingController();
  final TextEditingController _weightCtrl = TextEditingController();
  final TextEditingController _waistCtrl = TextEditingController();
  final TextEditingController _hipCtrl = TextEditingController();
  final TextEditingController _bustCtrl = TextEditingController();
  final TextEditingController _dobCtrl = TextEditingController();
  final TextEditingController _valCtrl = TextEditingController(); // Controller cho ô nhập custom

  DateTime? _selectedDate;
  int _selectedGender = 0; // 0: Unknown, 1: Male, 2: Female, 3: Other
  String _selectedBodyShape = "Unknown";
  String _selectedSkinTone = "Unknown";

  final List<String> _bodyShapes = ["Hourglass", "Rectangle", "Triangle", "Inverted Triangle", "Apple", "Unknown"];
  final List<String> _skinTones = ["Light", "Medium", "Dark", "Unknown"];

  // ================= PHẦN QUẢN LÝ SỞ THÍCH =================
  final List<String> _preferenceTypes = ["Style", "Color", "Material", "Brand"];
  String _selectedType = "Style";

  final Map<String, List<String>> _defaultValues = {
    "Style": ["Minimalist", "Streetwear", "Vintage", "Casual", "Formal", "Sporty"],
    "Color": ["Black", "White", "Red", "Blue", "Green", "Yellow", "Gray"],
    "Material": ["Cotton", "Silk", "Denim", "Leather", "Linen"],
    "Brand": ["Nike", "Adidas", "Zara", "H&M", "Uniqlo"]
  };

  final List<Map<String, String>> _userPreferences = [];
  // ========================================================

  @override
  void initState() {
    super.initState();
    _fetchMyData();
  }

  @override
  void dispose() {
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _waistCtrl.dispose();
    _hipCtrl.dispose();
    _bustCtrl.dispose();
    _dobCtrl.dispose();
    _valCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchMyData() async {
    final profile = await UserProfileService().getMe();
    if (profile != null && mounted) {
      setState(() {
        _selectedGender = profile['gender'] ?? 0;

        if (profile['dateOfBirth'] != null) {
          _selectedDate = DateTime.tryParse(profile['dateOfBirth'].toString());
          if (_selectedDate != null) {
            _dobCtrl.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
          }
        }

        _heightCtrl.text = (profile['height'] ?? '').toString();
        _weightCtrl.text = (profile['weight'] ?? '').toString();
        _waistCtrl.text = (profile['waist'] ?? '').toString();
        _hipCtrl.text = (profile['hip'] ?? '').toString();
        _bustCtrl.text = (profile['bust'] ?? '').toString();

        String bodyShape = profile['bodyShape'] ?? "Unknown";
        _selectedBodyShape = _bodyShapes.contains(bodyShape) ? bodyShape : "Unknown";

        String skinTone = profile['skinTone'] ?? "Unknown";
        _selectedSkinTone = _skinTones.contains(skinTone) ? skinTone : "Unknown";

        // Load dữ liệu sở thích từ API vào mảng hiển thị UI
        _userPreferences.clear();
        if (profile['favoriteStyles'] != null) {
          for (var item in profile['favoriteStyles']) {
            _userPreferences.add({"type": "Style", "value": item.toString()});
          }
        }
        if (profile['favoriteColors'] != null) {
          for (var item in profile['favoriteColors']) {
            _userPreferences.add({"type": "Color", "value": item.toString()});
          }
        }
        if (profile['favoriteMaterials'] != null) {
          for (var item in profile['favoriteMaterials']) {
            _userPreferences.add({"type": "Material", "value": item.toString()});
          }
        }
        if (profile['favoriteBrands'] != null) {
          for (var item in profile['favoriteBrands']) {
            _userPreferences.add({"type": "Brand", "value": item.toString()});
          }
        }

        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1950, 1, 1),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.black, onPrimary: Colors.white, onSurface: Colors.black),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobCtrl.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _addPreference(String type, String value) {
    String val = value.trim();
    if (val.isEmpty) return;

    bool exists = _userPreferences.any((p) => p['type'] == type && (p['value'] ?? '').toLowerCase() == val.toLowerCase());
    if (!exists) {
      setState(() {
        _userPreferences.add({"type": type, "value": val});
        _valCtrl.clear();
      });
    }
  }

  Future<void> _onSave() async {
    setState(() => _isSaving = true);

    // Tách dữ liệu sở thích ra theo type để gửi về Backend
    List<String> favStyles = _userPreferences.where((p) => p['type'] == 'Style').map((p) => p['value']!).toList();
    List<String> favColors = _userPreferences.where((p) => p['type'] == 'Color').map((p) => p['value']!).toList();
    List<String> favMaterials = _userPreferences.where((p) => p['type'] == 'Material').map((p) => p['value']!).toList();
    List<String> favBrands = _userPreferences.where((p) => p['type'] == 'Brand').map((p) => p['value']!).toList();

    Map<String, dynamic> payload = {
      "gender": _selectedGender,
      "dateOfBirth": _selectedDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
      "height": double.tryParse(_heightCtrl.text) ?? 0,
      "weight": double.tryParse(_weightCtrl.text) ?? 0,
      "waist": double.tryParse(_waistCtrl.text) ?? 0,
      "hip": double.tryParse(_hipCtrl.text) ?? 0,
      "bust": double.tryParse(_bustCtrl.text) ?? 0,
      "bodyShape": _selectedBodyShape,
      "skinTone": _selectedSkinTone,
      "favoriteStyles": favStyles,
      "favoriteColors": favColors,
      "favoriteMaterials": favMaterials,
      "favoriteBrands": favBrands,
    };

    final success = await UserProfileService().updateProfile(payload);

    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Profile updated successfully!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.black,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(
                  bottom: MediaQuery.of(context).size.height - 150,
                  left: 20,
                  right: 20
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            )
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Failed to update profile.", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(
                  bottom: MediaQuery.of(context).size.height - 150,
                  left: 20,
                  right: 20
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            )
        );
      }
    }
  }

  // Hàm chuyển đổi từ số int sang chữ để hiển thị trên Dropdown
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
    List<String> currentSuggestions = _defaultValues[_selectedType] ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text("PERSONAL INFO", style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Keep your profile updated to get the best AI styling recommendations.", style: TextStyle(color: Colors.black54, fontSize: 13)),
                  const SizedBox(height: 30),

                  // ================= 1. BASIC INFO =================
                  _buildSectionTitle("BASIC INFO"),
                  const SizedBox(height: 12),
                  // Vẫn giữ trường Date Of Birth
                  TextField(
                    controller: _dobCtrl,
                    readOnly: true,
                    onTap: () => _selectDate(context),
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      labelText: "Date of Birth",
                      labelStyle: const TextStyle(color: Colors.black54, fontSize: 13),
                      suffixIcon: const Icon(Icons.calendar_today, size: 18, color: Colors.black54),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 2.0)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Cập nhật lại Dropdown Gender theo Enum mới
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

                  // ================= 2. MEASUREMENTS =================
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

                  // ================= 3. APPEARANCE =================
                  _buildSectionTitle("APPEARANCE"),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildDropdown("Body Shape", _bodyShapes, _selectedBodyShape, (val) => setState(() => _selectedBodyShape = val!))),
                      const SizedBox(width: 16),
                      Expanded(child: _buildDropdown("Skin Tone", _skinTones, _selectedSkinTone, (val) => setState(() => _selectedSkinTone = val!))),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // ================= 4. STYLE PREFERENCES =================
                  _buildSectionTitle("STYLE PREFERENCES"),
                  const SizedBox(height: 12),

                  // Khung nhập liệu Type + Text
                  Row(
                    children: [
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
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _valCtrl,
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
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

                  // Thanh gợi ý (Quick Add)
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
                            onPressed: () => _addPreference(_selectedType, suggestion),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Các sở thích đã lưu
                  const Text("ADDED PREFERENCES", style: TextStyle(color: Colors.black38, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  if (_userPreferences.isEmpty)
                    const Text("No preferences added.", style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic))
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
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Nút Save ghim dưới cùng
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
                  onPressed: _isSaving ? null : _onSave,
                  child: _isSaving
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("SAVE CHANGES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.5)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helpers ---
  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black38, letterSpacing: 1.2));
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 2.0)),
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
      items: items.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value, style: const TextStyle(color: Colors.black), overflow: TextOverflow.ellipsis))).toList(),
      onChanged: onChanged,
    );
  }
}