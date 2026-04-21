import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ChatItem extends StatelessWidget {
  final String name;
  final String lastMessage;
  final String time;
  final String avatarUrl;
  final bool isOnline; // Thêm thuộc tính này
  final bool isUnread;
  final VoidCallback onTap;


  const ChatItem({
    super.key,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.avatarUrl,
    required this.onTap,
    this.isOnline = false,
    this.isUnread = false,
  });
  String _formatTime(String rawTime) {
    if (rawTime.isEmpty) return "";
    try {

      String timeStr = rawTime;
      if (!timeStr.endsWith('Z') && !timeStr.contains('+')) {
        timeStr += 'Z';
      }

      DateTime dt = DateTime.parse(timeStr).toLocal();
      DateTime now = DateTime.now();

      if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
        return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
      }

      DateTime yesterday = now.subtract(const Duration(days: 1));
      if (dt.day == yesterday.day && dt.month == yesterday.month && dt.year == yesterday.year) {
        return "Yesterday";
      }

      return "${dt.day}/${dt.month}";
    } catch (e) {
      return "";
    }
  }
  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.divider,
            backgroundImage: NetworkImage(avatarUrl),
          ),
          if (isOnline)
            Positioned(
              right: 1,
              bottom: 1,
              child: Container(
                height: 14,
                width: 14,
                decoration: BoxDecoration(
                  color: Colors.greenAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        name,
        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Text(
        lastMessage,
        style: TextStyle(
          color: isUnread ? Colors.black : Colors.black87,
          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(time), // GỌI HÀM FORMAT Ở ĐÂY
            style: TextStyle(
                color: isUnread ? AppColors.textPink : Colors.black26,
                fontSize: 11
            ),
          ),
          const SizedBox(height: 5),
          if (isUnread)
            Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(color: AppColors.textPink, shape: BoxShape.circle),
              child: const Center(
                  child: Text("!", style: TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold))
              ),
            ),
        ],
      ),
    );
  }
}