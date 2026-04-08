import 'package:fashion_mobile/screens/notification_screen.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../constants/app_colors.dart';
import '../utils/route_transitions.dart';
import '../screens/chat_list_screen.dart';
class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MainAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: false,

      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/logowapo.png',
            height: 35,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),
          const Text(
            "WAPO",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900, // Độ đậm cực cao để tạo phong cách Brand
              letterSpacing: 1.2,          // Khoảng cách chữ rộng ra chút cho sang
              fontFamily: 'Montserrat',    // Nếu bạn có font riêng, hoặc dùng mặc định
            ),
          ),

        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NotificationScreen())
            );
          },
          icon: const Icon(Icons.notifications_none, color: AppColors.textPrimary),
        ),
        IconButton(
          onPressed: () {
             Navigator.push(context, SlideRoute(page: const ChatListScreen()));
          },
          icon: Icon(PhosphorIcons.chatsCircle(), color: AppColors.textPrimary)
        )
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}