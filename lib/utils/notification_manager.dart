import 'package:flutter/material.dart';

import '../services/notification_service.dart';

final NotificationManager notificationManager = NotificationManager();

class NotificationManager extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  List<Map<String, dynamic>> notifications = [];

  bool isLoading = false;
  bool _isInitialized = false;

  int get unreadCount {
    return notifications.where((item) {
      final status = _readValue(item, 'status')?.toLowerCase();
      return status == 'unread';
    }).length;
  }

  bool get hasUnreadNotification => unreadCount > 0;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    _service.onNotificationReceived = _onNewNotification;

    await _service.initNotificationService();

    _isInitialized = true;
  }

  Future<void> fetchNotificationHistory() async {
    isLoading = true;
    notifyListeners();

    try {
      notifications = await _service.getMyNotifications();
    } catch (e) {
      debugPrint('Cannot fetch notifications: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(Map<String, dynamic> item) async {
    final notificationId = _readNotificationId(item);

    if (notificationId == null) {
      return;
    }

    final currentStatus = _readValue(item, 'status')?.toLowerCase();

    if (currentStatus != 'unread') {
      return;
    }

    final success = await _service.markAsRead(notificationId);

    if (!success) {
      return;
    }

    _updateLocalNotificationStatus(notificationId, 'Read');

    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    if (unreadCount == 0) {
      return;
    }

    final success = await _service.markAllAsRead();

    if (!success) {
      return;
    }

    for (final item in notifications) {
      item['status'] = 'Read';
      item['Status'] = 'Read';
    }

    notifyListeners();
  }

  void _onNewNotification(Map<String, dynamic> data) {
    debugPrint('SignalR notification data: $data');

    final normalizedData = _normalizeNotificationMap(data);

    final newId = _readValue(normalizedData, 'id') ??
        _readValue(normalizedData, 'notificationId') ??
        _readValue(normalizedData, 'NotificationId');

    if (newId != null && newId.isNotEmpty) {
      final exists = notifications.any((item) {
        final itemId = _readValue(item, 'id') ??
            _readValue(item, 'notificationId') ??
            _readValue(item, 'NotificationId');

        return itemId == newId;
      });

      if (exists) {
        return;
      }
    }

    normalizedData['status'] =
        _readValue(normalizedData, 'status') ?? 'Unread';
    normalizedData['Status'] = normalizedData['status'];

    notifications.insert(0, normalizedData);

    notifyListeners();
  }

  Future<void> clearLocalNotifications() async {
    await _service.clearAllNotifications();
  }

  void clearInMemory() {
    notifications.clear();
    notifyListeners();
  }

  int? _readNotificationId(Map<String, dynamic> item) {
    final idText = _readValue(item, 'id') ??
        _readValue(item, 'notificationId') ??
        _readValue(item, 'NotificationId');

    if (idText == null || idText.trim().isEmpty) {
      return null;
    }

    return int.tryParse(idText);
  }

  void _updateLocalNotificationStatus(int notificationId, String status) {
    for (final item in notifications) {
      final currentId = _readNotificationId(item);

      if (currentId == notificationId) {
        item['status'] = status;
        item['Status'] = status;
        break;
      }
    }
  }

  Map<String, dynamic> _normalizeNotificationMap(Map<String, dynamic> data) {
    return {
      ...data,
      'id': data['id'] ??
          data['Id'] ??
          data['notificationId'] ??
          data['NotificationId'],
      'title': data['title'] ?? data['Title'],
      'content': data['content'] ?? data['Content'],
      'type': data['type'] ?? data['Type'],
      'status': data['status'] ?? data['Status'],
      'createdAt': data['createdAt'] ?? data['CreatedAt'],
      'relatedId': data['relatedId'] ?? data['RelatedId'],
      'imageUrl': data['imageUrl'] ?? data['ImageUrl'],
      'senderName': data['senderName'] ?? data['SenderName'],
      'senderAvatar': data['senderAvatar'] ?? data['SenderAvatar'],
    };
  }

  String? _readValue(Map<String, dynamic> item, String key) {
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

  @override
  void dispose() {
    _service.disconnect();
    super.dispose();
  }
}