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
  static Future<bool?> showUploadMenu(BuildContext context) async {
    return await showModalBottomSheet<bool>( // Thêm <bool> ở đây
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Chụp ảnh"),
              onTap: () async {
                // Phải có await và trả kết quả về cho BottomSheet bằng Navigator.pop
                final uploaded = await Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadScreen(isCamera: true)));
                Navigator.pop(context, uploaded); // Trả 'true' về cho WardrobeScreen
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Thư viện"),
              onTap: () async {
                final uploaded = await Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadScreen(isCamera: false)));
                Navigator.pop(context, uploaded); // Trả 'true' về cho WardrobeScreen
              },
            ),
          ],
        );
      },
    );
  }
}