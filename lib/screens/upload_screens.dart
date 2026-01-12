import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CameraUploadScreen extends StatelessWidget {
  const CameraUploadScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: const Text("Chụp ảnh đồ"), backgroundColor: AppColors.background),
    body: const Center(child: Text("Giao diện Camera ở đây", style: TextStyle(color: Colors.white))),
  );
}

class GalleryUploadScreen extends StatelessWidget {
  const GalleryUploadScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: const Text("Chọn từ thư viện"), backgroundColor: AppColors.background),
    body: const Center(child: Text("Giao diện Thư viện ảnh ở đây", style: TextStyle(color: Colors.white))),
  );
}