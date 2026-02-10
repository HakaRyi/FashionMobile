import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../utils/upload_utils.dart';
import '../widgets/model_option_button.dart'; //widget này cho cái nút chụp ảnh và tải lên
import '../widgets/model_grid_item.dart';    //widget này là widget cho mấy item người mẫu, sau này mún custom hoặc sửa thì sửa trong nì

class ModelManagementScreen extends StatefulWidget {
  const ModelManagementScreen({super.key});

  @override
  State<ModelManagementScreen> createState() => _ModelManagementScreenState();
}

class _ModelManagementScreenState extends State<ModelManagementScreen> {
  // Giả lập ID người mẫu đang được chọn
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text("Quản lý người mẫu",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- PHẦN LƯU Ý ---
            _buildGuidelines(),

            const SizedBox(height: 24),

            // --- CÁC NÚT TẢI ẢNH (SỬ DỤNG WIDGET RIÊNG & UTILS) ---
            Row(
              children: [
                ModelOptionButton(
                  icon: Icons.camera_alt,
                  label: "Chụp ảnh",
                  color: Colors.orange,
                  onTap: () => UploadUtils.openCamera(context),
                ),
                const SizedBox(width: 12),
                ModelOptionButton(
                  icon: Icons.photo_library,
                  label: "Tải lên",
                  color: AppColors.textPink,
                  onTap: () => UploadUtils.openGallery(context),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // --- DANH SÁCH MODEL ---
            const Text("Người mẫu có sẵn",
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 2,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.7,
              ),
              itemBuilder: (context, index) {
                return ModelGridItem(
                  imagePath: "assets/images/human1.jpg",
                  isSelected: selectedIndex == index,
                  onTap: () => setState(() => selectedIndex = index),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Tách nhỏ phần Guidelines để build() không quá dài
  Widget _buildGuidelines() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.blueAccent),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Lưu ý khi tải ảnh:",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text("• Hình ảnh phải rõ nét, không bị mờ.",
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                Text("• Chỉ chứa duy nhất 1 người trong hình.",
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                Text("• Chụp chính diện, rõ vóc dáng người.",
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}