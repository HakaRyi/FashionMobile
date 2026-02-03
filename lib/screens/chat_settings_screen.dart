import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ChatSettingsScreen extends StatelessWidget {
  final String userName;
  final String avatarUrl;

  const ChatSettingsScreen({super.key, required this.userName, required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Phần Header: Avatar lớn
          Center(
            child: Column(
              children: [
                CircleAvatar(radius: 50, backgroundImage: NetworkImage(avatarUrl)),
                const SizedBox(height: 16),
                Text(userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Danh sách các mục cài đặt
          Expanded(
            child: ListView(
              children: [
                _buildActionItem(Icons.search, "Tìm kiếm cuộc trò chuyện"),
                _buildActionItem(Icons.edit_note, "Biệt danh"),
                _buildActionItem(Icons.palette_outlined, "Chủ đề"),
                _buildActionItem(Icons.groups_outlined, "Tạo nhóm với $userName"),
                _buildActionItem(Icons.image_outlined, "Xem file phương tiện & lịch sử hình ảnh"),
                const Divider(color: AppColors.divider, height: 40),
                _buildActionItem(Icons.notifications_off_outlined, "Tắt thông báo"),
                _buildActionItem(Icons.block_flipped, "Chặn", isDanger: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String title, {bool isDanger = false}) {
    return ListTile(
      leading: Icon(icon, color: isDanger ? Colors.redAccent : Colors.white),
      title: Text(title, style: TextStyle(color: isDanger ? Colors.redAccent : Colors.white, fontSize: 15)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
      onTap: () {},
    );
  }
  Widget _buildMediaHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            "File phương tiện đã gửi",
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20),
            itemCount: 5,
            itemBuilder: (context, index) {
              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: const DecorationImage(
                    image: NetworkImage("https://picsum.photos/200"),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}