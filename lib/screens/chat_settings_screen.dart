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
      name: "New group with $userName",
      memberIds: [targetUserId],
    );
    Navigator.pop(context);
    if (success) {
      NotificationUtils.showTopRight(context, message: "Group created successfully!");
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    } else {
      NotificationUtils.showTopRight(context, message: "Failed to create group!", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black45),
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
                Text(userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: ListView(
              children: [
                _buildActionItem(Icons.search, "Search in conversation",
                    onTap: () {
                      Navigator.pop(context, "OPEN_SEARCH");
                    }),
                if (!isGroup) ...[
                  _buildActionItem(
                      Icons.groups_outlined,
                      "Create group with $userName",
                      onTap: () => _handleCreateGroup(context)
                  ),
                ] else ...[
                  _buildActionItem(
                      Icons.people_outline,
                      "View and manage members",
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
                _buildActionItem(Icons.image_outlined, "Media, files & links",
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
      leading: Icon(icon, color: isDanger ? Colors.redAccent : Colors.black),
      title: Text(title, style: TextStyle(color: isDanger ? Colors.redAccent : Colors.black, fontSize: 15)),
      trailing: const Icon(Icons.chevron_right, color: Colors.black26, size: 20),
      onTap: onTap,
    );
  }
}