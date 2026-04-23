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
  final TextEditingController _searchController = TextEditingController();
  late Future<List<dynamic>> _groupsFuture;
  bool _isLoading = true;
  List<dynamic> _groups = [];
  List<dynamic> _filteredGroups = [];
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
      _filteredGroups = data;
      _isLoading = false;
    });
  }
  Future<void> _refreshGroups() async {
    setState(() {
      _groupsFuture = _chatService.getMyGroups();
    });
  }
  void _runFilter(String enteredKeyword) {
    List<dynamic> results = [];
    if (enteredKeyword.isEmpty) {
      results = _groups;
    } else {
      results = _groups
          .where((group) =>
          group["name"].toLowerCase().contains(enteredKeyword.toLowerCase()))
          .toList();
    }

    setState(() {
      _filteredGroups = results;
    });
  }
  void _handleNewMessageRealtime(dynamic msg) {
    final int incomingGroupId = msg['groupId'] ?? msg['GroupId'] ?? 0;

    setState(() {
      int index = _groups.indexWhere((g) => g['groupId'] == incomingGroupId);

      if (index != -1) {
        var updatedGroup = _groups.removeAt(index);
        updatedGroup['lastMessage'] = _buildLastMessagePreview(msg);
        updatedGroup['lastMessageAt'] = DateTime.now().toIso8601String();
        updatedGroup['unreadCount'] = (updatedGroup['unreadCount'] ?? 0) + 1;
        _groups.insert(0, updatedGroup);
        _runFilter(_searchController.text);
      } else {
        _loadInitialGroups();
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        centerTitle: true,
        title: const Text("MESSAGES",
            style: TextStyle(color: Colors.black87,fontWeight: FontWeight.w900)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
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
        color: Colors.black,
        backgroundColor: Colors.white,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
            : Column(
          children: [
            _buildSearchField(),
            _buildActiveUsersList(),
            // const Padding(
            //   padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
            //   child: Align(
            //     alignment: Alignment.centerLeft,
            //     child: Text("CONVERSATIONS",
            //         style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.black38)),
            //   ),
            // ),
            Expanded(
              child: _filteredGroups.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                itemCount: _filteredGroups.length,
                itemBuilder: (context, index) {
                  final group = _filteredGroups[index];

                  // THÊM HIỆU ỨNG POP & SLIDE TẠI ĐÂY
                  return TweenAnimationBuilder<double>(
                    // Mỗi item sẽ delay một chút tạo hiệu ứng sóng (staggered)
                    duration: Duration(milliseconds: 400 + (index * 100).clamp(0, 500)),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.easeOutQuart,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          // Trượt từ trên xuống (-30px về 0)
                          offset: Offset(0, -30 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            )
                          ]
                      ),
                      child: ChatItem(
                        name: group['name'],
                        lastMessage: group['lastMessage'] ?? "Tap to start chatting",
                        avatarUrl: group['avatar'] ?? "",
                        isOnline: group['isOnline'] == "Online",
                        time: group['lastMessageAt'] ?? "",
                        isUnread: (group['unreadCount'] ?? 0) > 0,
                        onTap: () => _navigateToChat(group),
                      ),
                    ),
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          // Chiều cao linh hoạt theo bàn phím
          height: MediaQuery.of(context).size.height * 0.75,
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 12, left: 20, right: 20
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Thanh cầm nắm (Handle bar)
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              const Text("NEW GROUP CHAT",
                  style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              const SizedBox(height: 24),

              // Input Tên Nhóm
              TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                      hintText: "Enter group name...",
                      hintStyle: const TextStyle(color: Colors.black26),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)
                  )
              ),
              const SizedBox(height: 24),

              const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("SELECT MEMBERS",
                      style: TextStyle(color: Colors.black45, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1))
              ),
              const SizedBox(height: 12),

              // Danh sách thành viên kèm Avatar
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _groups.where((g) => g['isGroup'] == false).length,
                  itemBuilder: (context, index) {
                    final privateChats = _groups.where((g) => g['isGroup'] == false).toList();
                    final user = privateChats[index];
                    int userId = user['otherUserId'] ?? 0;
                    bool isSelected = selectedMembers.any((m) => m['id'] == userId);

                    return InkWell(
                      onTap: () {
                        setModalState(() {
                          if (!isSelected) {
                            selectedMembers.add({'id': userId, 'name': user['name']});
                          } else {
                            selectedMembers.removeWhere((m) => m['id'] == userId);
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            // Avatar User
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: const Color(0xFFF5F5F5),
                              backgroundImage: NetworkImage(user['avatar'] ?? "https://static.vecteezy.com/system/resources/previews/009/292/244/non_2x/default-avatar-icon-of-social-media-user-vector.jpg"),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                user['name'],
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                            ),
                            // Custom Checkbox Đen
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? Colors.black : Colors.transparent,
                                border: Border.all(color: isSelected ? Colors.black : Colors.black12, width: 2),
                              ),
                              child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Nút Tạo Nhóm màu Đen chuẩn Chic
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: ElevatedButton(
                  onPressed: (selectedMembers.isEmpty || isCreating) ? null : () async {
                    setModalState(() => isCreating = true);
                    String groupName = nameController.text.trim();
                    if (groupName.isEmpty) groupName = "New Group";
                    List<int> ids = selectedMembers.map((m) => m['id'] as int).toList();
                    await _handleActualCreateGroup(groupName, ids);
                    if (mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: isCreating
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("CREATE GROUP", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                ),
              ),
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
      NotificationUtils.showTopRight(context, message: "Group created successfully!");
      _loadInitialGroups(); //refresh list
      if (_groups.isNotEmpty) {
        int newGroupId = _groups.first['groupId'];
        await _chatService.joinGroupManual(newGroupId);
      }
    }else{
      NotificationUtils.showTopRight(
          context,
          message: "Failed to create group, please try again!",
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
      padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 15.0), // Căn chỉnh lề giống Wardrobe
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, // Chuyển từ black12 sang trắng tinh khôi
          borderRadius: BorderRadius.circular(12), // Bo góc 12 đồng bộ
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03), // Bóng đổ siêu nhẹ chuẩn Chic
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => _runFilter(value),
          style: TextStyle(color: Colors.black),
          cursorColor: Colors.black, // Con trỏ màu đen cho sang
          decoration: InputDecoration(
            hintText: 'Search conversations...',
            hintStyle: TextStyle(color: Colors.black26, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: Colors.black87), // Icon đen đậm hơn chút
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.close, size: 18, color: Colors.black26),
              onPressed: () {
                _searchController.clear();
                _runFilter('');
              },
            )
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 14),
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
          const Text("No conversations yet",
              style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }

  String _buildLastMessagePreview(dynamic msg) {
    final content = (msg['content'] ?? '').toString().trim();
    final photos = (msg['photos'] as List?) ?? [];
    final sharedPostId = msg['sharedPostId'] ?? msg['SharedPostId'];

    if (content.isNotEmpty) return content;
    if (photos.isNotEmpty) return 'Đã gửi ảnh';
    if (sharedPostId != null) return 'Đã chia sẻ một bài viết';

    return 'Tin nhắn mới';
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    super.dispose();
  }
}
