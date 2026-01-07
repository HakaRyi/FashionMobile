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
                const Icon(Icons.more_horiz, color: AppColors.textSecondary),
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
}