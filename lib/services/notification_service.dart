import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class NotificationService {
  HubConnection? _hubConnection;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Function(Map<String, dynamic>)? onNotificationReceived;

  Future<void> initNotificationService() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _localNotificationsPlugin.initialize(initSettings);

    await _connectSignalR();
  }

  Future<void> _connectSignalR() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    if (token.isEmpty) return;

    final url = "${ApiConstants.baseSignalRUrl}/notificationHub";

    _hubConnection = HubConnectionBuilder()
        .withUrl(
      url,
      options: HttpConnectionOptions(
        accessTokenFactory: () async => token,
      ),
    )
        .withAutomaticReconnect()
        .build();

    _hubConnection?.onclose(({error}) => debugPrint("SignalR Connection Closed"));
    _hubConnection?.on("ReceiveNotification", _handleIncomingNotification);

    try {
      await _hubConnection?.start();
      debugPrint("SignalR Connected Successfully!");
    } catch (e) {
      debugPrint("SignalR Connection Error: $e");
    }
  }

  void _handleIncomingNotification(List<dynamic>? parameters) {
    if (parameters == null || parameters.isEmpty) return;

    try {
      final notificationData = parameters.first as Map<String, dynamic>;

      final title = notificationData['title'] ?? 'Thông báo mới';
      final content = notificationData['content'] ?? '';

      _showLocalNotification(title, content);

      if (onNotificationReceived != null) {
        onNotificationReceived!(notificationData);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _showLocalNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'fashion_mobile_channel',
      'Thông báo ứng dụng',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _localNotificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      platformDetails,
    );
  }

  Future<List<Map<String, dynamic>>> getMyNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) return [];

      final url = Uri.parse("${ApiConstants.baseUrl}/Notification/my-notifications");
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint(e.toString());
      return [];
    }
  }

  void disconnect() {
    _hubConnection?.stop();
  }
}