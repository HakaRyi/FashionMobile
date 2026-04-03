import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input_field.dart';
import '../screens/chat_settings_screen.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final int groupId;
  final String userName;
  final String avatarUrl;
  final bool isOnline; // Thêm vào constructor

  const ChatScreen({
    super.key,
    required this.groupId,
    required this.userName,
    required this.avatarUrl,
    this.isOnline = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  String myId = "";
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyId();
    _loadHistory();
    _initRealtime();
  }
  void _loadMyId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      myId = prefs.getString('userId') ?? "";
    });
  }
  void _initRealtime() {
    _chatService.initSignalR(
      onMessageReceived: (msg) {
        if (mounted){
            setState(() {
              final incomingContent = (msg['content'] ?? msg['Content'] ?? "").toString().trim();
              final incomingPhotos = msg['photos'] ?? msg['Photos'] ?? [];
              _messages.removeWhere((m) {
                bool isTemp = m['messageId'] == -1;
                String localContent = (m['content'] ?? "").toString().trim();
                bool contentMatch = localContent == incomingContent;

                bool photoMatch = true;
                if (m['photos'] != null) {
                  photoMatch = (m['photos'] as List).length == (incomingPhotos as List).length;
                }
                return isTemp && contentMatch && photoMatch;
              });
              final normalizedMsg = {
                ...msg,
                'content': incomingContent,
                'photos': incomingPhotos,
                'senderName': msg['senderName'] ?? msg['SenderName'] ?? "Unknown",
                'sentAt': msg['sentAt'] ?? msg['SentAt'] ?? DateTime.now().toIso8601String(),
              };
            _messages.insert(0, normalizedMsg);
          });
        }
        print("Tin nhắn ảo đang có: ${_messages.where((m) => m['messageId'] == -1).map((m) => m['content'])}");
        print("Tin nhắn SignalR về: ${msg['content']}");
        print("Nội dung nhận được: ${msg['content'] ?? msg['Content']}");
      },
      onMessageRecalled: (id) {
        if (mounted) {
          setState(() {
            final index = _messages.indexWhere((m) => m['messageId'] == id);
            if (index != -1) {
              _messages[index]['content'] = "Tin nhắn đã bị thu hồi";
              _messages[index]['isRecalled'] = true;
            }
          });
        }
      },
      onReactionAdded: (messageId, type) {
        if (mounted) {
          setState(() {
            final index = _messages.indexWhere((m) => m['messageId'] == messageId);
            if (index != -1) {
              // Khởi tạo list nếu null, sau đó gán reaction mới
              _messages[index]['reactions'] = [{'reactionType': type}];
            }
          });
        }
      },
    );
  }

  void _loadHistory() async {
    final history = await _chatService.getChatHistory(widget.groupId);
    if (mounted) {
      setState(() {
        // reversed vì ListView dùng reverse: true
        _messages = history.reversed.toList();
        _isLoading = false;
      });
    }
  }

  void _handleSend(String text, List<String> imagePaths) async {
    print("DEBUG: MyId hiện tại là: '$myId'");
    if (text.trim().isEmpty && imagePaths.isEmpty) return;
    final String currentText = text.trim();
    _controller.clear();
    final String clientMsgId = DateTime.now().millisecondsSinceEpoch.toString();
    final tempMsg = {
      "messageId": -1,
      "clientMsgId": clientMsgId,
      "content": currentText,
      "senderId": myId,
      "senderName": "Me",
      "photos": imagePaths,
      "sentAt": DateTime.now().toIso8601String(),
      "isTemp": true,
    };

    setState(() {
      _messages.insert(0, tempMsg);
    });
    await _chatService.sendMessage(widget.groupId, currentText,photoPaths: imagePaths);
  }

  // Hàm thu hồi tin nhắn khi long press vào bubble
  void _onRecall(int messageId) async {
    await _chatService.recallMessage(messageId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (context) => ChatSettingsScreen(
                  userName: widget.userName,
                  avatarUrl: widget.avatarUrl
              )
          )),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(widget.avatarUrl),
                  ),
                  if (widget.isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 10,
                        width: 10,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.background, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.userName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    Text(
                      widget.isOnline ? "Đang hoạt động" : "Ngoại tuyến",
                      style: TextStyle(
                          color: widget.isOnline ? Colors.greenAccent : Colors.white38,
                          fontSize: 10
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.textPink))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[index];
                final bool isTemp = m['isTemp'] == true;
                final bool isMe = isTemp||m['isOwner'] == true ||
                                  m['senderId']?.toString() == myId.toString();

                final DateTime sentTime = m['sentAt'] != null
                    ? DateTime.parse(m['sentAt'].toString()).toLocal()
                    : DateTime.now();

                return GestureDetector(
                  onLongPress: () => _showExtraMenu(m),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      // Nếu là mình thì đẩy sang phải, người khác thì bên trái
                      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end, // Avatar nằm dưới cùng nếu tin nhắn dài
                      children: [
                        // HIỂN THỊ AVATAR NGƯỜI KHÁC
                        if (!isMe) ...[
                          CircleAvatar(
                            radius: 14, // Kích thước nhỏ xinh
                            backgroundImage: NetworkImage(m['senderAvatarUrl'] ?? "https://i.pravatar.cc/150?img=11"), // Lấy avatar từ widget truyền vào
                          ),
                          const SizedBox(width: 8),
                        ],

                        // NỘI DUNG TIN NHẮN VÀ GIỜ
                        Flexible(
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              ChatBubble(
                                message: m['content'] ?? "",
                                photos: (m['photos'] as List?)?.map((e) => e.toString()).toList(),
                                reactions: m['reactions'],
                                isMe: isMe,
                              ),
                              // Hiển thị giờ
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Text(
                                  "${sentTime.hour}:${sentTime.minute.toString().padLeft(2, '0')}",
                                  style: const TextStyle(color: Colors.white60, fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Khoảng trống bên phải nếu là người khác gửi (để không bị tràn)
                        if (!isMe) const SizedBox(width: 40),
                        // Khoảng trống bên trái nếu là mình gửi
                        if (isMe) const SizedBox(width: 8),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          ChatInputField(controller: _controller, onSend: _handleSend),
        ],
      ),
    );
  }

  void _showExtraMenu(dynamic message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['❤️', '😆', '😲', '😥', '😡'].map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      String type = '';
                      if (emoji == '❤️') type = 'like';
                      if (emoji == '😆') type = 'haha';
                      if (emoji == '😲') type = 'suprise';
                      if (emoji == '😥') type = 'sad';
                      if (emoji == '😡') type = 'mad';

                      _chatService.sendReaction(message['messageId'], type);
                      Navigator.pop(context);
                    },
                    child: Text(emoji, style: const TextStyle(fontSize: 30)),
                  );
                }).toList(),
              ),
          ),
          const Divider(color: Colors.white10),
          ListTile(
            leading: const Icon(Icons.push_pin_outlined, color: Colors.white),
            title: const Text("Ghim tin nhắn", style: TextStyle(color: Colors.white)),
            onTap: () {
              // _chatService.pinMessage(message['messageId'], widget.groupId);
              Navigator.pop(context);
            },
          ),
          if (message['senderName'] != widget.userName) // Chỉ mình mới thu hồi được tin mình gửi
            ListTile(
              leading: const Icon(Icons.history, color: Colors.redAccent),
              title: const Text("Thu hồi tin nhắn", style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                _onRecall(message['messageId']);
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _chatService.stopConnection();
    _controller.dispose();
    super.dispose();
  }
}