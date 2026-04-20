import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../constants/api_constants.dart';
import 'package:http_parser/http_parser.dart';

import 'notification_service.dart';
class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();
  HubConnection? _hubConnection;
  static int? currentGroupId;
  // Lấy token từ SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  String _buildNotificationPreview(Map<String, dynamic> msg) {
    final content = (msg['content'] ?? msg['Content'] ?? '').toString().trim();

    final photosRaw = msg['photos'] ?? msg['Photos'] ?? [];
    final List photos = photosRaw is List ? photosRaw : [];

    final sharedPostId = msg['sharedPostId'] ??
        msg['SharedPostId'] ??
        msg['postId'] ??
        msg['PostId'];

    if (content.isNotEmpty) return content;
    if (photos.isNotEmpty) return 'Đã gửi ảnh';
    if (sharedPostId != null) return 'Đã chia sẻ một bài viết';

    return 'Tin nhắn mới';
  }

  // Khởi tạo kết nối SignalR
  Future<void> initSignalR({
    required Function(dynamic message) onMessageReceived,
    required Function(int messageId) onMessageRecalled,
    required Function(int messageId, String type) onReactionAdded,
  }) async {
    final token = await _getToken();
    if (token == null) return;

    _hubConnection = HubConnectionBuilder()
        .withUrl(ApiConstants.signalRHubUrl,
        options: HttpConnectionOptions(
          accessTokenFactory: () async => token,
        ))
        .withAutomaticReconnect()
        .build();

    // Lắng nghe các sự kiện từ Back-end
  //  _hubConnection!.on("ReceiveMessage", (arguments) => onMessageReceived(arguments![0]));
    _hubConnection!.on("MessageRecalled", (arguments) => onMessageRecalled(arguments![0] as int));
    _hubConnection!.on("NewGroupCreated", (arguments) async {
      if (arguments != null && arguments.isNotEmpty) {
        int newGroupId = arguments[0] as int;
        print("DEBUG: Nhận được lệnh Join Group mới: $newGroupId");
        await _hubConnection!.invoke("JoinGroup", args: [newGroupId]);
      }
    });
    _hubConnection!.on("ReactionUpdated", (arguments) {
      onReactionAdded(arguments![0] as int, arguments![1] as String);
    });
    _hubConnection!.on("ReceiveReaction", (arguments) {
      onReactionAdded(arguments![0] as int, arguments![2].toString());
    });

    _hubConnection!.on("ReceiveMessage", (arguments) async {
      if (arguments != null && arguments.isNotEmpty) {
        final Map<String, dynamic> msg = arguments[0] as Map<String, dynamic>;

        final prefs = await SharedPreferences.getInstance();
        final myId = prefs.getString('userId') ?? "";

        final int incomingGroupId = msg['groupId'] ?? msg['GroupId'] ?? 0;

        if (msg['senderId'].toString() != myId && incomingGroupId != ChatService.currentGroupId) {
          NotificationService().showChatNotification(
            groupId: incomingGroupId,
            senderId: msg['senderId'] ?? 0,
            senderName: msg['senderName'] ?? "Người dùng",
            senderAvatar: msg['senderAvatar'],
            content: _buildNotificationPreview(msg),
            photos: List<String>.from(msg['photos'] ?? []),
            isGroup: msg['groupName'] != "Private Chat",
            groupName: msg['groupName']?? msg['GroupName'],
          );
        }

        onMessageReceived(msg);
      }
    });
    await _hubConnection!.start();
  }
  Future<void> joinGroupManual(int groupId) async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      await _hubConnection!.invoke("JoinGroup", args: [groupId]);
      print("DEBUG: Chủ động Join vào Group mới: $groupId");
    }
  }
  Future<bool> createGroup({
    required String name,
    required List<int> memberIds,
    String? avatarPath,
  }) async {
    final token = await _getToken();
    var request = http.MultipartRequest('POST', Uri.parse("${ApiConstants.baseUrl}${ApiConstants.groupEndpoint}/create-group"));
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['Name'] = name;

    for (int i = 0; i < memberIds.length; i++) {
      request.fields['MemberIds[$i]'] = memberIds[i].toString();
    }
    if (avatarPath != null) {
      request.files.add(await http.MultipartFile.fromPath('Avatar', avatarPath));
    }

    var response = await request.send();
    return response.statusCode == 200;
  }
  // --- API CALLS ---
  Future<List<dynamic>> getMyGroups() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse("${ApiConstants.baseUrl}${ApiConstants.groupEndpoint}/get-my-groups"),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200 ? jsonDecode(response.body) : [];
  }

  Future<List<dynamic>> getChatHistory(int groupId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse("${ApiConstants.baseUrl}${ApiConstants.chatEndpoint}/chat-history/$groupId"),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200 ? jsonDecode(response.body) : [];
  }

  // Gửi tin nhắn (Qua API vì có chứa File ảnh)
  Future<void> sendMessage(int groupId, String content, {List<String>? photoPaths}) async {
    final token = await _getToken();
    var request = http.MultipartRequest('POST', Uri.parse("${ApiConstants.baseUrl}${ApiConstants.chatEndpoint}/send/$groupId"));
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['content'] = content;
    if (photoPaths != null && photoPaths.isNotEmpty) {
      for (var path in photoPaths) {
        String extension = path.split('.').last.toLowerCase();

        request.files.add(await http.MultipartFile.fromPath(
          'photo',
          path,
          contentType: MediaType('image', extension == 'jpg' ? 'jpeg' : extension),
        ));
      }
    }
    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("Status Code SendMessage: ${response.statusCode}");
      if (response.statusCode != 200 && response.statusCode != 201) {
        print("Lỗi server trả về: ${response.body}");
      }
    } catch (e) {
      print("Lỗi kết nối khi gửi tin nhắn: $e");
    }
  }

  // Thu hồi tin nhắn
  Future<void> recallMessage(int messageId) async {
    final token = await _getToken();
    await http.put(
      Uri.parse("${ApiConstants.baseUrl}${ApiConstants.chatEndpoint}/recall-msg/$messageId"),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  // Thêm vào class ChatService
  Future<void> sendReaction(int messageId, String type) async {
    final token = await _getToken();
    // Gọi đúng endpoint: /add-message-reaction/{messageId}?type=haha
    final url = Uri.parse("${ApiConstants.baseUrl}${ApiConstants.chatEndpoint}/add-message-reaction/$messageId?type=$type");

    await http.post(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
  }
  Future<int?> createOrGet1v1Room(int targetUserId) async {
    final token = await _getToken();
    final url = Uri.parse("${ApiConstants.baseUrl}${ApiConstants.groupEndpoint}/create-1v1-room/$targetUserId");

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'accept': '*/*'
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        //json { "message": "...", "groupId": ... }
        return data['groupId'] as int?;
      }
    } catch (e) {
      print("Lỗi createOrGet1v1Room: $e");
    }
    return null;
  }
  Future<List<dynamic>> getUsersInGroup(int groupId) async {
    final token = await _getToken();
    try {
      final response = await http.get(
        Uri.parse("${ApiConstants.baseUrl}${ApiConstants.groupEndpoint}/get-users-in-group/$groupId"),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Lỗi lấy thành viên nhóm: $e");
    }
    return [];
  }
  Future<bool> addMemberToGroup(int groupId, int targetUserId) async {
    final token = await _getToken();
    final url = Uri.parse("${ApiConstants.baseUrl}${ApiConstants.groupEndpoint}/add-member-to-group/$groupId/$targetUserId");

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'accept': '*/*'
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Lỗi addMemberToGroup: $e");
      return false;
    }
  }
  Future<List<dynamic>> getPhotosInGroup(int groupId) async {
    final token = await _getToken();
    try {
      final response = await http.get(
        Uri.parse("${ApiConstants.baseUrl}${ApiConstants.groupEndpoint}/get-photos-in-group/$groupId"),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Lỗi lấy ảnh trong nhóm: $e");
    }
    return [];
  }
  void stopConnection() {
    //_hubConnection?.stop();
  }
}