import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../utils/upload_utils.dart';

class AddClothingCard extends StatelessWidget {
  const AddClothingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Gọi trực tiếp từ class UploadUtils
      onTap: () => UploadUtils.showUploadMenu(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.divider, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              color: AppColors.textSecondary.withOpacity(0.5),
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              "Thêm đồ mới",
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}