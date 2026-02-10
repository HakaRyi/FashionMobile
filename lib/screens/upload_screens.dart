import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';

class UploadScreen extends StatefulWidget {
  final bool isCamera;
  const UploadScreen({super.key, required this.isCamera});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();

  // Hàm xử lý lấy ảnh
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: widget.isCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 80, // Nén ảnh lại một chút cho nhẹ
    );

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _pickImage(); // Tự động mở camera/gallery khi vào màn hình
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isCamera ? "Chụp ảnh đồ" : "Chọn từ thư viện"),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          if (_image != null)
            IconButton(
              onPressed: () => print("Tiến hành Upload lên Server"),
              icon: const Icon(Icons.check, color: AppColors.textPink),
            )
        ],
      ),
      body: Center(
        child: _image == null
            ? const Text("Chưa chọn ảnh", style: TextStyle(color: Colors.white))
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hiển thị ảnh đã chọn
            Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.width * 1.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                image: DecorationImage(
                  image: FileImage(_image!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.refresh),
              label: const Text("Chọn lại ảnh"),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.surface),
            ),
          ],
        ),
      ),
    );
  }
}