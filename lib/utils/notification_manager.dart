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

  void _onNewNotification(Map<String, dynamic> data) {
    debugPrint('SignalR notification data: $data');

    final newId = _readValue(data, 'id') ??
        _readValue(data, 'notificationId') ??
        _readValue(data, 'NotificationId');

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

    notifications.insert(0, data);
    notifyListeners();
  }

  Future<void> clearLocalNotifications() async {
    await _service.clearAllNotifications();
  }

  void clearInMemory() {
    notifications.clear();
    notifyListeners();
  }

  String? _readValue(Map<String, dynamic> item, String key) {
    final lowerCamel = item[key];
    final upperCamel = item[_capitalizeFirst(key)];

    final value = lowerCamel ?? upperCamel;

    if (value == null) {
      return null;
    }

    return value.toString();
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