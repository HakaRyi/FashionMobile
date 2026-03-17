import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../constants/app_colors.dart';
import '../models/post_feed_model.dart';
import '../managers/post_manager.dart';
import '../widgets/comments/comment_sheet.dart';

class PostItem extends StatefulWidget {
  final PostFeedModel post;
  final bool isMyPost;

  const PostItem({
    super.key,
    required this.post,
    this.isMyPost = false,
  });

  @override
  State<PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  late final int postId;

  int currentPage = 0;
  bool showHeart = false;

  @override
  void initState() {
    super.initState();
    postId = widget.post.postId;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: postManager,
      builder: (context, _) {
        final post = postManager.getPostOrNull(postId) ?? widget.post;

        final userName = post.userName;
        final avatarUrl =
        (post.avatarUrl != null && post.avatarUrl!.trim().isNotEmpty)
            ? post.avatarUrl!
            : 'https://i.pravatar.cc/150?img=8';

        final title = (post.title ?? '').trim();
        final content = post.content ?? '';
        final images = post.imageUrls;
        final likeCount = post.likeCount;
        final commentCount = post.commentCount;
        final isLiked = post.isLiked;
        final isSaved = post.isSaved;
        final createdAt = _timeAgo(post.createdAt);

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey[800],
                      backgroundImage: NetworkImage(avatarUrl),
                      onBackgroundImageError: (_, __) {},
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                    IconButton(
                      icon: const Icon(
                        Icons.more_horiz,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => _showPostOptions(context),
                    ),
                  ],
                ),
              ),

              if (title.isNotEmpty || content.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title.isNotEmpty)
                        Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      if (title.isNotEmpty && content.trim().isNotEmpty)
                        const SizedBox(height: 4),
                      if (content.trim().isNotEmpty)
                        Text(
                          content,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            height: 1.4,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),

              if (images.isNotEmpty)
                GestureDetector(
                  onDoubleTap: () {
                    if (!isLiked) {
                      postManager.toggleLike(postId);
                    }

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
                      SizedBox(
                        height: 400,
                        child: PageView.builder(
                          itemCount: images.length,
                          onPageChanged: (i) {
                            if (mounted) {
                              setState(() => currentPage = i);
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
                          tween: Tween<double>(begin: 0.5, end: 1.2),
                          duration: const Duration(milliseconds: 300),
                          builder: (_, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: child,
                            );
                          },
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 120,
                          ),
                        ),
                    ],
                  ),
                ),

              if (images.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      images.length,
                          (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == currentPage ? Colors.white : Colors.white24,
                        ),
                      ),
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => postManager.toggleLike(postId),
                      borderRadius: BorderRadius.circular(20),
                      child: Row(
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(
                              begin: 0.9,
                              end: isLiked ? 1.2 : 1,
                            ),
                            duration: const Duration(milliseconds: 200),
                            builder: (_, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: child,
                              );
                            },
                            child: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : AppColors.textSecondary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            likeCount.toString(),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    InkWell(
                      onTap: () {
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
                                      top: Radius.circular(20),
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
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.mode_comment_rounded,
                            color: AppColors.textSecondary,
                            size: 24,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            commentCount.toString(),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    const Icon(
                      Icons.send_outlined,
                      color: AppColors.textSecondary,
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => postManager.toggleSave(postId),
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(scale: animation, child: child);
                        },
                        child: Icon(
                          isSaved ? Icons.bookmark : Icons.bookmark_border,
                          key: ValueKey(isSaved),
                          color: isSaved
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _timeAgo(DateTime? date) {
    if (date == null) return '';

    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';

    return '${date.day}/${date.month}';
  }

  void _showPostOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              if (widget.isMyPost)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    'Xóa bài viết',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () async {
                    Navigator.pop(context);

                    try {
                      await postManager.deleteMyPost(postId);
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Xóa bài thất bại: $e')),
                      );
                    }
                  },
                )
              else
                ListTile(
                  leading: const Icon(
                    Icons.report_gmailerrorred_rounded,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    'Báo cáo bài viết',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () {
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tính năng báo cáo đang được hoàn thiện'),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}