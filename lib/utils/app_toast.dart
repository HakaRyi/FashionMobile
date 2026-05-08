import 'dart:async';

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppToast {
  static OverlayEntry? _currentEntry;
  static Timer? _timer;

  static void show(
      BuildContext context,
      String message, {
        bool isError = false,
        Duration duration = const Duration(milliseconds: 3500),
      }) {
    _showOverlay(
      context,
      message: message,
      isError: isError,
      duration: duration,
    );
  }

  static void showSuccess(
      BuildContext context,
      String message, {
        Duration duration = const Duration(milliseconds: 3500),
      }) {
    show(
      context,
      message,
      isError: false,
      duration: duration,
    );
  }

  static void showError(
      BuildContext context,
      String message, {
        Duration duration = const Duration(milliseconds: 4000),
      }) {
    show(
      context,
      message,
      isError: true,
      duration: duration,
    );
  }

  static void _showOverlay(
      BuildContext context, {
        required String message,
        required bool isError,
        required Duration duration,
      }) {
    final overlay = Overlay.maybeOf(context);

    if (overlay == null) {
      return;
    }

    _removeCurrentToast();

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return _ToastWidget(
          message: message,
          isError: isError,
          duration: duration,
          onDismissed: () {
            if (_currentEntry == overlayEntry) {
              _currentEntry = null;
            }

            overlayEntry.remove();
          },
        );
      },
    );

    _currentEntry = overlayEntry;
    overlay.insert(overlayEntry);
  }

  static void _removeCurrentToast() {
    _timer?.cancel();
    _timer = null;

    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final Duration duration;
  final VoidCallback onDismissed;

  const _ToastWidget({
    required this.message,
    required this.isError,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;
  late final Animation<Offset> _offsetAnimation;

  Timer? _dismissTimer;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 220),
    );

    _opacityAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();

    _dismissTimer = Timer(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (_isDismissed || !mounted) {
      return;
    }

    _isDismissed = true;

    await _controller.reverse();

    if (mounted) {
      widget.onDismissed();
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isError
        ? Colors.redAccent.withOpacity(0.55)
        : AppColors.textPink.withOpacity(0.55);

    final iconColor =
    widget.isError ? Colors.redAccent : AppColors.textPink;

    final icon =
    widget.isError ? Icons.error_outline : Icons.check_circle_outline;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          bottom: false,
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: SlideTransition(
              position: _offsetAnimation,
              child: Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: _dismiss,
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: 430,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: borderColor,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          icon,
                          color: iconColor,
                          size: 21,
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            widget.message,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 13,
                              height: 1.35,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          Icons.close_rounded,
                          color: Colors.black.withOpacity(0.35),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}