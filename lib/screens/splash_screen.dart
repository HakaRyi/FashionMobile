import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import 'login_screen.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _letterSpacingAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000), // Tăng lên 2s cho mượt hẳn
      vsync: this,
    );

    // 1. Hiệu ứng mờ ảo (Opacity)
    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );

    // 2. Hiệu ứng trượt nhẹ từ dưới lên (Slide)
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 1.0, curve: Curves.easeOutQuart)),
    );

    // 3. Hiệu ứng dãn chữ (Letter Spacing) - Đây là bí kíp cho sự sang chảnh
    _letterSpacingAnim = Tween<double>(begin: 2.0, end: 12.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 1.0, curve: Curves.easeOutQuart)),
    );

    _controller.forward();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Chờ 2.5s để hiệu ứng diễn ra trọn vẹn
    await Future.delayed(const Duration(milliseconds: 2500));

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final refreshToken = prefs.getString('refreshToken');

    final bool hasSession =
        (refreshToken != null && refreshToken.trim().isNotEmpty) ||
            (token != null && token.trim().isNotEmpty);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 1000),
        pageBuilder: (context, animation, secondaryAnimation) =>
        hasSession ? const MainScreen() : const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Chuyển sang trắng tinh khôi cho sang
      body: Stack(
        children: [
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnim.value,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Text(
                      "WAPO",
                      style: GoogleFonts.playfairDisplay(
                        textStyle: TextStyle(
                          color: Colors.black,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          letterSpacing: _letterSpacingAnim.value, // Chữ dãn dần ra
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Thay Loading bằng một thanh line chạy nhỏ xíu ở dưới cùng cho tinh tế
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: FadeTransition(
                opacity: _opacityAnim,
                child: SizedBox(
                  width: 30,
                  child: LinearProgressIndicator(
                    minHeight: 1,
                    backgroundColor: Colors.black.withOpacity(0.05),
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black.withOpacity(0.2)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}