import 'package:fashion_mobile/screens/notification_screen.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../constants/app_colors.dart';
import '../utils/route_transitions.dart';
import '../screens/chat_list_screen.dart';
import 'package:google_fonts/google_fonts.dart';
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
          // Image.asset(
          //   'assets/images/logowapo.png',
          //   height: 35,
          //   fit: BoxFit.contain,
          // ),
          const SizedBox(width: 10),
           Text(
            "WAPO",
            style: GoogleFonts.playfairDisplay( // Thay đổi tên font ở đây
              textStyle: const TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 4.0, // Tăng giãn chữ cho sang
              ),
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
          icon:  Icon(PhosphorIcons.bell(), color: AppColors.textPrimary, size: 26),
        ),
        IconButton(
          onPressed: () {
             Navigator.push(context, SlideRoute(page: const ChatListScreen()));
          },
          icon: Icon(PhosphorIcons.chatsCircle(), color: AppColors.textPrimary, size: 26),
        )
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}