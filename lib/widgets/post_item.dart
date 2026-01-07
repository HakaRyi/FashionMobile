import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class PostItem extends StatelessWidget {
  const PostItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //avatar
          const CircleAvatar(
              backgroundColor: AppColors.divider,
              child: Icon(Icons.person, color: AppColors.textPrimary)
          ),
          const SizedBox(width: 12),


          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    "nguyen_van_a",
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 4),
                const Text(
                    "do dep ko",
                    style: TextStyle(color: AppColors.textPrimary)
                ),
                const SizedBox(height: 10),
                Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: const Center(
                      child: Icon(Icons.style, color: AppColors.textSecondary, size: 40)
                  ),
                ),

                //like cmt share
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Icon(Icons.favorite_border, color: AppColors.textPrimary, size: 20),
                    SizedBox(width: 15),
                    Icon(Icons.chat_bubble_outline, color: AppColors.textPrimary, size: 20),
                    SizedBox(width: 15),
                    Icon(Icons.send_outlined, color: AppColors.textPrimary, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}