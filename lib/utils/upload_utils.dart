import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../screens/upload_screens.dart';

class UploadUtils {
  static void openCamera(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UploadScreen(isCamera: true)),
    );
  }

  static void openGallery(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UploadScreen(isCamera: false)),
    );
  }

  // Hàm dùng chung cho toàn bộ App
  static void showUploadMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: const Text("Chụp ảnh mới", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UploadScreen(isCamera: true)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: const Text("Chọn từ thư viện", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UploadScreen(isCamera: false)),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}