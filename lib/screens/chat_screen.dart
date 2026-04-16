import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../services/notification_service.dart';
import '../utils/global_event_bus.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input_field.dart';
import '../screens/chat_settings_screen.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final int groupId;
  final String userName;
  final String avatarUrl;
  final bool isOnline; // Thêm vào constructor
  final bool isGroup;
  final int? otherUserId;
  final List<dynamic> allGroups;

  const ChatScreen({
    super.key,
    required this.groupId,
    required this.userName,
    required this.avatarUrl,
    this.isOnline = false,
    this.isGroup = false,
    this.otherUserId,
    this.allGroups = const [],
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
  StreamSubscription? _msgSub;
  StreamSubscription? _recallSub;
  StreamSubscription? _reactSub;
  bool _isSearching = false;
  final TextEditingController _searchControllerLocal = TextEditingController();
  String _searchQuery = "";
  List<dynamic> _searchResults = [];
  @override
  void initState() {
    super.initState();
    ChatService.currentGroupId = widget.groupId;
    NotificationService().clearAllNotifications();
    _loadMyId();
    _loadHistory();
    _msgSub = GlobalEventBus().onMessageReceived.listen((event) {
      _handleIncomingMessage(event.message);
    });
    _recallSub = GlobalEventBus().onMessageRecalled.listen((event) {
      if (mounted) {
        setState(() {
          final index = _messages.indexWhere((m) => m['messageId'] == event.messageId);
          if (index != -1) {
            _messages[index]['content'] = "Tin nhắn đã bị thu hồi";
            _messages[index]['isRecalled'] = true;
          }
        });
      }
    });
    void _onSearchMessage(String query) {
      if (query.isEmpty) {
        setState(() {
          _searchResults = [];
        });
        return;
      }
      setState(() {
        _searchResults = _messages.where((m) {
          final content = (m['content'] ?? "").toString().toLowerCase();
          return content.contains(query.toLowerCase());
        }).toList();
      });
    }
    // 3. LẮNG NGHE THẢ REACT (Đây là cái ní đang thiếu nè)
    _reactSub = GlobalEventBus().onMessageReaction.listen((event) {
      if (mounted) {
        setState(() {
          final index = _messages.indexWhere((m) => m['messageId'] == event.messageId);
          if (index != -1) {
            // Cập nhật reaction ngay lập tức trên UI
            _messages[index]['reactions'] = [{'reactionType': event.type}];
          }
        });
      }
    });
  }
  void _handleIncomingMessage(dynamic msg) {
    if (!mounted) return;

    final int incomingGroupId = msg['groupId'] ?? msg['GroupId'] ?? 0;
    if (incomingGroupId != widget.groupId) return;
    print("DEBUG SIGNALR: Nhận 1 tin mới ID=${msg['messageId']}. Nội dung=${msg['content']}");
    setState(() {
      final avatar = msg['senderAvatar'] ?? msg['SenderAvatar'];
      final incomingContent = (msg['content'] ?? msg['Content'] ?? "").toString().trim();
      final incomingPhotos = msg['photos'] ?? msg['Photos'] ?? [];
      int removedCount = 0;
      _messages.removeWhere((m) {
        bool isTemp = m['messageId'] == -1;
        bool match = isTemp && (m['content'] ?? "").toString().trim() == incomingContent;
        if (match) removedCount++;
        return match;
      });
      print("DEBUG SIGNALR: Đã xóa $removedCount tin nhắn ảo khớp nội dung.");
      final normalizedMsg = {
        ...msg,
        'content': incomingContent,
        'photos': incomingPhotos,
        'senderName': msg['senderName'] ?? msg['SenderName'] ?? "Unknown",
        'senderAvatar': avatar,
        'sentAt': msg['sentAt'] ?? msg['SentAt'] ?? DateTime.now().toIso8601String(),
      };
      bool alreadyExists = _messages.any((m) => m['messageId'] == normalizedMsg['messageId']);
      if (!alreadyExists) {
        _messages.insert(0, normalizedMsg);
        print("DEBUG SIGNALR: Đã chèn tin nhắn thật vào danh sách.");
      } else {
        print("DEBUG SIGNALR: Tin nhắn này đã tồn tại, bỏ qua insert.");
      }
    });
  }
  void _loadMyId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      myId = prefs.getString('userId') ?? "";
    });
  }

  void _loadHistory() async {
    final history = await _chatService.getChatHistory(widget.groupId);
    if (mounted) {
      setState(() {
        _messages = history.map((m) {
          return {
            ...m,
            'senderAvatar': m['senderAvatar'] ?? widget.avatarUrl,
          };
        }).toList().reversed.toList();
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
  void _navigateToSettings() async {
    final result = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ChatSettingsScreen(
              targetUserId: widget.otherUserId ?? 0,
              userName: widget.userName,
              avatarUrl: widget.avatarUrl,
              isGroup: widget.isGroup,
              groupId: widget.groupId,
              allGroups: widget.allGroups,
            )
        )
    );
    if (result == "OPEN_SEARCH") {
      setState(() {
        _isSearching = true;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    // 1. Logic lọc tin nhắn theo Search Query
    final filteredMessages = _messages.where((m) {
      if (_searchQuery.isEmpty) return true;
      final content = (m['content'] ?? "").toString().toLowerCase();
      return content.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () {
            if (_isSearching) {
              setState(() {
                _isSearching = false;
                _searchQuery = "";
                _searchControllerLocal.clear();
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        // 2. AppBar biến hình: Nếu đang search thì hiện TextField, không thì hiện Profile
        title: _isSearching
            ? TextField(
          controller: _searchControllerLocal,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: const InputDecoration(
            hintText: "Tìm tin nhắn...",
            hintStyle: TextStyle(color: Colors.white38),
            border: InputBorder.none,
          ),
          onChanged: (val) {
            setState(() {
              _searchQuery = val;
            });
          },
        )
            : InkWell(
          onTap: _navigateToSettings, // Gọi hàm điều hướng có hứng kết quả tag
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
          // 3. Thanh hiển thị số kết quả tìm thấy (Chỉ hiện khi đang search)
          if (_isSearching && _searchQuery.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.white.withOpacity(0.05),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 14, color: Colors.white38),
                  const SizedBox(width: 8),
                  Text("Tìm thấy ${filteredMessages.length} kết quả", style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.textPink))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              reverse: true,
              // 4. Dùng filteredMessages thay vì _messages
              itemCount: filteredMessages.length,
              itemBuilder: (context, index) {
                final m = filteredMessages[index];
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
                      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!isMe) ...[
                          CircleAvatar(
                            radius: 14,
                            backgroundImage: NetworkImage(m['senderAvatar'] ?? "https://cdn-icons-png.flaticon.com/512/8377/8377384.png"),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              if (!isMe)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4, bottom: 2),
                                  child: Text(
                                    m['senderName'] ?? "Unknown",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ChatBubble(
                                message: m['content'] ?? "",
                                photos: (m['photos'] as List?)?.map((e) => e.toString()).toList(),
                                reactions: m['reactions'],
                                isMe: isMe,
                              ),
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
                        if (!isMe) const SizedBox(width: 40),
                        if (isMe) const SizedBox(width: 8),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // 5. Ẩn thanh nhập tin nhắn khi đang search để tập trung tìm kiếm
          if (!_isSearching) ChatInputField(controller: _controller, onSend: _handleSend),
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
              //_chatService.pinMessage(message['messageId'], widget.groupId);
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
    ChatService.currentGroupId = null;
    _chatService.stopConnection();
    _controller.dispose();
    _msgSub?.cancel();
    _recallSub?.cancel();
    _reactSub?.cancel();
    super.dispose();
  }
}