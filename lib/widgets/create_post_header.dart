import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../screens/create_post_screens.dart';

class CreatePostHeader extends StatefulWidget {
  const CreatePostHeader({super.key});

  @override
  State<CreatePostHeader> createState() => _CreatePostHeaderState();
}

class _CreatePostHeaderState extends State<CreatePostHeader> {
  String _username = "Đang tải...";
  String _avatar = "";

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  // Hàm lấy dữ liệu từ SharedPreferences đã được AuthService lưu
  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Lấy theo key bạn đã đặt trong AuthService: 'username' và 'avatar'
      _username = prefs.getString('username') ?? "Người dùng";
      _avatar = prefs.getString('avatar') ?? "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Hiển thị Avatar từ URL đã lưu
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.divider,
                backgroundImage: _avatar.isNotEmpty
                    ? NetworkImage(_avatar)
                    : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Hiển thị Username từ Token đã giải mã
                    Text(
                      _username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
                          );
                        },
                        borderRadius: BorderRadius.circular(15),
                        child: Ink(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: const Text(
                            "Hôm nay bạn mặc gì?",
                            style: TextStyle(color: Colors.white54, fontSize: 14),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}