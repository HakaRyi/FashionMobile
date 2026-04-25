import 'package:flutter/material.dart';

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
      if (!mounted) {
        return;
      }

      setState(() {
        _keyword = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      await postManager.fetchShareableUsers(refresh: widget.refreshOnOpen);
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = _normalizeError(e);
      });
    }
  }

  String _normalizeError(Object error) {
    final text = error.toString();

    if (text.startsWith('Exception: ')) {
      return text.replaceFirst('Exception: ', '').trim();
    }

    return text;
  }

  List<ShareableUserModel> _filterUsers(List<ShareableUserModel> users) {
    if (_keyword.isEmpty) {
      return users;
    }

    return users.where((user) {
      final name = user.userName.toLowerCase();
      return name.contains(_keyword);
    }).toList();
  }

  Widget _buildRoleBadge({
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark ? Colors.black : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black54,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
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
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Search people to share...',
                hintStyle: const TextStyle(
                  color: Colors.black38,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.black45,
                ),
                filled: true,
                fillColor: const Color(0xFFF7F7F7),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: Colors.black.withOpacity(0.06),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Colors.black,
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
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
                  : postManager.isLoadingShareableUsers
                  ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.black,
                ),
              )
                  : users.isEmpty
                  ? const Center(
                child: Text(
                  'No people available to share with.',
                  style: TextStyle(
                    color: Colors.black45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
                  : ListView.separated(
                itemCount: users.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final user = users[index];
                  final isSelected = widget.selectedUserIds
                      .contains(user.accountId);

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => widget.onToggleUser(user),
                      child: AnimatedContainer(
                        duration:
                        const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFF1F1F1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? Colors.black
                                : Colors.black.withOpacity(0.06),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor:
                              const Color(0xFFF1F1F1),
                              backgroundImage:
                              user.avatarUrl != null &&
                                  user.avatarUrl!
                                      .isNotEmpty
                                  ? NetworkImage(
                                user.avatarUrl!,
                              )
                                  : null,
                              child: user.avatarUrl == null ||
                                  user.avatarUrl!.isEmpty
                                  ? const Icon(
                                Icons.person,
                                color: Colors.black26,
                              )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.userName.isNotEmpty
                                        ? user.userName
                                        : 'User',
                                    maxLines: 1,
                                    overflow:
                                    TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                      fontWeight:
                                      FontWeight.w900,
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
                                          isDark: false,
                                        ),
                                      if (user.isFollowing)
                                        _buildRoleBadge(
                                          label: 'You follow',
                                          isDark: true,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Checkbox(
                              value: isSelected,
                              activeColor: Colors.black,
                              checkColor: Colors.white,
                              side: const BorderSide(
                                color: Colors.black38,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(5),
                              ),
                              onChanged: (_) =>
                                  widget.onToggleUser(user),
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