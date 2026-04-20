import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../main.dart';
import 'api_client.dart';
import '../utils/global_event_bus.dart';
import '../screens/chat_screen.dart';
import '../services/chat_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();
  HubConnection? _hubConnection;
  static BuildContext? globalContext;
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
    await _localNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          final data = jsonDecode(response.payload!);

          // Dùng navigatorKey ĐỂ CHẮC CHẮN LUÔN CHẠY ĐƯỢC
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                groupId: data['groupId'],
                userName: data['senderName'] ?? "Chat",
                avatarUrl: data['senderAvatar'] ?? "",
              ),
            ),
          );
        }
      },
    );

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
        accessTokenFactory: () async {
          final p = await SharedPreferences.getInstance();
          return p.getString('token') ?? '';
        },
      ),
    )
        .withAutomaticReconnect()
        .build();

    _hubConnection?.onclose(({error}) => debugPrint("SignalR Connection Closed"));
    _hubConnection?.on("ReceiveNotification", _handleIncomingNotification);
    _hubConnection?.on("ModelProcessed", _handleModelProcessed);

    try {
      await _hubConnection?.start();
      debugPrint("SignalR Connected Successfully!");
    } catch (e) {
      debugPrint("SignalR Connection Error: $e");
    }
  }

  void _handleModelProcessed(List<dynamic>? parameters) {
    if (parameters == null || parameters.isEmpty) return;
    try {
      final data = parameters.first as Map<String, dynamic>;
      final modelId = data['modelId'] as int;
      final status = data['status'] as String;

      GlobalEventBus().fireModelProcessed(modelId, status);

      _showLocalNotification(
        'Kết quả kiểm duyệt',
        status == 'Active' ? 'Model của bạn đã duyệt thành công!' : 'Model của bạn bị từ chối.',
      );
    } catch (e) {
      debugPrint(e.toString());
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
      debugPrint("Lỗi xử lý SignalR: ${e.toString()}");
    }
  }

  // Future<void> _showLocalNotification(String title, String body) async {
  //   const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
  //     'fashion_mobile_channel',
  //     'Thông báo ứng dụng',
  //     importance: Importance.max,
  //     priority: Priority.high,
  //     showWhen: true,
  //   );
  //
  //   const NotificationDetails platformDetails = NotificationDetails(
  //     android: androidDetails,
  //     iOS: DarwinNotificationDetails(),
  //   );
  //
  //   await _localNotificationsPlugin.show(
  //     DateTime.now().millisecond,
  //     title,
  //     body,
  //     platformDetails,
  //   );
  // }
  Future<void> _showLocalNotification(
      String title,
      String body, {
        String channelId = 'fashion_mobile_channel',
        String channelName = 'Thông báo ứng dụng',
        String? payload,
      }) async {
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      // Nếu là chat thì bật rung và chuông mạnh hơn
      styleInformation: const BigTextStyleInformation(''),
    );

    NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _localNotificationsPlugin.show(
      (title + body).hashCode,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }
  Future<void> clearAllNotifications() async {
    await _localNotificationsPlugin.cancelAll();
  }
  Future<List<Map<String, dynamic>>> getMyNotifications() async {
    try {
      final url = Uri.parse("${ApiConstants.baseUrl}/notifications/me");

      final response = await ApiClient.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint("Lỗi lấy danh sách thông báo: ${e.toString()}");
      return [];
    }
  }
  Future<void> showChatNotification({
    required int groupId,
    required int senderId,
    required String senderName,
    required String? senderAvatar,
    required String content,
    required List<String> photos,
    required bool isGroup,
    String? groupName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final myId = prefs.getString('userId') ?? "";
    if (senderId.toString() == myId) return;

    String displayContent = content;
    if (content.isEmpty && photos.isNotEmpty) {
      displayContent = "Đã gửi ${photos.length} file đính kèm";
    }

    String title = senderName;
    String body = displayContent;

    if (isGroup) {
      title = groupName ?? "Nhóm mới";
      body = "$senderName: $displayContent";
    }
    String payload = jsonEncode({
      "groupId": groupId,
      "senderName": isGroup ? (groupName ?? "Nhóm") : senderName,
      "senderAvatar": senderAvatar,
    });
    // GỌI HÀM VỚI CHANNEL RIÊNG CHO CHAT
    await _showLocalNotification(
      title,
      body,
      channelId: 'chat_messages_channel',
      channelName: 'Tin nhắn chat',
      payload: payload,
    );
  }

  Future<void> showManualLocalNotification({
    required String title,
    required String body,
    String channelId = 'fashion_mobile_channel',
    String channelName = 'Thông báo ứng dụng',
    String? payload,
  }) async {
    await _showLocalNotification(
      title,
      body,
      channelId: channelId,
      channelName: channelName,
      payload: payload,
    );
  }

  void disconnect() {
    _hubConnection?.stop();
  }
}