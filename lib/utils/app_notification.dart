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
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          right: 0,
          child: Material(
            color: Colors.transparent,
            child: AnimatedToastWidget(
              title: title,
              message: message,
              type: type,
              onDismissed: () {
                if (overlayEntry.mounted) {
                  overlayEntry.remove();
                }
              },
            ),
          ),
        );
      },
    );

    overlayState.insert(overlayEntry);
  }
}