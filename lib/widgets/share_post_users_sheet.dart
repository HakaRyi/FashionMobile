import 'package:flutter/material.dart';

import '../managers/post_manager.dart';
import '../models/post_feed_model.dart';
import '../models/shareable_user_model.dart';
import '../services/notification_service.dart';
import '../utils/notification_utils.dart';
import 'share_user_list.dart';

class SharePostUsersSheet extends StatefulWidget {
  final PostFeedModel post;

  const SharePostUsersSheet({
    super.key,
    required this.post,
  });

  @override
  State<SharePostUsersSheet> createState() => _SharePostUsersSheetState();
}

class _SharePostUsersSheetState extends State<SharePostUsersSheet> {
  final Set<int> _selectedUserIds = {};
  final TextEditingController _captionController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  void _toggleUser(ShareableUserModel user) {
    setState(() {
      if (_selectedUserIds.contains(user.accountId)) {
        _selectedUserIds.remove(user.accountId);
      } else {
        _selectedUserIds.add(user.accountId);
      }
    });
  }

  String _normalizeError(Object error) {
    final text = error.toString();

    if (text.startsWith('Exception: ')) {
      return text.replaceFirst('Exception: ', '').trim();
    }

    return text;
  }

  Future<void> _handleShare() async {
    if (_selectedUserIds.isEmpty || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await postManager.sharePostToChat(
        post: widget.post,
        receiverAccountIds: _selectedUserIds.toList(),
        caption: _captionController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      NotificationUtils.showTopRight(
        context,
        message: 'Post shared successfully.',
      );

      await NotificationService().showManualLocalNotification(
        title: 'Post shared',
        body: 'You shared this post with ${_selectedUserIds.length} user(s).',
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      final message = _normalizeError(e);

      NotificationUtils.showTopRight(
        context,
        message: 'Failed to share post.',
        isError: true,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(message),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selectedUserIds.length;

    return SafeArea(
      top: false,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.84,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 14),
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'SHARE TO CHAT',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F1F1),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.black.withOpacity(0.05),
                      ),
                    ),
                    child: Text(
                      selectedCount == 1
                          ? '1 selected'
                          : '$selectedCount selected',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _captionController,
                maxLines: 2,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Add a message...',
                  hintStyle: const TextStyle(
                    color: Colors.black38,
                    fontWeight: FontWeight.w500,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF7F7F7),
                  contentPadding: const EdgeInsets.all(14),
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
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ShareUserList(
                  selectedUserIds: _selectedUserIds,
                  onToggleUser: _toggleUser,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                  (_selectedUserIds.isEmpty || _isSubmitting)
                      ? null
                      : _handleShare,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.black,
                    disabledBackgroundColor: const Color(0xFFEDEDED),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.black38,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'SHARE',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}