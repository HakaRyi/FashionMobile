import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../utils/upload_utils.dart';

class AddClothingCard extends StatelessWidget {
  final VoidCallback? onUploadSuccess;

  const AddClothingCard({super.key, this.onUploadSuccess});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final result = await UploadUtils.showUploadMenu(context);

          if (result == true && onUploadSuccess != null) {
            onUploadSuccess!();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface, // Nền xám nhạt tinh tế
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.stroke, width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.stroke, width: 0.5),
                ),
                child: const Icon(
                  Icons.add,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Thêm đồ mới",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}