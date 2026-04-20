import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
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

  void _toggleUser(ShareableUserModel user) {
    setState(() {
      if (_selectedUserIds.contains(user.accountId)) {
        _selectedUserIds.remove(user.accountId);
      } else {
        _selectedUserIds.add(user.accountId);
      }
    });
  }

  Future<void> _handleShare() async {
    if (_selectedUserIds.isEmpty || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await postManager.sharePostToChat(
        post: widget.post,
        receiverAccountIds: _selectedUserIds.toList(),
        caption: _captionController.text.trim(),
      );

      if (!mounted) return;

      NotificationUtils.showTopRight(
        context,
        message: 'Đã chia sẻ bài viết thành công',
      );

      // Nếu bạn muốn máy người gửi cũng nổi 1 local notification nội bộ sau khi share xong
      // thì giữ đoạn này. Không ảnh hưởng flow chat hiện tại.
      await NotificationService().showManualLocalNotification(
        title: 'Chia sẻ bài viết',
        body: 'Bạn đã chia sẻ bài viết cho ${_selectedUserIds.length} người',
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      NotificationUtils.showTopRight(
        context,
        message: 'Chia sẻ thất bại',
        isError: true,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Chia sẻ thất bại: $e'),
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
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.84,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 14),
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.25),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Chia sẻ vào chat',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.textPink.withOpacity(0.25),
                      ),
                    ),
                    child: Text(
                      '${_selectedUserIds.length} đã chọn',
                      style: const TextStyle(
                        color: AppColors.textPink,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
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
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Thêm lời nhắn...',
                  hintStyle: const TextStyle(
                    color: AppColors.textSecondary,
                  ),
                  filled: true,
                  fillColor: AppColors.backgroundSecondary,
                  contentPadding: const EdgeInsets.all(14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
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
                  onPressed: (_selectedUserIds.isEmpty || _isSubmitting)
                      ? null
                      : _handleShare,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppColors.textPink,
                    disabledBackgroundColor: AppColors.textSecondary.withOpacity(0.25),
                    foregroundColor: Colors.white,
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
                    'Chia sẻ',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
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