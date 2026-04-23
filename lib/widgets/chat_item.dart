import 'package:flutter/material.dart';

class ChatItem extends StatelessWidget {
  final String name;
  final String lastMessage;
  final String time;
  final String avatarUrl;
  final bool isOnline;
  final bool isUnread;
  final VoidCallback onTap;

  const ChatItem({super.key, required this.name, required this.lastMessage, required this.time,
    required this.avatarUrl, required this.onTap, this.isOnline = false, this.isUnread = false});

  String _formatTime(String rawTime) {
    if (rawTime.isEmpty) return "";
    try {
      DateTime dt = DateTime.parse(rawTime.endsWith('Z') || rawTime.contains('+') ? rawTime : '${rawTime}Z').toLocal();
      DateTime now = DateTime.now();
      if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
        return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
      }
      return "${dt.day}/${dt.month}";
    } catch (e) { return ""; }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  backgroundImage: NetworkImage(avatarUrl),
                ),
                if (isOnline)
                  Positioned(
                    right: 0, bottom: 0,
                    child: Container(
                      height: 14, width: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00FF00),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: TextStyle(color: Colors.black, fontWeight: isUnread ? FontWeight.w900 : FontWeight.w500, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(lastMessage,
                      style: TextStyle(color: isUnread ? Colors.black : Colors.black45,
                          fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400, fontSize: 13),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_formatTime(time),
                    style: TextStyle(color: isUnread ? Colors.black : Colors.black26, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (isUnread)
                  Container(
                    width: 10, height: 10,
                    decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}