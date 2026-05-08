
import 'dart:math' as math;
import 'package:fashion_mobile/screens/physical_profile_screen.dart';
import 'package:fashion_mobile/utils/app_notification.dart';
import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/notification_type.dart';
import '../managers/google_auth_manager.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/google_login_button.dart';
import 'main_screen.dart';
import 'onboarding_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final AuthService _authService = AuthService();
  final GoogleAuthManager _googleAuthManager = GoogleAuthManager();

  late AnimationController _fabricController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _fabricController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _fabricController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      NotificationService.show(
        context,
        title: "Notice",
        message: "Please enter both email and password.",
        type: NotificationType.warning,
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.login(email, password);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      final profileService = UserProfileService();
      final profile = await profileService.getMe();

      if (!mounted) return;

      if (profile != null && profile['hasCompletedOnboarding'] == false) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const PhysicalProfileScreen(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MainScreen(),
          ),
        );
      }
    } else {
      final String errorMsg = result['message'] ?? "";

      if (errorMsg.toLowerCase().contains("banned")) {
        NotificationService.show(
          context,
          title: "ACCOUNT BANNED",
          message: "Your account has been restricted for violating our terms. Please contact support for more details.",
          type: NotificationType.error,
        );
      }else{
        NotificationService.show(
          context,
          title: "Error",
          message: result['message'] ?? "Login failed. Please try again.",
          type: NotificationType.error,
        );
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    try {
      final idToken = await _googleAuthManager.getGoogleIdToken();

      if (!mounted) return;

      if (idToken == null) {
        setState(() => _isLoading = false);
        return;
      }

      final result = await _authService.loginWithGoogle(idToken);

      if (!mounted) return;

      if (result['success'] == true) {
        if (result['isNewUser'] == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const OnboardingScreen(),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MainScreen(),
            ),
          );
        }
      } else {
        NotificationService.show(
          context,
          title: "Error",
          message: result['message'] ?? "Google login failed. Please try again.",
          type: NotificationType.error,
        );
      }
    } catch (_) {
      if (mounted) {
        NotificationService.show(
          context,
          title: "Error",
          message: "Google login failed. Please try again.",
          type: NotificationType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _fabricController,
              builder: (context, child) {
                return CustomPaint(
                  painter: FabricPainter(_fabricController.value),
                );
              },
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 80),
                  // Image.asset(
                  //   'assets/images/logowapo.png',
                  //   height: 45,
                  //   fit: BoxFit.contain,
                  //   color: Colors.black,
                  // ),
                  Text(
                    "WAPO",
                    style: GoogleFonts.playfairDisplay(
                      textStyle: const TextStyle(
                        color: Colors.black,
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "WELCOME BACK",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 60),

                  CustomTextField(
                    hintText: "Email",
                    icon: Icons.email_outlined,
                    controller: _emailController,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    hintText: "Password",
                    icon: Icons.lock_outline,
                    isPassword: true,
                    controller: _passwordController,
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(
                        "Forgot password?",
                        style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        disabledBackgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Text(
                        "LOGIN",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "OR",
                    style: TextStyle(
                      color: Colors.black38,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 30),

                  GoogleLoginButton(
                    onTap: _isLoading ? () {} : _handleGoogleLogin,
                  ),

                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account?",
                        style: TextStyle(color: Colors.black54),
                      ),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                              const RegisterScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Sign up now",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FabricPainter extends CustomPainter {
  final double animationValue;

  FabricPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = Colors.black.withOpacity(0.04)
      ..style = PaintingStyle.fill;

    final paint2 = Paint()
      ..color = Colors.black.withOpacity(0.06)
      ..style = PaintingStyle.fill;

    final paint3 = Paint()
      ..color = Colors.black.withOpacity(0.03)
      ..style = PaintingStyle.fill;

    final paint4 = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    final paint5 = Paint()
      ..color = Colors.black.withOpacity(0.02)
      ..style = PaintingStyle.fill;

    final path1 = Path();
    path1.moveTo(0, size.height * 0.1);
    path1.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.2 + math.sin(animationValue * 2 * math.pi) * 60,
      size.width,
      size.height * 0.05,
    );
    path1.lineTo(size.width, 0);
    path1.lineTo(0, 0);
    path1.close();

    final path2 = Path();
    path2.moveTo(0, size.height * 0.8);
    path2.quadraticBezierTo(
      size.width * 0.4,
      size.height * 0.7 + math.cos(animationValue * 2 * math.pi) * 80,
      size.width * 0.8,
      size.height * 0.9,
    );
    path2.quadraticBezierTo(
      size.width * 0.95,
      size.height * 0.95 + math.sin(animationValue * math.pi) * 30,
      size.width,
      size.height * 0.8,
    );
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();

    final path3 = Path();
    path3.moveTo(size.width * 0.2, 0);
    path3.quadraticBezierTo(
      size.width * 0.6 + math.sin(animationValue * 2 * math.pi + math.pi) * 80,
      size.height * 0.5,
      size.width,
      size.height * 0.4,
    );
    path3.lineTo(size.width, 0);
    path3.close();

    final path4 = Path();
    path4.moveTo(0, size.height * 0.4);
    path4.quadraticBezierTo(
      size.width * 0.3 + math.cos(animationValue * 2 * math.pi) * 50,
      size.height * 0.5 + math.sin(animationValue * 2 * math.pi) * 50,
      0,
      size.height * 0.7,
    );
    path4.close();

    final path5 = Path();
    path5.moveTo(size.width, size.height * 0.3);
    path5.quadraticBezierTo(
      size.width * 0.7 + math.sin(animationValue * 2 * math.pi) * 70,
      size.height * 0.6 + math.cos(animationValue * 2 * math.pi) * 40,
      size.width,
      size.height * 0.7,
    );
    path5.close();

    canvas.drawPath(path1, paint1);
    canvas.drawPath(path2, paint2);
    canvas.drawPath(path3, paint3);
    canvas.drawPath(path4, paint4);
    canvas.drawPath(path5, paint5);
  }

  @override
  bool shouldRepaint(covariant FabricPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}