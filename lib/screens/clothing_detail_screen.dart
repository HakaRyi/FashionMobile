import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/detail_image.dart';
import '../widgets/attribute_field.dart';

class ClothingDetailScreen extends StatelessWidget {
  final String title;
  final String imagePath;

  const ClothingDetailScreen({
    super.key,
    required this.title,
    required this.imagePath
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: () => print("Đã lưu chỉnh sửa"),
            icon: const Icon(Icons.check, color: AppColors.textPink),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Gọi Widget ảnh đã tách
            DetailImage(imagePath: imagePath),

            const SizedBox(height: 24),

            // Phần thông tin thuộc tính
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const AttributeField(
                    label: "Tên món đồ",
                    initialValue: "Áo Thun Đội Tuyển Việt Nam 2022",
                    icon: Icons.label_outline,
                  ),
                  const AttributeField(
                    label: "Dịp",
                    initialValue: "Thể thao",
                    icon: Icons.calendar_view_day,
                  ),
                  const AttributeField(
                    label: "Loại",
                    initialValue: "Áo",
                    icon: Icons.category_outlined,
                  ),
                  const AttributeField(
                    label: "Chất liệu",
                    initialValue: "Thun",
                    icon: Icons.category,
                  ),
                  const AttributeField(
                    label: "Màu sắc",
                    initialValue: "Đỏ",
                    icon: Icons.color_lens_outlined,
                  ),
                  const AttributeField(
                    label: "Thương hiệu",
                    initialValue: "Grand Sport",
                    icon: Icons.branding_watermark_rounded,
                  ),
                  const AttributeField(
                    label: "Size",
                    initialValue: "XL",
                    icon: Icons.straighten,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Nút Xóa món đồ
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              label: const Text("Xóa khỏi tủ đồ", style: TextStyle(color: Colors.redAccent)),
            )
          ],
        ),
      ),
    );
  }
}