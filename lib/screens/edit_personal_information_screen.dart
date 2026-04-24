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

  DateTime? _selectedDate;
  int _selectedGender = 0; // 0: Female, 1: Male, 2: Unisex
  String _selectedBodyShape = "Unknown";
  String _selectedSkinTone = "Unknown";

  final List<String> _bodyShapes = ["Hourglass", "Rectangle", "Triangle", "Inverted Triangle", "Apple", "Unknown"];
  final List<String> _skinTones = ["Light", "Medium", "Dark", "Unknown"];

  // Style Preferences
  final List<String> _availableStyles = ["Minimalist", "Streetwear", "Vintage", "Casual", "Formal", "Sporty"];
  List<String> _selectedStyles = [];

  @override
  void initState() {
    super.initState();
    _fetchMyData();
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

        if (profile['favoriteStyles'] != null) {
          _selectedStyles = List<String>.from(profile['favoriteStyles']);
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

  Future<void> _onSave() async {
    setState(() => _isSaving = true);

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
      "favoriteStyles": _selectedStyles,
      "favoriteColors": ["Black", "White"], // Giữ nguyên theo payload cũ
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          )
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Failed to update profile.", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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

                        // 1. Basic Info
                        _buildSectionTitle("BASIC INFO"),
                        const SizedBox(height: 12),
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
                        _buildDropdown(
                          "Gender",
                          ["Female", "Male", "Unisex"],
                          _selectedGender == 0 ? "Female" : (_selectedGender == 1 ? "Male" : "Unisex"),
                          (val) {
                            setState(() => _selectedGender = val == "Female" ? 0 : (val == "Male" ? 1 : 2));
                          },
                        ),
                        const SizedBox(height: 30),

                        // 2. Measurements
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

                        // 3. Appearance
                        _buildSectionTitle("APPEARANCE"),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildDropdown("Body Shape", _bodyShapes, _selectedBodyShape, (val) => setState(() => _selectedBodyShape = val!))),
                            const SizedBox(width: 16),
                            Expanded(child: _buildDropdown("Skin Tone", _skinTones, _selectedSkinTone, (val) => setState(() => _selectedSkinTone = val!))),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // 4. Style Preferences
                        _buildSectionTitle("STYLE PREFERENCES"),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _availableStyles.map((style) {
                            final isSelected = _selectedStyles.contains(style);
                            return FilterChip(
                              label: Text(style),
                              selected: isSelected,
                              selectedColor: Colors.black,
                              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.w600),
                              backgroundColor: Colors.grey.shade100,
                              checkmarkColor: Colors.white,
                              onSelected: (bool value) {
                                setState(() {
                                  if (value) {
                                    _selectedStyles.add(style);
                                  } else {
                                    _selectedStyles.remove(style);
                                  }
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