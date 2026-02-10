import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input_field.dart';
import '../screens/chat_settings_screen.dart'; // Màn hình chúng ta sẽ tạo bên dưới

class ChatScreen extends StatelessWidget {
  final String userName;
  final String avatarUrl; // Nên truyền từ danh sách chat qua
  final bool isOnline;    // Kiểm tra trạng thái

  const ChatScreen({
    super.key,
    required this.userName,
    required this.avatarUrl,
    this.isOnline = true, // Demo mặc định là online
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0.5,
        leadingWidth: 40,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
                builder: (context) => ChatSettingsScreen(userName: userName, avatarUrl: avatarUrl)
            ));
          },
          child: Row(
            children: [
              // Avatar với chấm trạng thái
              Stack(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(avatarUrl),
                  ),
                  if (isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 10,
                        width: 10,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.background, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              // Tên và nút mũi tên
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(userName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        const Icon(Icons.keyboard_arrow_right, color: Colors.white70, size: 18),
                      ],
                    ),
                    if (isOnline)
                      const Text("Đang hoạt động", style: TextStyle(color: Colors.greenAccent, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.videocam_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.call_outlined, size: 20), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                ChatBubble(message: "Chào bạn! Bộ đồ này mua ở đâu vậy?", isMe: false),
                ChatBubble(message: "Chào bạn! Mình tự thiết kế trên app đó.", isMe: true),

              ],
            ),
          ),
          const ChatInputField(),
        ],
      ),
    );
  }
}