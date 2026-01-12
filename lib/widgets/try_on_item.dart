import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class TryOnItem extends StatelessWidget {
  final String imagePath;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isNetworkImage;

  const TryOnItem({
    super.key,
    required this.imagePath,
    required this.isSelected,
    required this.onTap,
    this.isNetworkImage = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.textPink : Colors.transparent,
            width: 2,
          ),
          image: DecorationImage(
            image: isNetworkImage
                ? NetworkImage(imagePath) as ImageProvider
                : AssetImage(imagePath),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}