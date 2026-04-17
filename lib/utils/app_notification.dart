import 'package:fashion_mobile/constants/app_colors.dart';
import 'package:flutter/material.dart';

import '../constants/notification_type.dart';
import 'animated_toast_widget.dart';

class NotificationService {
  static void show(
      BuildContext context, {
        required String title,
        required String message,
        NotificationType type = NotificationType.info,
      }) {
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        right: 0,
        child: Material(
          color: AppColors.backgroundSecondary,
          child: AnimatedToastWidget(
            title: title,
            message: message,
            type: type,
            onDismissed: () {
              overlayEntry.remove();
            },
          ),
        ),
      ),
    );
    overlayState.insert(overlayEntry);
  }
}