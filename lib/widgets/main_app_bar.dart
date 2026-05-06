import 'package:fashion_mobile/screens/notification_screen.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../screens/chat_list_screen.dart';
import '../utils/notification_manager.dart';
import '../utils/route_transitions.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MainAppBar({super.key});

  void _openNotificationScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationScreen(),
      ),
    ).then((_) {
      notificationManager.fetchNotificationHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: false,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 10),
          Text(
            'WAPO',
            style: GoogleFonts.playfairDisplay(
              textStyle: const TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 4.0,
              ),
            ),
          ),
        ],
      ),
      actions: [
        ListenableBuilder(
          listenable: notificationManager,
          builder: (context, child) {
            return IconButton(
              onPressed: () => _openNotificationScreen(context),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    PhosphorIcons.bell(),
                    color: AppColors.textPrimary,
                    size: 26,
                  ),
                  if (notificationManager.hasUnreadNotification)
                    Positioned(
                      right: -1,
                      top: -1,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.background,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              SlideRoute(page: const ChatListScreen()),
            );
          },
          icon: Icon(
            PhosphorIcons.chatsCircle(),
            color: AppColors.textPrimary,
            size: 26,
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}