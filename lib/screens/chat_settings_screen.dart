import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/chat_service.dart';
import '../utils/notification_utils.dart';
import '../utils/route_transitions.dart';
import 'groupMembersScreen.dart';
import 'groupPhotosScreen.dart';

class ChatSettingsScreen extends StatelessWidget {
  final int targetUserId;
  final int groupId;
  final String userName;
  final String avatarUrl;
  final bool isGroup;
  final List<dynamic> allGroups;

  const ChatSettingsScreen({
    super.key,
    required this.targetUserId,
    required this.userName,
    required this.avatarUrl,
    required this.groupId,
    this.isGroup = false,
    this.allGroups = const [],
  });

  void _handleCreateGroup(BuildContext context) async {
    showDialog(context: context, builder: (c) => const Center(child: CircularProgressIndicator(color: AppColors.textPink)));
    bool success = await ChatService().createGroup(
      name: "Nhóm mới với $userName",
      memberIds: [targetUserId],
    );
    Navigator.pop(context);
    if (success) {
      NotificationUtils.showTopRight(context, message: "Tạo nhóm thành công!");
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    } else {
      NotificationUtils.showTopRight(context, message: "Tạo nhóm thất bại!", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(radius: 50, backgroundImage: NetworkImage(avatarUrl)),
                const SizedBox(height: 16),
                Text(userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: ListView(
              children: [
                _buildActionItem(Icons.search, "Tìm kiếm cuộc trò chuyện",
                    onTap: () {
                      Navigator.pop(context, "OPEN_SEARCH");
                    }),
                if (!isGroup) ...[
                  _buildActionItem(
                      Icons.groups_outlined,
                      "Tạo nhóm với $userName",
                      onTap: () => _handleCreateGroup(context)
                  ),
                ] else ...[
                  _buildActionItem(
                      Icons.people_outline,
                      "Xem và quản lý thành viên",
                      onTap: () {
                        Navigator.push(
                          context,
                          SlideRoute(
                            page: GroupMembersScreen(
                              groupId: groupId,
                              allGroups: allGroups, // Truyền danh sách chat để lọc bạn bè
                            ),
                          ),
                        );
                      }
                  ),
                ],
                _buildActionItem(Icons.image_outlined, "Xem file phương tiện & lịch sử hình ảnh",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GroupPhotosScreen(groupId: groupId),
                        ),
                      );
                    }
                ),
                //const Divider(color: AppColors.divider, height: 40),
                // _buildActionItem(Icons.notifications_off_outlined, "Tắt thông báo"),
                // _buildActionItem(Icons.block_flipped, "Chặn", isDanger: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String title, {bool isDanger = false, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: isDanger ? Colors.redAccent : Colors.white),
      title: Text(title, style: TextStyle(color: isDanger ? Colors.redAccent : Colors.white, fontSize: 15)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
      onTap: onTap,
    );
  }
}