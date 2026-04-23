// lib/widgets/post_item.dart
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/post_status_values.dart';
import '../managers/post_manager.dart';
import '../models/post_feed_model.dart';
import '../screens/create_post_screens.dart';
import '../screens/navbar_screens/profile_screen.dart';
import '../screens/other_profile_screen.dart';
import '../screens/public_wardrobe_screen.dart';
import 'comments/comment_sheet.dart';
import 'share_post_users_sheet.dart';
import 'report_post_sheet.dart';

class PostItem extends StatefulWidget {
  final PostFeedModel post;
  final bool isMyPost;
  final VoidCallback? onRefresh;

  const PostItem({
    super.key,
    required this.post,
    this.isMyPost = false,
    this.onRefresh,
  });

  @override
  State<PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  final PageController _pageController = PageController();

  int currentPage = 0;
  bool showHeart = false;

  int get postId => widget.post.postId;

  @override
  void initState() {
    super.initState();
    // postId = widget.post.postId;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void didUpdateWidget(covariant PostItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.post.postId != widget.post.postId) {
      currentPage = 0;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      });
    }
  }

  bool _canEditPost(String? status) {
    final s = status?.toLowerCase();
    return s != PostStatusValues.rejected.toLowerCase() &&
        s != 'airejected' &&
        s != 'blockedbyadmin';
  }

  void _openUserPublicWardrobe() {
    final currentPost = postManager.getPostAnywhereOrNull(postId) ?? widget.post;

    if (currentPost.accountId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User information not found.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PublicWardrobeScreen(accountId: currentPost.accountId),
      ),
    );
  }

  Future<void> _handleProfileNavigation(
      BuildContext context,
      int postUserId,
      ) async {
    final prefs = await SharedPreferences.getInstance();

    final dynamic rawUserId = prefs.get('userId');
    int? currentUserId;

    if (rawUserId is int) {
      currentUserId = rawUserId;
    } else if (rawUserId is String) {
      currentUserId = int.tryParse(rawUserId);
    }

    if (!context.mounted) return;

    if (currentUserId != null && currentUserId == postUserId) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtherProfileScreen(userId: postUserId),
        ),
      );
    }
  }

  Future<void> _openReportSheet() async {
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportPostSheet(postId: postId),
    );

    if (!mounted || message == null || message.trim().isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openShareUsersSheet() async {
    final currentPost = postManager.getPostAnywhereOrNull(postId) ?? widget.post;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SharePostUsersSheet(post: currentPost),
    );

    if (!mounted || result != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You have shared the post in the chat.'),
      ),
    );
  }

  Widget _buildInfoBadge({
    required String label,
    required IconData icon,
    required Color textColor,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: postManager,
      builder: (context, _) {
        final post = postManager.getPostAnywhereOrNull(postId) ?? widget.post;

        final shareCount = post.shareCount;
        final postUserId = post.accountId;
        final userName =
        post.userName.trim().isNotEmpty ? post.userName : 'User';
        final avatarUrl =
        (post.avatarUrl != null && post.avatarUrl!.trim().isNotEmpty)
            ? post.avatarUrl!
            : 'assets/images/default_avatar.png';

        final title = (post.title ?? '').trim();
        final content = (post.content ?? '').trim();
        final images = post.imageUrls;
        final likeCount = post.likeCount;
        final commentCount = post.commentCount;
        final isLiked = post.isLiked;
        final isSaved = post.isSaved;
        final createdAt = _timeAgo(post.createdAt);
        final bool hideMenu = widget.isMyPost && post.isEvent;
        return Container(
          color: AppColors.background,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(
                context: context,
                userName: userName,
                avatarUrl: avatarUrl,
                createdAt: createdAt,
                status: post.status,
                hideMenu: hideMenu,
                postUserId: postUserId,
                isExpertPost: post.isExpertPost,
                isLikedByExpert: post.isLikedByExpert,
              ),

              if (title.isNotEmpty || content.isNotEmpty)
                _buildCaption(
                  title: title,
                  content: content,
                ),

              if (images.isNotEmpty)
                _buildImageSlider(
                  images: images,
                  isLiked: isLiked,
                  isEvent: post.isEvent,
                  eventName: post.eventName,
                ),

              _buildActions(
                isLiked: isLiked,
                isSaved: isSaved,
                likeCount: likeCount,
                commentCount: commentCount,
                shareCount: shareCount,
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(
                  color: Colors.white,
                  height: 0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBanner(String? status) {
    final statusText = postManager.getMyPostStatusText(status);
    final statusColor = postManager.getMyPostStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader({
    required BuildContext context,
    required String userName,
    required String avatarUrl,
    required String createdAt,
    required int postUserId,
    required bool isExpertPost,
    required bool isLikedByExpert,
    String? status,
    required bool hideMenu,
  }) {
    final bool canOpenProfile = postUserId > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: canOpenProfile
                  ? () => _handleProfileNavigation(context, postUserId)
                  : null,
              onLongPress: (!widget.isMyPost && canOpenProfile)
                  ? _openUserPublicWardrobe
                  : null,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white10,
                    backgroundImage: avatarUrl.startsWith('http')
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: !avatarUrl.startsWith('http')
                        ? ClipOval(
                      child: Image.asset(
                        avatarUrl,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white),
                      ),
                    )
                        : null,
                    onBackgroundImageError: avatarUrl.startsWith('http')
                        ? (exception, stackTrace) {
                      debugPrint('Avatar load error: $exception');
                    }
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            decoration: canOpenProfile
                                ? TextDecoration.underline
                                : null,
                            decorationColor: Colors.white38,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              createdAt,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                            if (isExpertPost) _buildInfoBadge(
                              label: 'Expert',
                              icon: Icons.workspace_premium_rounded,
                              textColor: const Color(0xFFB388FF),
                              bgColor: const Color(0xFFB388FF).withOpacity(0.12),
                              borderColor: const Color(0xFFB388FF).withOpacity(0.28),
                            ),
                            if (isLikedByExpert) _buildInfoBadge(
                              label: 'Expert liked',
                              icon: Icons.favorite_rounded,
                              textColor: const Color(0xFFFF8A65),
                              bgColor: const Color(0xFFFF8A65).withOpacity(0.12),
                              borderColor: const Color(0xFFFF8A65).withOpacity(0.28),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.isMyPost && status != null) ...[
            _buildStatusBanner(status),
            const SizedBox(width: 8),
          ],
          if (!hideMenu)
            IconButton(
              splashRadius: 20,
              icon: const Icon(
                Icons.more_horiz,
                color: AppColors.textSecondary,
                size: 22,
              ),
              onPressed: () => _showPostOptions(context, status),
            ),
        ],
      ),
    );
  }

  Widget _buildCaption({
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          if (title.isNotEmpty && content.isNotEmpty) const SizedBox(height: 6),
          if (content.isNotEmpty)
            Text(
              content,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                height: 1.45,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageSlider({
    required List<String> images,
    required bool isLiked,
    bool isEvent = false,
    String? eventName,
  }) {
    return GestureDetector(
      onDoubleTap: () async {
        try {
          if (!isLiked) {
            await postManager.toggleLikePost(postId);
          }

          if (!mounted) return;
          setState(() => showHeart = true);

          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) {
              setState(() => showHeart = false);
            }
          });
        } catch (e) {
          _showError('Like post failed: $e');
        }
      },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: 4 / 5,
            child: PageView.builder(
              controller: _pageController,
              itemCount: images.length,
              onPageChanged: (index) {
                if (mounted) {
                  setState(() => currentPage = index);
                }
              },
              itemBuilder: (_, index) {
                return CachedNetworkImage(
                  imageUrl: images[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (_, __) => Container(
                    color: Colors.white10,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(
                      color: AppColors.textPink,
                      strokeWidth: 2.4,
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.white10,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white38,
                      size: 36,
                    ),
                  ),
                );
              },
            ),
          ),
          if (isEvent && eventName != null)
            Positioned(
              top: 12,
              left: 12,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.event_repeat, color: AppColors.textPink, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          eventName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (showHeart)
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.6, end: 1.15),
              duration: const Duration(milliseconds: 260),
              builder: (_, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: 0.92,
                    child: child,
                  ),
                );
              },
              child: const Icon(
                Icons.favorite,
                color: Colors.white,
                size: 110,
              ),
            ),

          if (images.length > 1)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${currentPage + 1}/${images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
        ),
    );
  }

  Widget _buildActions({
    required bool isLiked,
    required bool isSaved,
    required int likeCount,
    required int commentCount,
    required int shareCount,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildActionIcon(
                onTap: () async {
                  try {
                    await postManager.toggleLikePost(postId);
                  } catch (e) {
                    _showError('Like post failed: $e');
                  }
                },
                icon: isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.redAccent : AppColors.textPrimary,
              ),
              const SizedBox(width: 14),
              _buildActionIcon(
                onTap: _openComments,
                icon: Icons.mode_comment_outlined,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: 14),
              _buildActionIcon(
                onTap: _openShareUsersSheet,
                icon: Icons.send_outlined,
                color: AppColors.textPrimary,
              ),
              const Spacer(),
              _buildActionIcon(
                onTap: () async {
                  try {
                    await postManager.toggleSavePost(postId);
                    widget.onRefresh?.call();
                  } catch (e) {
                    _showError('Save post failed: $e');
                  }
                },
                icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: isSaved ? AppColors.textPink : AppColors.textPrimary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (likeCount > 0)
            Text(
              '$likeCount likes',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (commentCount > 0) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: _openComments,
              child: Text(
                'View all $commentCount comments',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
          if (shareCount > 0) ...[
            const SizedBox(height: 4),
            Text(
              '$shareCount shares',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionIcon({
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          color: color,
          size: 25,
        ),
      ),
    );
  }

  Future<void> _openComments() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          expand: false,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
              ),
              child: CommentSheet(
                postId: postId,
                scrollController: controller,
              ),
            );
          },
        );
      },
    );

    try {
      await postManager.refreshPostById(postId);
      widget.onRefresh?.call();
    } catch (e) {
      debugPrint('Refresh post after comment sheet closed error: $e');
    }
  }

  String _timeAgo(DateTime? date) {
    if (date == null) return '';
    final utcDate = date.isUtc ? date : DateTime.parse('${date.toIso8601String()}Z');
    // Chuyển đổi sang giờ Local (nếu server trả về UTC)
    final localDate = utcDate.toLocal();
    final now = DateTime.now();
    final diff = now.difference(localDate);

    if (diff.isNegative || diff.inSeconds < 30) return 'Just now';

    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';

    if (diff.inHours < 24) return '${diff.inHours}h ago';

    if (diff.inDays < 7) return '${diff.inDays}d ago';

    // Nếu quá 7 ngày thì hiện ngày tháng cụ thể
    return DateFormat('dd/MM/yyyy').format(localDate);
  }

  void _showPostOptions(BuildContext context, String? status) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.only(bottom: 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (widget.isMyPost) ...[
                if (_canEditPost(status))
                  ListTile(
                    leading: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.textPrimary,
                    ),
                    title: const Text(
                      "Edit Post",
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreatePostScreen(
                            postToEdit: {
                              'postId': widget.post.postId,
                              'title': widget.post.title,
                              'content': widget.post.content,
                              'imageUrls': widget.post.images,
                              'status': widget.post.status,
                              'visibility': widget.post.visibility,
                            },
                          ),
                        ),
                      ).then((_) {
                        widget.onRefresh?.call();
                      });
                    },
                  ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    "Delete Post",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 16,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showDeleteConfirmDialog(context);
                  },
                ),
              ] else ...[
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.report_gmailerrorred_rounded,
                      color: Colors.redAccent,
                      size: 22,
                    ),
                  ),
                  title: const Text(
                    "Report Post",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: const Text(
                    "I am concerned about this post",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _openReportSheet();
                  },
                ),
                const Divider(
                  color: Colors.white10,
                  indent: 16,
                  endIndent: 16,
                ),
                ListTile(
                  leading: const Icon(
                    Icons.visibility_off_outlined,
                    color: AppColors.textPrimary,
                  ),
                  title: const Text(
                    "Not interested",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  onTap: () => Navigator.pop(ctx),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext parentContext) {
    showDialog(
      context: parentContext,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text(
          "Delete post?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Are you sure you want to delete this post? This action cannot be undone.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await postManager.deleteMyPost(postId);
                widget.onRefresh?.call();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete post: $e'),
                  ),
                );
              }
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}