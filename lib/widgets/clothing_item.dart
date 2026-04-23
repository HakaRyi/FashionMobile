import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ClothingItem extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ClothingItem({
    super.key,
    required this.title,
    this.imageUrl,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.stroke, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                child: Container(
                  width: double.infinity,
                  color: Colors.white,
                  child: (imageUrl != null && imageUrl!.startsWith('http'))
                      ? Image.network(imageUrl!, fit: BoxFit.contain)
                      : const Icon(Icons.checkroom, color: AppColors.textSecondary, size: 40),
                ),
              ),
            ),
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
            //   child: Text(
            //     title,
            //     style: const TextStyle(
            //       color: AppColors.textPrimary,
            //       fontSize: 13,
            //       fontWeight: FontWeight.w600,
            //       letterSpacing: 0.3,
            //     ),
            //     maxLines: 1,
            //     overflow: TextOverflow.ellipsis,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}