import 'package:flutter/material.dart';

import '../constants/notification_action_type.dart';
import '../main.dart';
import '../screens/order_detail_screen.dart';

class NotificationNavigation {
  static void open(Map<String, dynamic> data) {
    final type = data['type']?.toString();
    final relatedId = _readInt(data['relatedId']) ??
        _readInt(data['RelatedId']) ??
        _readInt(data['notificationId']) ??
        _readInt(data['NotificationId']);

    if (NotificationActionType.isOrderType(type)) {
      if (relatedId == null) {
        debugPrint('Notification relatedId is missing: $data');
        return;
      }

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(
            orderId: relatedId,
            isPurchase: true,
          ),
        ),
      );
      return;
    }

    debugPrint('Unhandled notification type: $type');
  }

  static int? _readInt(dynamic value) {
    if (value == null) return null;

    if (value is int) return value;

    return int.tryParse(value.toString());
  }
}