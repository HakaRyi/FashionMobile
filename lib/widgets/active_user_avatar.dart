import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ActiveUserAvatar extends StatelessWidget {
  final String avatarUrl;
  final String name;
  final bool isOnline;
  final VoidCallback? onTap;

  const ActiveUserAvatar({
    super.key,
    required this.avatarUrl,
    required this.name,
    this.isOnline = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 20),
        child: Column(
          children: [
            Stack(
              children: [
                // Vòng viền trang trí nếu đang Online (giống Instagram/Messenger)
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isOnline ? AppColors.textPink.withOpacity(0.5) : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(avatarUrl),
                  ),
                ),
                // Chấm trạng thái
                if (isOnline)
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: Container(
                      height: 12,
                      width: 12,
                      decoration: BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.background, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              name.split(" ")[0], // Chỉ lấy phần tên đầu tiên
              style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 11,
                  fontWeight: FontWeight.w500
              ),
            ),
          ],
        ),
      ),
    );
  }
}