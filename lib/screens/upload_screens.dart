import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../constants/api_constants.dart';
import '../constants/fashion_constants.dart'; // Đảm bảo đã import hằng số
import '../widgets/ai_result_panel.dart';

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
        _aiResult = null;
      });
    } else if (_image == null) {
      Navigator.pop(context);
    }
  }

  Future<void> _analyzeFashion() async {
    if (_image == null) return;
    setState(() => _isAnalyzing = true);

    try {
      final processUrl = Uri.parse("${ApiConstants.baseAIUrl}/process-image");
      var request = http.MultipartRequest('POST', processUrl);
      request.files.add(await http.MultipartFile.fromPath('file', _image!.path));

      var streamRes = await request.send();
      var res = await http.Response.fromStream(streamRes);

      if (res.statusCode == 200) {
        var jsonImg = jsonDecode(res.body);
        String remoteUrl = jsonImg['processed_url'];

        setState(() {
          _aiResult = {'processed_url': remoteUrl, 'data': {}};
        });
          final classifyUrl = Uri.parse("${ApiConstants.baseAIUrl}/analyze-fashion?image_url=$remoteUrl");
          final resAI = await http.get(classifyUrl);

          if (resAI.statusCode == 200) {
            var jsonAI = jsonDecode(resAI.body);
            Map<String, dynamic> detected = Map<String, dynamic>.from(jsonAI['detected_info']);
            final Map<String, String> aiToAppMapper = {
              'item': 'itemType',
              'category': 'category',
              'sub_category': 'subCategory',
              'gender': 'gender',
              'main_color': 'mainColor',
              'sub_color': 'subColor',
              'material': 'material',
              'style': 'style',
              'pattern': 'pattern',
              'fit': 'fit',
              'neckline': 'neckline',
              'sleeve_length': 'sleeveLength',
              'length': 'length',
            };
            final prefs = await SharedPreferences.getInstance();
            final userName = prefs.getString('username') ?? "User";
            setState(() {
              _aiResult['data'] = detected;
              _selectedAttributes = {};
              detected.forEach((aiKey, value) {
                String appKey = aiToAppMapper[aiKey] ?? aiKey;
                _selectedAttributes[appKey] = value.toString();
              });
              _selectedAttributes['size'] = "";
              String finalItemType = _selectedAttributes['itemType'] ?? "clothing";
              _selectedAttributes['itemName'] = "New $userName's $finalItemType";
              _selectedAttributes['description'] = jsonAI['suggested_summary']?? "";
              _selectedAttributes['isPublic'] = "false";
              _selectedAttributes['itemType'] = detected['item'] ?? "clothing";
            });
          }
      }
    } catch (e) {
      _showToast("AI Error: $e");
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _initializeEmptyAttributes() {
    setState(() {
      _aiResult = {
        'processed_url': _aiResult?['processed_url'] ?? '',
        'data': <String, dynamic>{}
      };
      // Khởi tạo toàn bộ field từ bộ hằng số dùng chung
      for (var key in FashionConstants.categories.keys) {
        _selectedAttributes[key] = _selectedAttributes[key] ?? "";
      }
    });
  }

  Future<void> _saveToDatabase() async {
    setState(() => _isAnalyzing = true);
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('username');
    final String itemType = _selectedAttributes['itemName'] ?? "item";
    final token = prefs.getString('token');

    try {
      bool isPublicBool = _selectedAttributes['isPublic'] == "true";
      print("Dữ liệu thực tế trong Map: $_selectedAttributes");
      final Map<String, dynamic> body = {
        "itemName": _selectedAttributes['itemName'] ?? "New Fashion Item",
        "itemType": _selectedAttributes['itemType'] ?? "clothing",
        "size": _selectedAttributes['size'],
        "category": _selectedAttributes['category'] ?? "upper_body",
        "subCategory": _selectedAttributes['subCategory'] ?? "top",
        "style": _selectedAttributes['style'] ?? "casual",
        "gender": _selectedAttributes['gender'] ?? "unisex",
        "mainColor": _selectedAttributes['mainColor'] ?? "unknown",
        "subColor": _selectedAttributes['subColor'] ?? "none",
        "material": _selectedAttributes['material'] ?? "cotton",
        "pattern": _selectedAttributes['pattern'] ?? "solid",
        "fit": _selectedAttributes['fit'] ?? "regular",
        "neckline": _selectedAttributes['neckline'] ?? "none",
        "sleeveLength": _selectedAttributes['sleeveLength'] ?? "none",
        "length": _selectedAttributes['length'] ?? "none",
        "brand": _selectedAttributes['brand'] ?? "none",
        "description": _selectedAttributes['description'] ?? "",
        "isPublic": isPublicBool,
        "status": 1, // Enum: 1 = Active
        "primaryImageUrl": _aiResult['processed_url']
      };
      print("JSON SENDING TO SERVER: ${jsonEncode(body)}");

      final response = await http.post(
        Uri.parse("${ApiConstants.baseUrl}${ApiConstants.uploadItemEndpoint}"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showToast("Added to wardrobe successfully!");
        Navigator.pop(context, true);
      } else {
        _showToast("Server Error: ${response.body}");
      }
    } catch (e) {
      _showToast("Connection Error");
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _showToast(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("AI CLASSIFICATION", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
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
        label: const Text("START ANALYSIS", style: TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pinkAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }
}

class _AnalyzingLoader extends StatelessWidget {
  const _AnalyzingLoader();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CircularProgressIndicator(color: Colors.pinkAccent),
        const SizedBox(height: 16),
        Text("AI is analyzing & removing background...",
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
      ],
    );
  }
}