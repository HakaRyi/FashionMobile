import 'package:flutter/material.dart';

class SlideRoute extends PageRouteBuilder {
  final Widget page;
  SlideRoute({required this.page})
      : super(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    // 1. Giảm thời gian chuyển cảnh (300-350ms là chuẩn cho app hiện đại)
    transitionDuration: const Duration(milliseconds: 350),
    // Thời gian khi vuốt quay lại
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // 2. Sử dụng đường cong Curves.fastOutSlowIn hoặc fastLinearToSlowEaseIn
      // để tạo cảm giác lướt đi nhanh lúc đầu và dừng lại mượt mà ở cuối.
      var curveAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.fastOutSlowIn,
        reverseCurve: Curves.fastOutSlowIn.flipped,
      );

      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0), // Trượt từ phải sang trái
          end: Offset.zero,
        ).animate(curveAnimation),
        child: child,
      );
    },
  );
}