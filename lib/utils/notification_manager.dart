import 'package:flutter/material.dart';
import '../services/notification_service.dart';

final NotificationManager notificationManager = NotificationManager();

class NotificationManager extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  List<Map<String, dynamic>> notifications = [];
  bool isLoading = false;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _service.onNotificationReceived = _onNewNotification;
    await _service.initNotificationService();
    _isInitialized = true;
  }

  void _onNewNotification(Map<String, dynamic> data) {
    debugPrint("SignalR Data: $data");
    notifications.insert(0, data);
    notifyListeners();
  }

  Future<void> fetchNotificationHistory() async {
    isLoading = true;
    notifyListeners();

    try {
      notifications = await _service.getMyNotifications();
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _service.disconnect();
    super.dispose();
  }
}