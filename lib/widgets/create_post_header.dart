import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../screens/create_post_screens.dart';
import '../services/account_service.dart';

class CreatePostHeader extends StatefulWidget {
  const CreatePostHeader({super.key});

  @override
  State<CreatePostHeader> createState() => _CreatePostHeaderState();
}

class _CreatePostHeaderState extends State<CreatePostHeader> with SingleTickerProviderStateMixin {
  String _avatar = "";
  final AccountService _accountService = AccountService();
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _fetchUserData();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000), // 3 giây: Tốc độ tối ưu cho sự mượt mà
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    try {
      final profileData = await _accountService.getMyProfile();
      if (profileData != null && mounted) {
        setState(() => _avatar = profileData['avatar'] ?? "");
      }
    } catch (e) {
      debugPrint("Lỗi khi load header: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.05), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08), // Tăng độ đậm lên một chút (từ 0.02 -> 0.06)
            blurRadius: 30,                       // Độ nhòe của bóng
            offset: const Offset(0, 10),           // Hướng bóng đổ xuống dưới (trục Y là 8)
            spreadRadius: 2,                      // Độ lan tỏa của bóng
          ),
        ],
      ),
      // Dùng ClipRRect để hiệu ứng ánh sáng không tràn ra khỏi bo góc của thẻ
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // LỚP 1: NỀN HIỆU ỨNG ÁNH SÁNG (Nằm dưới cùng)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: const [
                          Color(0xFFF5F5F5),
                          Color(0xFFF5F5F5),
                          Colors.white, // Vệt sáng lướt qua
                          Color(0xFFF5F5F5),
                          Color(0xFFF5F5F5),
                        ],
                        stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                        // Dịch chuyển ma trận để mượt tuyệt đối không khựng
                        transform: _GradientTranslateTransform(
                          (_controller.value * 2 - 1) * 400, // Tính toán khoảng cách dịch chuyển
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // LỚP 2: NỘI DUNG (Avatar, Text - Nằm trên lớp ánh sáng)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black.withOpacity(0.05), width: 1),
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFFEEEEEE),
                      backgroundImage: _avatar.isNotEmpty
                          ? NetworkImage(_avatar)
                          : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CreatePostScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          // Màu nền của ô text trong suốt nhẹ để thấy ánh sáng lướt qua bên dưới
                          color: Colors.black.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          "What are you wearing today?",
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// LỚP TRỢ GIÚP DỊCH CHUYỂN GRADIENT KHÔNG KHỰNG
class _GradientTranslateTransform extends GradientTransform {
  final double dx;
  const _GradientTranslateTransform(this.dx);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(dx, 0, 0);
  }
}