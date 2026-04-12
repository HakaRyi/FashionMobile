import 'dart:async';

import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../widgets/chat_item.dart';
import '../utils/global_event_bus.dart';
import 'chat_screen.dart';
import '../../utils/route_transitions.dart';
import '../../widgets/active_user_avatar.dart';
import '../../services/chat_service.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  late Future<List<dynamic>> _groupsFuture;
  bool _isLoading = true;
  List<dynamic> _groups = [];
  StreamSubscription? _msgSub;
  @override
  void initState() {
    super.initState();
    _loadInitialGroups();

    // 2. Lắng nghe EventBus khi có tin nhắn mới tới
    _msgSub = GlobalEventBus().onMessageReceived.listen((event) {
      _handleNewMessageRealtime(event.message);
    });
  }
  Future<void> _loadInitialGroups() async {
    if (_groups.isEmpty) setState(() => _isLoading = true);
    final data = await _chatService.getMyGroups();
    setState(() {
      _groups = data;
      _isLoading = false;
    });
  }
  Future<void> _refreshGroups() async {
    setState(() {
      _groupsFuture = _chatService.getMyGroups();
    });
  }
  void _handleNewMessageRealtime(dynamic msg) {
    final int incomingGroupId = msg['groupId'] ?? msg['GroupId'] ?? 0;

    setState(() {
      int index = _groups.indexWhere((g) => g['groupId'] == incomingGroupId);

      if (index != -1) {
        var updatedGroup = _groups.removeAt(index);
        updatedGroup['lastMessage'] = msg['content'];
        updatedGroup['lastMessageAt'] = DateTime.now().toIso8601String();
        updatedGroup['unreadCount'] = (updatedGroup['unreadCount'] ?? 0) + 1;
        _groups.insert(0, updatedGroup);
      } else {
        _loadInitialGroups();
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text("TIN NHẮN",
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note, color: AppColors.textPink),
            onPressed: () {
              // Logic tạo nhóm mới hoặc tìm stylist
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadInitialGroups,
        color: AppColors.textPink,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.textPink))
            : _groups.isEmpty
            ? _buildEmptyState()
            : Column(
          children: [
            _buildSearchField(),
            // 1. Dòng avatar Online
            _buildActiveUsersList(),
            // 2. Danh sách chat chính
            Expanded(
              child: ListView.separated(
                itemCount: _groups.length,
                separatorBuilder: (context, index) => const Divider(color: Colors.white10, indent: 85),
                itemBuilder: (context, index) {
                  final group = _groups[index];
                  return ChatItem(
                    name: group['name'],
                    lastMessage: group['lastMessage'] ?? "Bấm để trò chuyện",
                    avatarUrl: group['avatar'] ?? "...",
                    isOnline: group['isOnline'] == "Online",
                    time: group['lastMessageAt'] ?? "",
                    isUnread: (group['unreadCount'] ?? 0) > 0,
                    onTap: () => _navigateToChat(group),
                  );
                },
              ),
            ),
          ],
        ),
      ),

    );
  }

  void _navigateToChat(dynamic group) {
    setState(() {
      group['unreadCount'] = 0;
    });
    Navigator.push(
      context,
      SlideRoute(
        page: ChatScreen(
          groupId: group['groupId'],
          userName: group['name'],
          avatarUrl: group['avatar'] ?? "https://cdn-icons-png.flaticon.com/512/8377/8377384.png",
          isOnline: group['isOnline'] == "Online",
        ),
      ),
    ).then((_) => _loadInitialGroups());
  }
  Widget _buildActiveUsersList() {
    return SizedBox(
      height: 105,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 16, top: 5),
        scrollDirection: Axis.horizontal,
        itemCount: _groups.length,
        itemBuilder: (context, index) {
          final group = _groups[index];
          if (group['isOnline'] != "Online") return const SizedBox.shrink();

          return ActiveUserAvatar(
            avatarUrl: group['avatar'] ?? "https://cdn-icons-png.flaticon.com/512/8377/8377384.png",
            name: group['name'],
            isOnline: true,
            onTap: () => _navigateToChat(group),
          );
        },
      ),
    );
  }
  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const TextField(
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            icon: Icon(Icons.search, color: Colors.grey),
            hintText: "Tìm kiếm cuộc trò chuyện...",
            hintStyle: TextStyle(color: Colors.grey),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.white24),
          const SizedBox(height: 16),
          const Text("Chưa có cuộc hội thoại nào",
              style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
  @override
  void dispose() {
    _msgSub?.cancel();
    super.dispose();
  }
}
