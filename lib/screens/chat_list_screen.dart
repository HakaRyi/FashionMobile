import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/chat_item.dart';
import 'chat_screen.dart';
import '../utils/route_transitions.dart';
import '../widgets/active_user_avatar.dart';
class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> chatData = [
      {"name": "Alex Designer", "lastMsg": "Bộ đồ này phối với sneaker trắng ổn không?", "time": "12:30", "avatar": "https://i.pravatar.cc/150?img=1", "isOnline": true},
      {"name": "Minh Thư", "lastMsg": "Cảm ơn bạn đã tư vấn nhé!", "time": "Hôm qua", "avatar": "https://i.pravatar.cc/150?img=5", "isOnline": false},
      {"name": "Fashion Bot", "lastMsg": "Bạn có 1 gợi ý phối đồ mới cho hôm nay.", "time": "Thứ 2", "avatar": "https://i.pravatar.cc/150?img=12", "isOnline": false},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text("TIN NHẮN", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.edit_note, color: AppColors.textPink), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // 1. THANH TÌM KIẾM
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const TextField(
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: Colors.grey),
                  hintText: "Tìm kiếm...",
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          // 2. DANH SÁCH NGƯỜI ĐANG HOẠT ĐỘNG (HORIZONTAL)
          SizedBox(
            height: 105,
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 16, top: 5),
              scrollDirection: Axis.horizontal,
              itemCount: chatData.length,
              itemBuilder: (context, index) {
                final user = chatData[index];
                return ActiveUserAvatar(
                  avatarUrl: user['avatar'],
                  name: user['name'],
                  isOnline: user['isOnline'],
                  onTap: () {
                    // Ví dụ: Nhấn vào avatar tròn cũng có thể mở nhanh trang chat
                    Navigator.push(
                        context,
                        SlideRoute(
                          page: ChatScreen(
                            userName: user['name'],
                            avatarUrl: user['avatar']?? "https://i.pravatar.cc/150?img=11", // Truyền avatarUrl
                            isOnline: user['isOnline'], // Truyền isOnline
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 3. DANH SÁCH CHAT CHÍNH
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                child: ListView.separated(
                  padding: const EdgeInsets.only(top: 10),
                  itemCount: chatData.length,
                  separatorBuilder: (context, index) => const Divider(color: Colors.white10, indent: 85),
                  itemBuilder: (context, index) {
                    final chat = chatData[index];
                    return ChatItem(
                      name: chat['name'],
                      lastMessage: chat['lastMsg'],
                      time: chat['time'],
                      avatarUrl: chat['avatar'],
                      isOnline: chat['isOnline'],
                      onTap: () {
                        Navigator.push(
                          context,
                          SlideRoute(
                            page: ChatScreen(
                              userName: chat['name'],
                              avatarUrl: chat['avatar'], // Truyền avatarUrl
                              isOnline: chat['isOnline'], // Truyền isOnline
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}