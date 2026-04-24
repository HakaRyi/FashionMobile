
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/notification_type.dart';
import '../utils/app_notification.dart';
import '../widgets/custom_text_field.dart';
import '../services/auth_service.dart';

class VerifyScreen extends StatefulWidget {
  final String email;

  const VerifyScreen({super.key, required this.email});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _codeController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  late AnimationController _fabricController;

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
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    String code = _codeController.text.trim();

    if (code.isEmpty) {
      NotificationService.show(
        context,
        title: "Notice",
        message: "Please enter the verification code",
        type: NotificationType.warning,
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.verifyAccount(widget.email, code);

    if (mounted) {
      setState(() => _isLoading = false);

      if (result['success']) {
        NotificationService.show(
          context,
          title: "Success",
          message: "Account verified successfully, please login",
          type: NotificationType.success,
        );

        Navigator.pop(context);
      } else {
        NotificationService.show(
          context,
          title: "Error",
          message: result['message'],
          type: NotificationType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    "VERIFY EMAIL",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Verification code has been sent to:\n${widget.email}",
                    style: const TextStyle(color: Colors.black54, height: 1.5, fontSize: 14),
                  ),
                  const SizedBox(height: 40),

                  CustomTextField(
                    hintText: "Enter 6-digit code",
                    icon: Icons.security,
                    controller: _codeController,
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
                      onPressed: _isLoading ? null : _handleVerify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("VERIFY", style: TextStyle(color: Colors.white, fontSize: 15, letterSpacing: 2, fontWeight: FontWeight.bold)),
                    ),
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
    final paint1 = Paint()..color = Colors.black.withOpacity(0.04)..style = PaintingStyle.fill;
    final paint2 = Paint()..color = Colors.black.withOpacity(0.06)..style = PaintingStyle.fill;
    final paint3 = Paint()..color = Colors.black.withOpacity(0.03)..style = PaintingStyle.fill;
    final paint4 = Paint()..color = Colors.black.withOpacity(0.05)..style = PaintingStyle.fill;
    final paint5 = Paint()..color = Colors.black.withOpacity(0.02)..style = PaintingStyle.fill;

    Path path1 = Path();
    path1.moveTo(0, size.height * 0.1);
    path1.quadraticBezierTo(size.width * 0.5, size.height * 0.2 + math.sin(animationValue * 2 * math.pi) * 60, size.width, size.height * 0.05);
    path1.lineTo(size.width, 0);
    path1.lineTo(0, 0);
    path1.close();

    Path path2 = Path();
    path2.moveTo(0, size.height * 0.8);
    path2.quadraticBezierTo(size.width * 0.4, size.height * 0.7 + math.cos(animationValue * 2 * math.pi) * 80, size.width * 0.8, size.height * 0.9);
    path2.quadraticBezierTo(size.width * 0.95, size.height * 0.95 + math.sin(animationValue * math.pi) * 30, size.width, size.height * 0.8);
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();

    Path path3 = Path();
    path3.moveTo(size.width * 0.2, 0);
    path3.quadraticBezierTo(size.width * 0.6 + math.sin(animationValue * 2 * math.pi + math.pi) * 80, size.height * 0.5, size.width, size.height * 0.4);
    path3.lineTo(size.width, 0);
    path3.close();

    Path path4 = Path();
    path4.moveTo(0, size.height * 0.4);
    path4.quadraticBezierTo(size.width * 0.3 + math.cos(animationValue * 2 * math.pi) * 50, size.height * 0.5 + math.sin(animationValue * 2 * math.pi) * 50, 0, size.height * 0.7);
    path4.close();

    Path path5 = Path();
    path5.moveTo(size.width, size.height * 0.3);
    path5.quadraticBezierTo(size.width * 0.7 + math.sin(animationValue * 2 * math.pi) * 70, size.height * 0.6 + math.cos(animationValue * 2 * math.pi) * 40, size.width, size.height * 0.7);
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