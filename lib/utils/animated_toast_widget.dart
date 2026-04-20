import 'package:fashion_mobile/constants/app_colors.dart';
import 'package:flutter/material.dart';

import '../constants/notification_type.dart';

class AnimatedToastWidget extends StatefulWidget {
  final String title;
  final String message;
  final NotificationType type;
  final VoidCallback onDismissed;

  const AnimatedToastWidget({
    Key? key,
    required this.title,
    required this.message,
    required this.type,
    required this.onDismissed,
  }) : super(key: key);

  @override
  State<AnimatedToastWidget> createState() => _AnimatedToastWidgetState();
}

class _AnimatedToastWidgetState extends State<AnimatedToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Hiệu ứng trượt từ phải sang trái
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    // Bắt đầu chạy hiệu ứng xuất hiện
    _controller.forward();

    // Tự động đóng sau 3 giây
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismissed());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: 300, // Chiều rộng cố định của thông báo
          margin: const EdgeInsets.only(top: 16, right: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background, // Nền tối hợp với app của bạn
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(color: widget.type.color, width: 4), // Vạch màu phân loại
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(widget.type.icon, color: widget.type.color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.message,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  _controller.reverse().then((_) => widget.onDismissed());
                },
                child: const Icon(Icons.close, color: AppColors.textPrimary, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}