import 'package:fashion_mobile/screens/notification_screen.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

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
            'assets/images/logostarbuck1.png',
            height: 35,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),
          const Text(
            'STARBUCKS',
            style: TextStyle(
              color: AppColors.textPink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              fontFamily: 'MyCustomFont',
              letterSpacing: 1.2,
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
          onPressed: () {},
          icon: const Icon(Icons.menu, color: AppColors.textPrimary),
        )
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}