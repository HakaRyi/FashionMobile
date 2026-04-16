import 'dart:async';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../widgets/chat_item.dart';
import '../utils/global_event_bus.dart';
import '../utils/notification_utils.dart';
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
              _showCreateGroupDialog();
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
  void _showCreateGroupDialog() async {
    List<Map<String, dynamic>> selectedMembers = [];
    TextEditingController nameController = TextEditingController();
    bool isCreating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Tạo nhóm mới", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                      hintText: "Tên nhóm...",
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)
                  )
              ),
              const SizedBox(height: 20),
              const Align(alignment: Alignment.centerLeft, child: Text("Chọn thành viên", style: TextStyle(color: Colors.white70))),

              SizedBox(
                height: 200,
                child: ListView.builder(
                  // Chỉ lấy những phòng chat 1-1 để mời
                  itemCount: _groups.where((g) => g['isGroup'] == false).length,
                  itemBuilder: (context, index) {
                    final privateChats = _groups.where((g) => g['isGroup'] == false).toList();
                    final user = privateChats[index];

                    // Logic lấy ID: Cần kiểm tra kĩ field ID của user trong group private của ní
                    int userId = user['otherUserId']??0;

                    bool isSelected = selectedMembers.any((m) => m['id'] == userId);

                    return CheckboxListTile(
                      title: Text(user['name'], style: const TextStyle(color: Colors.white)),
                      value: isSelected,
                      activeColor: AppColors.textPink,
                      onChanged: (val) {
                        setModalState(() {
                          if (val == true) {
                            selectedMembers.add({'id': userId, 'name': user['name']});
                          } else {
                            selectedMembers.removeWhere((m) => m['id'] == userId);
                          }
                        });
                      },
                    );
                  },
                ),
              ),

              ElevatedButton(
                onPressed: (selectedMembers.isEmpty || isCreating) ? null : () async {
                  setModalState(() => isCreating = true);

                  String groupName = nameController.text.trim();
                  if (groupName.isEmpty) groupName = "Nhóm mới";
                  List<int> ids = selectedMembers.map((m) => m['id'] as int).toList();

                  // FIX LỖI Ở ĐÂY: Bây giờ hàm này trả về Future nên await được
                  await _handleActualCreateGroup(groupName, ids);

                  if (mounted) {
                    Navigator.pop(context); // Đóng BottomSheet
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textPink,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: isCreating
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("TẠO NHÓM"),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  Future<void> _handleActualCreateGroup(String name, List<int> memberIds) async {
    showDialog(context: context, builder: (c) => const Center(child: CircularProgressIndicator()));

    bool success = await _chatService.createGroup(
      name: name,
      memberIds: memberIds,
    );

    if (mounted) Navigator.pop(context);

    if (success) {
      NotificationUtils.showTopRight(context, message: "Tạo nhóm thành công!");
      _loadInitialGroups(); //refresh list
      if (_groups.isNotEmpty) {
        int newGroupId = _groups.first['groupId'];
        await _chatService.joinGroupManual(newGroupId);
      }
    }else{
      NotificationUtils.showTopRight(
          context,
          message: "Tạo nhóm thất bại, vui lòng thử lại!",
          isError: true
      );
    }
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
          otherUserId: group['otherUserId'],
          avatarUrl: group['avatar'] ?? "https://static.vecteezy.com/system/resources/previews/009/292/244/non_2x/default-avatar-icon-of-social-media-user-vector.jpg",
          isOnline: group['isOnline'] == "Online",
          isGroup: group['isGroup'] ?? false,
          allGroups: _groups,
        ),
      ),
    ).then((_) => _loadInitialGroups());
  }
  Widget _buildActiveUsersList() {
    final activeFriends = _groups.where((g) {
      return g['isGroup'] == false && g['isOnline'] == "Online";
    }).toList();
    return SizedBox(
      height: 105,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 16, top: 5),
        scrollDirection: Axis.horizontal,
        itemCount: activeFriends.length,
        itemBuilder: (context, index) {
          final group = activeFriends[index];

          return ActiveUserAvatar(
            avatarUrl: group['avatar'] ?? "https://static.vecteezy.com/system/resources/previews/009/292/244/non_2x/default-avatar-icon-of-social-media-user-vector.jpg",
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
