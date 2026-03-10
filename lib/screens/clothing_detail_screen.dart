import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../widgets/attribute_field.dart';

class ClothingDetailScreen extends StatelessWidget {
  final Map<String, dynamic> itemData;

  const ClothingDetailScreen({super.key, required this.itemData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(itemData['itemName'] ?? "Chi tiết", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Ảnh từ Cloudinary
            Container(
              height: 350,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(itemData['primaryImageUrl'], fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 24),

            // Thuộc tính AI thực tế
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface.withOpacity(0.5), borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  AttributeField(label: "Tên", initialValue: itemData['itemName'], icon: Icons.label),
                  AttributeField(label: "Màu sắc", initialValue: itemData['mainColor'], icon: Icons.color_lens),
                  AttributeField(label: "Phong cách", initialValue: itemData['style'], icon: Icons.style),
                  AttributeField(label: "Chất liệu", initialValue: itemData['fabric'], icon: Icons.texture),
                  AttributeField(label: "Họa tiết", initialValue: itemData['pattern'], icon: Icons.grid_on),
                  AttributeField(label: "Vị trí in", initialValue: itemData['placement'] ?? "N/A", icon: Icons.place),
                  AttributeField(label: "Thương hiệu", initialValue: itemData['brand'] ?? "N/A", icon: Icons.branding_watermark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}