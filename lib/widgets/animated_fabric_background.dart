// lib/widgets/animated_fabric_background.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedFabricBackground extends StatefulWidget {
  // Biến child này sẽ chứa nội dung của các trang khác truyền vào
  final Widget child;

  const AnimatedFabricBackground({super.key, required this.child});

  @override
  State<AnimatedFabricBackground> createState() => _AnimatedFabricBackgroundState();
}

class _AnimatedFabricBackgroundState extends State<AnimatedFabricBackground> with SingleTickerProviderStateMixin {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // LỚP 1: Vẽ nền động lượn sóng
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
        // LỚP 2: Nội dung chính của trang nằm đè lên trên
        widget.child,
      ],
    );
  }
}

// Lớp vẽ vẽ sóng đem luôn vào file này để giấu đi cho gọn
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