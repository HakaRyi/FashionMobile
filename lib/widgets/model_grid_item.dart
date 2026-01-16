import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ModelGridItem extends StatelessWidget {
  final String imagePath;
  final bool isSelected;
  final VoidCallback onTap;

  const ModelGridItem({
    super.key,
    required this.imagePath,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? AppColors.textPink : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
          ),
        ),
        // Hiển thị dấu tích nếu được chọn
        child: isSelected
            ? Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: AppColors.textPink,
              radius: 12,
              child: const Icon(Icons.check, color: Colors.white, size: 16),
            ),
          ),
        )
            : null,
      ),
    );
  }
}