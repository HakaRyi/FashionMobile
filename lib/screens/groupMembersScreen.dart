import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../services/chat_service.dart';
import '../utils/route_transitions.dart';
import 'chat_screen.dart';
import 'other_profile_screen.dart';

class GroupMembersScreen extends StatefulWidget {
  final int groupId;
  final List<dynamic> allGroups; // Nhận danh sách này để lấy bạn bè mời

  const GroupMembersScreen({
    super.key,
    required this.groupId,
    this.allGroups = const []
  });

  @override
  State<GroupMembersScreen> createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends State<GroupMembersScreen> {
  final ChatService _chatService = ChatService();
  List<dynamic> _members = [];
  List<dynamic> _filteredMembers = [];
  bool _isLoading = true;
  String myId = "";

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMyId();
    _fetchMembers();
  }

  Future<void> _loadMyId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      myId = prefs.getString('userId') ?? "";
    });
  }

  Future<void> _fetchMembers() async {
    final data = await _chatService.getUsersInGroup(widget.groupId);
    if (mounted) {
      setState(() {
        _members = data;
        _filteredMembers = data;
        _isLoading = false;
      });
    }
  }

  void _filterMembers(String query) {
    setState(() {
      _filteredMembers = _members
          .where((user) => user['username']
          .toString()
          .toLowerCase()
          .contains(query.toLowerCase()))
          .toList();
    });
  }

  // --- LOGIC THÊM THÀNH VIÊN VÀ LỌC TRÙNG ---
  void _showAddMemberBottomSheet() {
    // 1. Lấy danh sách chat 1-1
    final List<dynamic> allFriends = widget.allGroups.where((g) => g['isGroup'] == false).toList();

    // 2. LỌC TRÙNG: Chỉ lấy những người CHƯA CÓ trong group này
    // user['id'] là AccountId từ API get-users-in-group
    // friend['otherUserId'] là AccountId từ API get-my-groups
    final List<dynamic> availableFriends = allFriends.where((friend) {
      return !_members.any((m) => m['id'] == friend['otherUserId']);
    }).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text("Mời vào nhóm", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            if (availableFriends.isEmpty)
              const Expanded(child: Center(child: Text("Mọi người đều đã ở trong nhóm", style: TextStyle(color: Colors.white38))))
            else
              Expanded(
                child: ListView.separated(
                  itemCount: availableFriends.length,
                  separatorBuilder: (c, i) => const Divider(color: Colors.white10),
                  itemBuilder: (c, index) {
                    final friend = availableFriends[index];
                    return ListTile(
                      leading: CircleAvatar(backgroundImage: NetworkImage(friend['avatar'] ?? "https://cdn-icons-png.flaticon.com/512/8377/8377384.png")),
                      title: Text(friend['name'] ?? "User", style: const TextStyle(color: Colors.white)),
                      trailing: const Icon(Icons.add_circle_outline, color: AppColors.textPink),
                      onTap: () {
                        Navigator.pop(ctx);
                        _handleActualAddMember(friend['otherUserId']);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleActualAddMember(int targetId) async {
    showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator(color: AppColors.textPink)));

    bool success = await _chatService.addMemberToGroup(widget.groupId, targetId);

    if (mounted) Navigator.pop(context); // Tắt loading

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã thêm thành viên!")));
      _fetchMembers(); // Load lại danh sách tại chỗ để thấy người mới
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Thành viên nhóm", style: TextStyle(fontSize: 18)),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      // THÊM NÚT "+" Ở ĐÂY
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.textPink,
        child: const Icon(Icons.person_add, color: Colors.white),
        onPressed: () => _showAddMemberBottomSheet(),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: _filterMembers,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Tìm thành viên...",
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.textPink))
                : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredMembers.length,
              separatorBuilder: (context, index) => const Divider(color: Colors.white10),
              itemBuilder: (context, index) {
                final user = _filteredMembers[index];
                final bool isMe = user['id'].toString() == myId;

                return ListTile(
                  onTap: isMe ? null : () => _showUserOptions(user),
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(user['avatar'] ?? "https://static.vecteezy.com/system/resources/previews/009/292/244/non_2x/default-avatar-icon-of-social-media-user-vector.jpg"),
                  ),
                  title: Row(
                    children: [
                      Text(user['username'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      if (isMe) ...[
                        const SizedBox(width: 8),
                        const Text("(Bạn)", style: TextStyle(color: Colors.white38, fontSize: 12)),
                      ]
                    ],
                  ),
                  subtitle: Text(user['isOnline'] == "Online" ? "Đang hoạt động" : "Ngoại tuyến",
                      style: TextStyle(color: user['isOnline'] == "Online" ? Colors.greenAccent : Colors.white38, fontSize: 12)),
                  trailing: user['status'] == "Active" ? const Icon(Icons.check_circle, color: Colors.pinkAccent, size: 16) : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleStartPrivateChat(int targetUserId, String name, String avatar) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.textPink)),
    );
    try {
      final groupId = await _chatService.createOrGet1v1Room(targetUserId);
      Navigator.pop(context);

      if (groupId != null) {
        Navigator.push(
          context,
          SlideRoute(
            page: ChatScreen(
              groupId: groupId,
              userName: name,
              avatarUrl: avatar,
              otherUserId: targetUserId,
              isGroup: false,
              isOnline: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      print("Lỗi nhắn tin riêng: $e");
    }
  }

  void _showUserOptions(dynamic user) {
    // 1. KIỂM TRA NẾU LÀ CHÍNH MÌNH THÌ KHÔNG LÀM GÌ CẢ
    if (user['id'].toString() == myId) {
      print("DEBUG: Đây là tôi, không hiện option.");
      return;
    }

    final int accountId = user['id'];
    final String username = user['username'] ?? "Người dùng";
    final String avatar = user['avatar'] ?? "https://cdn-icons-png.flaticon.com/512/8377/8377384.png";

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CircleAvatar(backgroundImage: NetworkImage(avatar)),
                title: Text(username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text("Tùy chọn thành viên", style: TextStyle(color: Colors.white54, fontSize: 12)),
              ),
              const Divider(color: Colors.white10),

              ListTile(
                leading: const Icon(Icons.person_outline, color: Colors.white),
                title: const Text("Xem trang cá nhân", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    SlideRoute(page: OtherProfileScreen(userId: accountId)),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                title: const Text("Nhắn tin riêng", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _handleStartPrivateChat(accountId, username, avatar);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}