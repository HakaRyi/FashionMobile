import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/notification_action_type.dart';
import '../utils/notification_navigation.dart';

class RealNotificationItem extends StatelessWidget {
  final Map<String, dynamic> item;

  const RealNotificationItem({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final title = _readValue('title') ?? 'Notification';
    final content = _readValue('content') ?? '';
    final type = _readValue('type') ?? '';
    final status = _readValue('status') ?? '';
    final createdAt = _readValue('createdAt') ?? 'Just now';

    final isUnread = status.toLowerCase() == 'unread';

    return GestureDetector(
      onTap: () {
        NotificationNavigation.open(item);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUnread
              ? AppColors.surface.withOpacity(0.95)
              : AppColors.surface.withOpacity(0.65),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnread
                ? Colors.pinkAccent.withOpacity(0.45)
                : Colors.white.withOpacity(0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThumbnail(type),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight:
                            isUnread ? FontWeight.bold : FontWeight.w600,
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.pinkAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    createdAt,
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(String type) {
    if (NotificationActionType.isOrderType(type)) {
      if (type == NotificationActionType.refundRequested ||
          type == NotificationActionType.refundApproved ||
          type == NotificationActionType.refundRejected) {
        return _iconBox(
          icon: Icons.assignment_return,
          color: Colors.orangeAccent,
        );
      }

      if (type == NotificationActionType.orderCancelled) {
        return _iconBox(
          icon: Icons.cancel_outlined,
          color: Colors.redAccent,
        );
      }

      if (type == NotificationActionType.orderCompleted) {
        return _iconBox(
          icon: Icons.check_circle_outline,
          color: Colors.greenAccent,
        );
      }

      if (type == NotificationActionType.orderDelivered) {
        return _iconBox(
          icon: Icons.local_shipping_outlined,
          color: Colors.lightBlueAccent,
        );
      }

      return _iconBox(
        icon: Icons.shopping_bag_outlined,
        color: Colors.pinkAccent,
      );
    }

    if (type == 'PostStatusUpdate') {
      return _iconBox(
        icon: Icons.verified,
        color: Colors.blueAccent,
      );
    }

    if (type == 'ModelProcessed') {
      return _iconBox(
        icon: Icons.checkroom_outlined,
        color: Colors.tealAccent,
      );
    }

    return _iconBox(
      icon: Icons.notifications,
      color: Colors.purpleAccent,
    );
  }

  Widget _iconBox({
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.5),
        ),
      ),
      child: Icon(
        icon,
        color: color,
        size: 28,
      ),
    );
  }

  String? _readValue(String key) {
    final lowerCamel = item[key];
    final upperCamel = item[_capitalizeFirst(key)];

    final value = lowerCamel ?? upperCamel;

    if (value == null) {
      return null;
    }

    final text = value.toString();

    if (text.trim().isEmpty) {
      return null;
    }

    return text;
  }

  String _capitalizeFirst(String value) {
    if (value.isEmpty) {
      return value;
    }

    return value[0].toUpperCase() + value.substring(1);
  }
}