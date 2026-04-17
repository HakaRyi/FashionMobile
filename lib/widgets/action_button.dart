import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // XÓA Expanded, thay bằng SizedBox để cố định độ rộng cho các nút đều nhau
    return SizedBox(
      width: 85, // Độ rộng này giúp chữ "Phong cách" không bị xuống hàng
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          // Thêm padding ngang để nội dung không sát mép
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            // border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 30), // Giảm size icon tí cho cân đối
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1, // Đảm bảo chữ nằm trên 1 dòng
                overflow: TextOverflow.ellipsis, // Nếu dài quá thì hiện ...
              ),
            ],
          ),
        ),
      ),
    );
  }
}