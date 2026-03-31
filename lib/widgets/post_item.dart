// lib/widgets/post_item.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/post_status_values.dart';
import '../managers/post_manager.dart';
import '../models/post_feed_model.dart';
import '../screens/create_post_screens.dart';
import '../screens/public_wardrobe_screen.dart';
import 'comments/comment_sheet.dart';

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
  late final int postId;
  final PageController _pageController = PageController();

  int currentPage = 0;
  bool showHeart = false;

  @override
  void initState() {
    super.initState();
    postId = widget.post.postId;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _canEditPost(String? status) {
    final s = status?.toLowerCase();
    return s != PostStatusValues.rejected.toLowerCase() &&
        s != 'airejected' &&
        s != 'blockedbyadmin';
  }

  void _openUserPublicWardrobe() {
    if (widget.post.accountId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy thông tin người dùng.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PublicWardrobeScreen(accountId: widget.post.accountId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: postManager,
      builder: (context, _) {
        final post = postManager.getPostOrNull(postId) ?? widget.post;

        final userName =
        post.userName.trim().isNotEmpty ? post.userName : 'Người dùng';
        final avatarUrl =
        (post.avatarUrl != null && post.avatarUrl!.trim().isNotEmpty)
            ? post.avatarUrl!
            : 'https://i.pravatar.cc/150?img=8';

        final title = (post.title ?? '').trim();
        final content = (post.content ?? '').trim();
        final images = post.imageUrls;
        final likeCount = post.likeCount;
        final commentCount = post.commentCount;
        final isLiked = post.isLiked;
        final isSaved = post.isSaved;
        final createdAt = _timeAgo(post.createdAt);

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
                ),
              _buildActions(
                isLiked: isLiked,
                isSaved: isSaved,
                likeCount: likeCount,
                commentCount: commentCount,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(
                  color: AppColors.divider,
                  height: 1,
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
    String? status,
  }) {
    final bool canOpenProfile = !widget.isMyPost && widget.post.accountId > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: canOpenProfile ? _openUserPublicWardrobe : null,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white10,
              backgroundImage: NetworkImage(avatarUrl),
              onBackgroundImageError: (_, __) {},
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: canOpenProfile ? _openUserPublicWardrobe : null,
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
                      decoration:
                      canOpenProfile ? TextDecoration.underline : null,
                      decorationColor: Colors.white38,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    createdAt,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
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
  }) {
    return GestureDetector(
      onDoubleTap: () async {
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
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: 1,
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
    );
  }

  Widget _buildActions({
    required bool isLiked,
    required bool isSaved,
    required int likeCount,
    required int commentCount,
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
                  await postManager.toggleLikePost(postId);
                },
                icon: isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.redAccent : AppColors.textPrimary,
              ),
              const SizedBox(width: 14),
              _buildActionIcon(
                onTap: () {
                  _openComments();
                },
                icon: Icons.mode_comment_outlined,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: 14),
              _buildActionIcon(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tính năng chia sẻ đang được phát triển'),
                    ),
                  );
                },
                icon: Icons.send_outlined,
                color: AppColors.textPrimary,
              ),
              const Spacer(),
              _buildActionIcon(
                onTap: () async {
                  await postManager.toggleSavePost(postId);
                },
                icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: AppColors.textPrimary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (likeCount > 0)
            Text(
              '$likeCount lượt thích',
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
                'Xem $commentCount bình luận',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
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

  void _openComments() {
    showModalBottomSheet(
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
                color: Color(0xFF121212),
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
  }

  String _timeAgo(DateTime? date) {
    if (date == null) return '';

    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút';
    if (diff.inHours < 24) return '${diff.inHours} giờ';
    if (diff.inDays < 7) return '${diff.inDays} ngày';

    return '${date.day}/${date.month}/${date.year}';
  }

  void _showPostOptions(BuildContext context, String? status) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.only(bottom: 20),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
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
                      "Chỉnh sửa bài viết",
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
                        if (widget.onRefresh != null) {
                          widget.onRefresh!();
                        }
                      });
                    },
                  ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    "Xóa bài viết",
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
                    "Báo cáo bài viết",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: const Text(
                    "Tôi lo ngại về bài viết này",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Đã gửi báo cáo")),
                    );
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
                    "Không quan tâm",
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
          "Xóa bài viết?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Bạn có chắc chắn muốn xóa bài viết này không? Hành động này không thể hoàn tác.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Hủy",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await postManager.deleteMyPost(postId);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(
                    content: Text('Xóa bài thất bại: $e'),
                  ),
                );
              }
            },
            child: const Text(
              "Xóa",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}