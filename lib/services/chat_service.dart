import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../constants/api_constants.dart';
import 'package:http_parser/http_parser.dart';
class ChatService {
  HubConnection? _hubConnection;

  // Lấy token từ SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
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
    _hubConnection!.on("ReceiveMessage", (arguments) => onMessageReceived(arguments![0]));
    _hubConnection!.on("MessageRecalled", (arguments) => onMessageRecalled(arguments![0] as int));
    _hubConnection!.on("ReactionUpdated", (arguments) {
      onReactionAdded(arguments![0] as int, arguments![1] as String);
    });
    _hubConnection!.on("ReceiveReaction", (arguments) {
      onReactionAdded(arguments![0] as int, arguments![2].toString());
    });

    await _hubConnection!.start();
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

  void stopConnection() {
    _hubConnection?.stop();
  }
}