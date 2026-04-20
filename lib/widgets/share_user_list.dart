import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../managers/post_manager.dart';
import '../models/shareable_user_model.dart';

class ShareUserList extends StatefulWidget {
  final Set<int> selectedUserIds;
  final ValueChanged<ShareableUserModel> onToggleUser;
  final bool refreshOnOpen;

  const ShareUserList({
    super.key,
    required this.selectedUserIds,
    required this.onToggleUser,
    this.refreshOnOpen = true,
  });

  @override
  State<ShareUserList> createState() => _ShareUserListState();
}

class _ShareUserListState extends State<ShareUserList> {
  final TextEditingController _searchController = TextEditingController();
  String _keyword = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(() {
      if (!mounted) return;
      setState(() {
        _keyword = _searchController.text.trim().toLowerCase();
      });
    });
  }

  Future<void> _loadUsers() async {
    try {
      await postManager.fetchShareableUsers(refresh: widget.refreshOnOpen);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    }
  }

  List<ShareableUserModel> _filterUsers(List<ShareableUserModel> users) {
    if (_keyword.isEmpty) return users;

    return users.where((u) {
      final name = u.userName.toLowerCase();
      return name.contains(_keyword);
    }).toList();
  }

  Widget _buildRoleBadge({
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: postManager,
      builder: (context, _) {
        final allUsers = postManager.shareableUsers;
        final users = _filterUsers(allUsers);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Tìm người để chia sẻ...',
                hintStyle: const TextStyle(
                  color: AppColors.textSecondary,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: AppColors.backgroundSecondary,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: AppColors.divider,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.textPink,
                    width: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _error != null
                  ? Center(
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: Colors.redAccent,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
                  : postManager.isLoadingShareableUsers
                  ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.textPink,
                ),
              )
                  : users.isEmpty
                  ? const Center(
                child: Text(
                  'Không có người nào để chia sẻ',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),
              )
                  : ListView.separated(
                itemCount: users.length,
                separatorBuilder: (_, __) => const Divider(
                  color: AppColors.divider,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final user = users[index];
                  final isSelected = widget.selectedUserIds.contains(user.accountId);

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => widget.onToggleUser(user),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.backgroundSecondary
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.textPink.withOpacity(0.45)
                                : AppColors.divider,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.backgroundSecondary,
                              backgroundImage: user.avatarUrl != null &&
                                  user.avatarUrl!.isNotEmpty
                                  ? NetworkImage(user.avatarUrl!)
                                  : null,
                              child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                                  ? const Icon(
                                Icons.person,
                                color: AppColors.textPink,
                              )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.userName.isNotEmpty
                                        ? user.userName
                                        : 'Người dùng',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      if (user.isFollower)
                                        _buildRoleBadge(
                                          label: 'Follows you',
                                          color: Colors.teal,
                                        ),
                                      if (user.isFollowing)
                                        _buildRoleBadge(
                                          label: 'You follow',
                                          color: AppColors.textPink,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Checkbox(
                              value: isSelected,
                              activeColor: AppColors.textPink,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              onChanged: (_) => widget.onToggleUser(user),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}