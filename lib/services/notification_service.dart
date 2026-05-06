import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../constants/api_constants.dart';
import '../main.dart';
import '../screens/chat_screen.dart';
import '../utils/global_event_bus.dart';
import '../utils/notification_navigation.dart';
import 'api_client.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  static const String _defaultChannelId = 'fashion_mobile_channel_sound_v2';
  static const String _defaultChannelName = 'App notifications';

  static const String _chatChannelId = 'chat_messages_channel_sound_v2';
  static const String _chatChannelName = 'Chat messages';

  static const String _androidSoundName = 'notification_sound';

  HubConnection? _hubConnection;

  static BuildContext? globalContext;

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Function(Map<String, dynamic>)? onNotificationReceived;

  Future<void> initNotificationService() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
    );

    await _connectSignalR();
  }

  void _handleLocalNotificationTap(NotificationResponse response) {
    if (response.payload == null || response.payload!.trim().isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(response.payload!);

      if (decoded is! Map) {
        return;
      }

      final payload = Map<String, dynamic>.from(decoded);

      if (payload['kind'] == 'chat') {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              groupId: payload['groupId'],
              userName: payload['senderName'] ?? 'Chat',
              avatarUrl: payload['senderAvatar'] ?? '',
            ),
          ),
        );
        return;
      }

      markPayloadAsRead(payload);
      NotificationNavigation.open(payload);
    } catch (e) {
      debugPrint('Cannot open notification payload: $e');
    }
  }

  Future<void> _connectSignalR() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    if (token.isEmpty) {
      return;
    }

    if (_hubConnection?.state == HubConnectionState.Connected ||
        _hubConnection?.state == HubConnectionState.Connecting) {
      return;
    }

    final url = '${ApiConstants.baseSignalRUrl}/notificationHub';

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

    _hubConnection?.onclose(({error}) {
      debugPrint('Notification SignalR closed: $error');
    });

    _hubConnection?.onreconnecting(({error}) {
      debugPrint('Notification SignalR reconnecting: $error');
    });

    _hubConnection?.onreconnected(({connectionId}) {
      debugPrint('Notification SignalR reconnected: $connectionId');
    });

    _hubConnection?.on('ReceiveNotification', _handleIncomingNotification);
    _hubConnection?.on('ModelProcessed', _handleModelProcessed);

    try {
      await _hubConnection?.start();
      debugPrint('Notification SignalR connected successfully.');
    } catch (e) {
      debugPrint('Notification SignalR connection error: $e');
    }
  }

  void _handleModelProcessed(List<dynamic>? parameters) {
    if (parameters == null || parameters.isEmpty) {
      return;
    }

    try {
      final rawData = parameters.first;

      if (rawData is! Map) {
        return;
      }

      final data = Map<String, dynamic>.from(rawData);

      final modelId = _readInt(data['modelId']);
      final status = data['status']?.toString() ?? '';

      if (modelId == null || status.isEmpty) {
        return;
      }

      GlobalEventBus().fireModelProcessed(modelId, status);

      final title = 'Model review result';
      final body = status == 'Active'
          ? 'Your model has been approved successfully.'
          : 'Your model has been rejected.';

      final payload = {
        'type': 'ModelProcessed',
        'title': title,
        'content': body,
        'relatedId': modelId,
        'status': 'Unread',
      };

      _showLocalNotification(
        title,
        body,
        payload: jsonEncode(payload),
      );

      _showInAppNotificationPopup(payload);
    } catch (e) {
      debugPrint('Cannot handle ModelProcessed event: $e');
    }
  }

  void _handleIncomingNotification(List<dynamic>? parameters) {
    if (parameters == null || parameters.isEmpty) {
      return;
    }

    try {
      final rawData = parameters.first;

      if (rawData is! Map) {
        return;
      }

      final notificationData = Map<String, dynamic>.from(rawData);
      final normalizedData = _normalizeNotificationMap(notificationData);

      final title = _readString(normalizedData['title']) ?? 'New notification';
      final content = _readString(normalizedData['content']) ?? '';

      _showLocalNotification(
        title,
        content,
        payload: jsonEncode(normalizedData),
      );

      _showInAppNotificationPopup(normalizedData);

      onNotificationReceived?.call(normalizedData);
    } catch (e) {
      debugPrint('Cannot handle SignalR notification: $e');
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

  void _showInAppNotificationPopup(Map<String, dynamic> data) {
    final context = navigatorKey.currentContext;

    if (context == null) {
      return;
    }

    final overlay = Overlay.maybeOf(context);

    if (overlay == null) {
      return;
    }

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () async {
                if (entry.mounted) {
                  entry.remove();
                }

                await markPayloadAsRead(data);

                NotificationNavigation.open(data);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFE5E5E5),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.14),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1877F2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_rounded,
                        color: Colors.white,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['title']?.toString() ?? 'New notification',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              height: 1.25,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data['content']?.toString() ?? '',
                            style: const TextStyle(
                              color: Color(0xFF333333),
                              fontSize: 13,
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        if (entry.mounted) {
                          entry.remove();
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          color: Color(0xFF666666),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(entry);

    Future.delayed(const Duration(seconds: 5), () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }

  Future<void> _showLocalNotification(
      String title,
      String body, {
        String channelId = _defaultChannelId,
        String channelName = _defaultChannelName,
        String? payload,
      }) async {
    final AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Notifications from WAPO app',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      enableVibration: true,
      sound: const RawResourceAndroidNotificationSound(_androidSoundName),
      styleInformation: BigTextStyleInformation(body),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final notificationId =
    (title + body + DateTime.now().millisecondsSinceEpoch.toString())
        .hashCode
        .abs();

    await _localNotificationsPlugin.show(
      notificationId,
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
      final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.getMyNotifications}',
      );

      final response = await ApiClient.get(url);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map(
                (item) => _normalizeNotificationMap(
              Map<String, dynamic>.from(item),
            ),
          )
              .toList();
        }

        if (decoded is Map) {
          final map = Map<String, dynamic>.from(decoded);

          final items =
              map['items'] ?? map['Items'] ?? map['data'] ?? map['Data'];

          if (items is List) {
            return items
                .whereType<Map>()
                .map(
                  (item) => _normalizeNotificationMap(
                Map<String, dynamic>.from(item),
              ),
            )
                .toList();
          }
        }
      }

      return [];
    } catch (e) {
      debugPrint('Cannot fetch notification history: $e');
      return [];
    }
  }

  Future<bool> markAsRead(int notificationId) async {
    try {
      final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.markNotificationAsRead(notificationId)}',
      );

      final response = await ApiClient.put(url);

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Cannot mark notification as read: $e');
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.markAllNotificationsAsRead}',
      );

      final response = await ApiClient.put(url);

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Cannot mark all notifications as read: $e');
      return false;
    }
  }

  Future<void> markPayloadAsRead(Map<String, dynamic> payload) async {
    final notificationId = _readInt(
      payload['id'] ??
          payload['Id'] ??
          payload['notificationId'] ??
          payload['NotificationId'],
    );

    if (notificationId == null) {
      return;
    }

    await markAsRead(notificationId);

    payload['status'] = 'Read';
    payload['Status'] = 'Read';
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

    final storedUserId =
        prefs.getString('userId') ?? prefs.getInt('userId')?.toString() ?? '';

    if (senderId.toString() == storedUserId) {
      return;
    }

    String displayContent = content;

    if (content.trim().isEmpty && photos.isNotEmpty) {
      displayContent = 'Sent ${photos.length} attachment(s)';
    }

    String title = senderName;
    String body = displayContent;

    if (isGroup) {
      title = groupName ?? 'Group chat';
      body = '$senderName: $displayContent';
    }

    final payload = jsonEncode({
      'kind': 'chat',
      'groupId': groupId,
      'senderName': isGroup ? (groupName ?? 'Group') : senderName,
      'senderAvatar': senderAvatar,
    });

    await _showLocalNotification(
      title,
      body,
      channelId: _chatChannelId,
      channelName: _chatChannelName,
      payload: payload,
    );
  }

  Future<void> showManualLocalNotification({
    required String title,
    required String body,
    String channelId = _defaultChannelId,
    String channelName = _defaultChannelName,
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
    _hubConnection = null;
  }

  int? _readInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString());
  }

  String? _readString(dynamic value, {String? fallback}) {
    if (value == null) {
      return fallback;
    }

    final text = value.toString();

    if (text.trim().isEmpty) {
      return fallback;
    }

    return text;
  }
}