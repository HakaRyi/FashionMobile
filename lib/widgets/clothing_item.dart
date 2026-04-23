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
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1), // Độ mờ của bóng (5%)
              blurRadius: 10, // Độ nhòe của bóng
              offset: const Offset(0, 4), // Hướng đổ bóng (xuống dưới 4px)
              spreadRadius: 1, // Độ lan tỏa
            ),
          ],
          // border: Border.all(
          //   color: AppColors.stroke.withOpacity(0),
          //   width: 1.5,
          // ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(8), // Thêm chút padding để ảnh không chạm viền
                child: (imageUrl != null && imageUrl!.startsWith('http'))
                    ? Image.network(
                  imageUrl!,
                  fit: BoxFit.contain,
                  // Khử răng cưa cho ảnh khi scale
                  filterQuality: FilterQuality.medium,
                )
                    : const Icon(Icons.checkroom, color: AppColors.textSecondary, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}