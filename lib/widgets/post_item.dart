import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class PostItem extends StatelessWidget {
  const PostItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const CircleAvatar(radius: 20, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=8')),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Bella Hadid", style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                    Text("2 hours ago", style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: AppColors.textSecondary),
                  onPressed: () => _showPostOptions(context),
                )
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Phối đồ phong cách tối giản cho mùa Thu 2026. #Fashion",
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.4),
            ),
          ),
          AspectRatio(
            aspectRatio: 4 / 5,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                image: const DecorationImage(
                  image: NetworkImage('https://picsum.photos/800/1000'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _interaction(Icons.favorite_rounded, "2.4K"),
                const SizedBox(width: 24),
                _interaction(Icons.mode_comment_rounded, "156"),
                const Spacer(),
                const Icon(Icons.bookmark_border_rounded, color: AppColors.textSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _interaction(IconData icon, String count) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 24),
        const SizedBox(width: 6),
        Text(count, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ],
    );
  }

  void _showPostOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Để làm bo góc mượt mà
      builder: (context) {
        return Container(
          padding: const EdgeInsets.only(bottom: 20),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E), // Màu nền menu (sáng hơn nền app xíu)
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Thanh nắm nhỏ (Handle bar)
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Item Báo cáo
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.report_gmailerrorred_rounded, color: Colors.redAccent, size: 22),
                ),
                title: const Text(
                  "Báo cáo bài viết",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: const Text(
                  "Tôi lo ngại về bài viết này",
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context); // Đóng menu
                  // TODO: Xử lý logic báo cáo ở đây (hiện dialog lý do, v.v.)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Đã gửi báo cáo")),
                  );
                },
              ),

              const Divider(color: Colors.white10, indent: 16, endIndent: 16),

              // Item phụ (Ví dụ: Không quan tâm)
              ListTile(
                leading: const Icon(Icons.visibility_off_outlined, color: AppColors.textPrimary),
                title: const Text(
                  "Không quan tâm",
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                ),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }
}