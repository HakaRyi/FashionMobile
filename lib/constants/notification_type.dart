import 'package:flutter/material.dart';

enum NotificationType { success, error, warning, info }

extension NotificationTypeExtension on NotificationType {
  Color get color {
    switch (this) {
      case NotificationType.success:
        return Colors.green.shade600;
      case NotificationType.error:
        return Colors.redAccent.shade400;
      case NotificationType.warning:
        return Colors.orange.shade500;
      case NotificationType.info:
        return Colors.blue.shade500;
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationType.success:
        return Icons.check_circle_outline;
      case NotificationType.error:
        return Icons.error_outline;
      case NotificationType.warning:
        return Icons.warning_amber_outlined;
      case NotificationType.info:
        return Icons.info_outline;
    }
  }
}