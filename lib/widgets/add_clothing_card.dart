import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../utils/upload_utils.dart';

class AddClothingCard extends StatelessWidget {
  // 1. Khai báo hàm callback
  final VoidCallback? onUploadSuccess;

  // 2. Thêm vào constructor
  const AddClothingCard({super.key, this.onUploadSuccess});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // 3. Đợi kết quả từ menu upload
        final result = await UploadUtils.showUploadMenu(context);

        // 4. Nếu upload thành công (trả về true), gọi hàm callback để load lại trang
        if (result == true && onUploadSuccess != null) {
          onUploadSuccess!();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white, style: BorderStyle.solid),
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