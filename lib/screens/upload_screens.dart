import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../constants/api_constants.dart';
import '../widgets/ai_result_panel.dart';
import 'package:http_parser/http_parser.dart';
class UploadScreen extends StatefulWidget {
  final bool isCamera;
  const UploadScreen({super.key, required this.isCamera});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;
  dynamic _aiResult;
  Map<String, String> _selectedAttributes = {};

  @override
  void initState() {
    super.initState();
    // Tự động mở camera/gallery khi màn hình vừa hiện lên
    WidgetsBinding.instance.addPostFrameCallback((_) => _pickImage());
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: widget.isCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _aiResult = null; // Reset kết quả cũ để chọn lại
      });
    } else if (_image == null) {
      Navigator.pop(context);
    }
  }

  // --- HÀM GỌI AI: Đã được sửa để xử lý Response an toàn hơn ---
  Future<void> _analyzeFashion() async {
    if (_image == null) return;
    setState(() => _isAnalyzing = true);

    try {
      final url = Uri.parse("${ApiConstants.baseAIUrl}${ApiConstants.AIidentityClothesEndpoint}");
      var request = http.MultipartRequest('POST', url);

      // Xác định định dạng file (ví dụ: jpg, png)
      String extension = _image!.path.split('.').last.toLowerCase();
      if (extension == 'jpg') extension = 'jpeg'; // API thường mong đợi jpeg thay vì jpg

      // THAY ĐỔI Ở ĐÂY: Thêm contentType
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        _image!.path,
        contentType: MediaType('image', extension), // Ép kiểu image/jpeg hoặc image/png
      ));

      // Thêm header Accept để khớp với curl
      request.headers.addAll({
        'accept': 'application/json',
      });

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        var json = jsonDecode(utf8.decode(response.bodyBytes));
        if (json['status'] == 'success') {
          setState(() {
            _aiResult = json;
            _selectedAttributes.clear();
            Map<String, dynamic> data = json['data'];
            data.forEach((key, value) {
              if (value is List && value.isNotEmpty) {
                _selectedAttributes[key] = value[0]['label'].toString();
              }
            });
          });
        }
      } else {
        _showToast("Lỗi ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      _showToast("Lỗi kết nối: $e");
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _saveToDatabase() async {
    setState(() => _isAnalyzing = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final Map<String, dynamic> body = {
        "PrimaryImageUrl": _aiResult['processed_url'],
        "ItemName": _selectedAttributes['item'] ?? "New Item",
        "Style": _selectedAttributes['style'] ?? "",
        "MainColor": _selectedAttributes['color'] ?? "",
        "Pattern":_selectedAttributes['pattern'] ?? "",
        "Fabric": _selectedAttributes['fabric'] ?? "",
        "Description": _selectedAttributes['details'] ?? "",
        "Placement": _selectedAttributes['placement']?? "",
        "Texture": _selectedAttributes['visual_texture'] ?? "",
        "Brand": _selectedAttributes['graphic_branding'] ?? "",
      };

      print("Gửi dữ liệu lưu: ${jsonEncode(body)}");

      final response = await http.post(
        Uri.parse("${ApiConstants.baseUrl}${ApiConstants.uploadItemEndpoint}"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showToast("Lưu vào tủ đồ thành công! ✨");
        // Quay về trang Wardrobe và refresh
        Navigator.pop(context, true);
      } else {
        print("Lỗi Backend: ${response.body}");
        _showToast("Lỗi lưu DB: ${response.statusCode}");
      }
    } catch (e) {
      _showToast("Lỗi kết nối lưu trữ: $e");
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("AI Phân loại", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          if (_aiResult != null && !_isAnalyzing)
            IconButton(
              onPressed: _saveToDatabase,
              icon: const Icon(Icons.cloud_upload_outlined, color: Colors.pinkAccent),
            )
        ],
      ),
      body: _image == null
          ? const Center(child: CircularProgressIndicator(color: Colors.pinkAccent))
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            _buildImagePreview(),
            const SizedBox(height: 24),
            if (_isAnalyzing)
              const _AnalyzingLoader()
            else if (_aiResult == null)
              _buildInitialButton()
            else
              AIResultPanel(
                aiData: _aiResult['data'],
                selectedAttributes: _selectedAttributes,
                onAttributeSelected: (key, val) => setState(() => _selectedAttributes[key] = val),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.width * 1.1,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _aiResult != null
              ? Image.network(
            _aiResult['processed_url'],
            key: ValueKey(_aiResult['processed_url']),
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loading) {
              if (loading == null) return child;
              return const Center(child: CircularProgressIndicator(color: Colors.white24));
            },
          )
              : Image.file(_image!, key: ValueKey(_image!.path), fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _buildInitialButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: _analyzeFashion,
        icon: const Icon(Icons.auto_awesome, size: 20),
        label: const Text("BẮT ĐẦU PHÂN LOẠI", style: TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pinkAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }
}

// Widget phụ hiển thị khi đang load AI
class _AnalyzingLoader extends StatelessWidget {
  const _AnalyzingLoader();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CircularProgressIndicator(color: Colors.pinkAccent),
        const SizedBox(height: 16),
        Text("AI đang phân tích & tách nền...",
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
      ],
    );
  }
}