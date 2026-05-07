// lib/widgets/post_item.dart
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../constants/post_status_values.dart';
import '../managers/post_manager.dart';
import '../models/post_feed_model.dart';
import '../screens/create_post_screens.dart';
import '../screens/navbar_screens/profile_screen.dart';
import '../screens/other_profile_screen.dart';
import '../screens/public_wardrobe_screen.dart';
import '../utils/app_toast.dart';
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
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    AppToast.showError(context, message);
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    AppToast.showSuccess(context, message);
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
    final s = status?.trim().toLowerCase();

    if (s == null || s.isEmpty) {
      return true;
    }

    return s != PostStatusValues.verifying.toLowerCase() &&
        s != PostStatusValues.pendingAdmin.toLowerCase() &&
        s != PostStatusValues.deleted.toLowerCase() &&
        s != PostStatusValues.banned.toLowerCase() &&
        s != 'airejected' &&
        s != 'blockedbyadmin';
  }

  bool _canDeletePost(String? status) {
    final s = status?.trim().toLowerCase();

    if (s == null || s.isEmpty) {
      return true;
    }

    return s != PostStatusValues.deleted.toLowerCase() &&
        s != PostStatusValues.banned.toLowerCase();
  }

  void _openUserPublicWardrobe() {
    final currentPost = postManager.getPostAnywhereOrNull(postId) ?? widget.post;

    if (currentPost.accountId <= 0) {
      AppToast.showError(
        context,
        'User information not found.',
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PublicWardrobeScreen(
          accountId: currentPost.accountId,
        ),
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

    if (!context.mounted) {
      return;
    }

    if (currentUserId != null && currentUserId == postUserId) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProfileScreen(),
        ),
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

    if (!mounted || message == null || message.trim().isEmpty) {
      return;
    }

    AppToast.showSuccess(
      context,
      message,
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

    if (!mounted || result != true) {
      return;
    }

    AppToast.showSuccess(
      context,
      'Post shared to chat successfully.',
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
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
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
              fontWeight: FontWeight.w800,
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
        final userName = post.userName.trim().isNotEmpty ? post.userName : 'User';

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
          margin: const EdgeInsets.only(bottom: 10),
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
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
              const Divider(
                color: Color(0xFFF1F1F1),
                height: 1,
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
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: statusColor.withOpacity(0.25),
        ),
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
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
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
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
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
                    radius: 20,
                    backgroundColor: const Color(0xFFF1F1F1),
                    backgroundImage:
                    avatarUrl.startsWith('http') ? NetworkImage(avatarUrl) : null,
                    child: !avatarUrl.startsWith('http')
                        ? ClipOval(
                      child: Image.asset(
                        avatarUrl,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.person,
                            color: Colors.black26,
                          );
                        },
                      ),
                    )
                        : null,
                    onBackgroundImageError: avatarUrl.startsWith('http')
                        ? (exception, stackTrace) {
                      debugPrint('Avatar load error: $exception');
                    }
                        : null,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            decoration: canOpenProfile ? TextDecoration.underline : null,
                            decorationColor: Colors.black26,
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
                                color: Colors.black45,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (isExpertPost)
                              _buildInfoBadge(
                                label: 'Expert',
                                icon: Icons.workspace_premium_rounded,
                                textColor: const Color(0xFF7C3AED),
                                bgColor: const Color(0xFF7C3AED).withOpacity(0.10),
                                borderColor: const Color(0xFF7C3AED).withOpacity(0.22),
                              ),
                            if (isLikedByExpert)
                              _buildInfoBadge(
                                label: 'Expert liked',
                                icon: Icons.favorite_rounded,
                                textColor: const Color(0xFFEA580C),
                                bgColor: const Color(0xFFEA580C).withOpacity(0.10),
                                borderColor: const Color(0xFFEA580C).withOpacity(0.22),
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
                color: Colors.black45,
                size: 23,
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
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                height: 1.3,
              ),
            ),
          if (title.isNotEmpty && content.isNotEmpty) const SizedBox(height: 6),
          if (content.isNotEmpty)
            Text(
              content,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w500,
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

          if (!mounted) {
            return;
          }

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
        padding: const EdgeInsets.symmetric(vertical: 6),
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
                      color: const Color(0xFFF1F1F1),
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2.4,
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: const Color(0xFFF1F1F1),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.black26,
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
                  borderRadius: BorderRadius.circular(999),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 8,
                      sigmaY: 8,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.52),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.18),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.event_repeat,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            eventName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
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
                tween: Tween<double>(
                  begin: 0.6,
                  end: 1.15,
                ),
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
                  shadows: [
                    Shadow(
                      color: Colors.black45,
                      blurRadius: 16,
                    ),
                  ],
                ),
              ),
            if (images.length > 1)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${currentPage + 1}/${images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
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
                color: isLiked ? Colors.redAccent : Colors.black,
              ),
              const SizedBox(width: 14),
              _buildActionIcon(
                onTap: _openComments,
                icon: Icons.mode_comment_outlined,
                color: Colors.black,
              ),
              const SizedBox(width: 14),
              _buildActionIcon(
                onTap: _openShareUsersSheet,
                icon: Icons.send_outlined,
                color: Colors.black,
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
                color: Colors.black,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (likeCount > 0)
            Text(
              '$likeCount likes',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          if (commentCount > 0) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: _openComments,
              child: Text(
                'View all $commentCount comments',
                style: const TextStyle(
                  color: Colors.black45,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (shareCount > 0) ...[
            const SizedBox(height: 4),
            Text(
              '$shareCount shares',
              style: const TextStyle(
                color: Colors.black45,
                fontSize: 13,
                fontWeight: FontWeight.w600,
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
      borderRadius: BorderRadius.circular(22),
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
                  top: Radius.circular(24),
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
    if (date == null) {
      return '';
    }

    final utcDate = date.isUtc ? date : DateTime.parse('${date.toIso8601String()}Z');
    final localDate = utcDate.toLocal();
    final now = DateTime.now();
    final diff = now.difference(localDate);

    if (diff.isNegative || diff.inSeconds < 30) {
      return 'Just now';
    }

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    }

    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }

    if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }

    return DateFormat('dd/MM/yyyy').format(localDate);
  }

  void _showPostOptions(BuildContext context, String? status) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ListenableBuilder(
          listenable: postManager,
          builder: (context, _) {
            final bool isDeleting = postManager.isPostDeleting(postId);

            return Container(
              padding: const EdgeInsets.only(bottom: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  if (widget.isMyPost) ...[
                    if (_canEditPost(status))
                      _buildOptionTile(
                        icon: Icons.edit_outlined,
                        title: 'Edit Post',
                        subtitle: 'Update the content or images of this post',
                        iconColor: Colors.black,
                        onTap: isDeleting
                            ? null
                            : () {
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
                    if (_canDeletePost(status))
                      _buildOptionTile(
                        icon: Icons.delete_outline,
                        title: 'Delete Post',
                        subtitle: isDeleting
                            ? 'Deleting this post...'
                            : 'Hide this post from feed and profile',
                        iconColor: Colors.redAccent,
                        onTap: isDeleting
                            ? null
                            : () {
                          Navigator.pop(ctx);
                          _showDeleteConfirmDialog(context);
                        },
                      ),
                  ] else ...[
                    _buildOptionTile(
                      icon: Icons.report_gmailerrorred_rounded,
                      title: 'Report Post',
                      subtitle: 'I am concerned about this post',
                      iconColor: Colors.redAccent,
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _openReportSheet();
                      },
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(
                        color: Color(0xFFF1F1F1),
                        height: 1,
                      ),
                    ),
                    _buildOptionTile(
                      icon: Icons.visibility_off_outlined,
                      title: 'Not interested',
                      subtitle: 'Show fewer posts like this',
                      iconColor: Colors.black,
                      onTap: () => Navigator.pop(ctx),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback? onTap,
  }) {
    final bool isDisabled = onTap == null;

    return Opacity(
      opacity: isDisabled ? 0.45 : 1,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 4,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: iconColor == Colors.redAccent ? Colors.redAccent : Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: Colors.black45,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          color: Colors.black12,
          size: 14,
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext parentContext) {
    showDialog(
      context: parentContext,
      barrierDismissible: !postManager.isPostDeleting(postId),
      builder: (ctx) {
        return ListenableBuilder(
          listenable: postManager,
          builder: (context, _) {
            final bool isDeleting = postManager.isPostDeleting(postId);

            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                'Delete post?',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This post will be removed from your profile and public feed.',
                    style: TextStyle(
                      color: Colors.black54,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You will not see it in your post list after deletion.',
                    style: TextStyle(
                      color: Colors.black38,
                      height: 1.4,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isDeleting) ...[
                    const SizedBox(height: 18),
                    const Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.redAccent,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Deleting post...',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(ctx),
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(
                      color: Colors.black38,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: isDeleting
                      ? null
                      : () async {
                    try {
                      await postManager.deleteMyPost(postId);

                      if (!ctx.mounted) {
                        return;
                      }

                      Navigator.pop(ctx);

                      if (!mounted) {
                        return;
                      }

                      widget.onRefresh?.call();

                      _showMessage('Post deleted successfully.');
                    } catch (e) {
                      if (!mounted) {
                        return;
                      }

                      AppToast.showError(
                        parentContext,
                        'Failed to delete post: $e',
                      );
                    }
                  },
                  child: Text(
                    isDeleting ? 'DELETING...' : 'DELETE',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}