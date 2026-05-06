import 'package:flutter/material.dart';

import '../constants/notification_action_type.dart';
import '../utils/notification_manager.dart';
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
    final senderAvatar = _readValue('senderAvatar');
    final createdAt = _readValue('createdAt');

    final isUnread = status.toLowerCase() == 'unread';
    final accentColor = _resolveAccentColor(type);

    return Material(
      color: isUnread ? const Color(0xFFF3F7FF) : Colors.white,
      child: InkWell(
        onTap: () async {
          await notificationManager.markAsRead(item);
          NotificationNavigation.open(item);
        },
        splashColor: Colors.black.withOpacity(0.04),
        highlightColor: Colors.black.withOpacity(0.025),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLeadingAvatar(
                type: type,
                senderAvatar: senderAvatar,
                accentColor: accentColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildContent(
                  title: title,
                  content: content,
                  createdAt: createdAt,
                  isUnread: isUnread,
                ),
              ),
              const SizedBox(width: 8),
              _buildTrailing(isUnread),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingAvatar({
    required String type,
    required String? senderAvatar,
    required Color accentColor,
  }) {
    final hasAvatar = senderAvatar != null && senderAvatar.trim().isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF2F2F2),
            border: Border.all(
              color: const Color(0xFFE5E5E5),
              width: 1,
            ),
          ),
          child: ClipOval(
            child: hasAvatar
                ? Image.network(
              senderAvatar,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildFallbackIcon(type, accentColor);
              },
            )
                : _buildFallbackIcon(type, accentColor),
          ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            child: Icon(
              _resolveSmallIcon(type),
              color: Colors.white,
              size: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackIcon(String type, Color accentColor) {
    return Container(
      color: accentColor.withOpacity(0.12),
      child: Icon(
        _resolveMainIcon(type),
        color: accentColor,
        size: 27,
      ),
    );
  }

  Widget _buildContent({
    required String title,
    required String content,
    required String? createdAt,
    required bool isUnread,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.black,
            fontSize: 15.2,
            height: 1.28,
            fontWeight: isUnread ? FontWeight.w800 : FontWeight.w700,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (content.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            content,
            style: const TextStyle(
              color: Color(0xFF333333),
              fontSize: 13.4,
              height: 1.35,
              fontWeight: FontWeight.w400,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 6),
        Text(
          _formatNotificationTime(createdAt),
          style: TextStyle(
            color: isUnread ? const Color(0xFF1877F2) : const Color(0xFF777777),
            fontSize: 12.2,
            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTrailing(bool isUnread) {
    if (!isUnread) {
      return const SizedBox(width: 10);
    }

    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.only(top: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF1877F2),
        shape: BoxShape.circle,
      ),
    );
  }

  IconData _resolveMainIcon(String type) {
    if (NotificationActionType.isOrderType(type)) {
      if (type == NotificationActionType.refundRequested ||
          type == NotificationActionType.refundApproved ||
          type == NotificationActionType.refundRejected) {
        return Icons.assignment_return_outlined;
      }

      if (type == NotificationActionType.orderCancelled) {
        return Icons.cancel_outlined;
      }

      if (type == NotificationActionType.orderCompleted) {
        return Icons.check_circle_outline_rounded;
      }

      if (type == NotificationActionType.orderDelivered) {
        return Icons.local_shipping_outlined;
      }

      return Icons.shopping_bag_outlined;
    }

    if (type == 'PostStatusUpdate') {
      return Icons.verified_outlined;
    }

    if (type == 'ModelProcessed') {
      return Icons.checkroom_outlined;
    }

    return Icons.notifications_none_rounded;
  }

  IconData _resolveSmallIcon(String type) {
    if (NotificationActionType.isOrderType(type)) {
      if (type == NotificationActionType.refundRequested ||
          type == NotificationActionType.refundApproved ||
          type == NotificationActionType.refundRejected) {
        return Icons.keyboard_return_rounded;
      }

      if (type == NotificationActionType.orderCancelled) {
        return Icons.close_rounded;
      }

      if (type == NotificationActionType.orderCompleted) {
        return Icons.check_rounded;
      }

      if (type == NotificationActionType.orderDelivered) {
        return Icons.local_shipping_rounded;
      }

      return Icons.shopping_bag_rounded;
    }

    if (type == 'PostStatusUpdate') {
      return Icons.check_rounded;
    }

    if (type == 'ModelProcessed') {
      return Icons.auto_awesome_rounded;
    }

    return Icons.notifications_rounded;
  }

  Color _resolveAccentColor(String type) {
    if (NotificationActionType.isOrderType(type)) {
      if (type == NotificationActionType.refundRequested ||
          type == NotificationActionType.refundApproved ||
          type == NotificationActionType.refundRejected) {
        return const Color(0xFFF59E0B);
      }

      if (type == NotificationActionType.orderCancelled) {
        return const Color(0xFFEF4444);
      }

      if (type == NotificationActionType.orderCompleted) {
        return const Color(0xFF22C55E);
      }

      if (type == NotificationActionType.orderDelivered) {
        return const Color(0xFF3B82F6);
      }

      return const Color(0xFF8B5CF6);
    }

    if (type == 'PostStatusUpdate') {
      return const Color(0xFF1877F2);
    }

    if (type == 'ModelProcessed') {
      return const Color(0xFF14B8A6);
    }

    return const Color(0xFF6B7280);
  }

  String _formatNotificationTime(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Just now';
    }

    final parsed = DateTime.tryParse(value);

    if (parsed == null) {
      return value;
    }

    final vietnamTime = parsed.toUtc().add(const Duration(hours: 7));
    final now = DateTime.now();
    final difference = now.difference(vietnamTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    final day = vietnamTime.day.toString().padLeft(2, '0');
    final month = vietnamTime.month.toString().padLeft(2, '0');
    final year = vietnamTime.year.toString();
    final hour = vietnamTime.hour.toString().padLeft(2, '0');
    final minute = vietnamTime.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
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