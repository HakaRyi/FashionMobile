import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class RealNotificationItem extends StatelessWidget {
  final Map<String, dynamic> item;

  const RealNotificationItem({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final title = item['title'] ?? 'Thông báo';
    final content = item['content'] ?? '';
    final type = item['type'] ?? '';
    final createdAt = item['createdAt'] ?? 'Vừa xong';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildThumbnail(type),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Text(
                  createdAt.toString(),
                  style: TextStyle(color: AppColors.textSecondary.withOpacity(0.5), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(String type) {
    if (type == "PostStatusUpdate") {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.blueAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
        ),
        child: const Icon(Icons.verified, color: Colors.blueAccent, size: 28),
      );
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.purpleAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.notifications, color: Colors.purpleAccent),
    );
  }
}