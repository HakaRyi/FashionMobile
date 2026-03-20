import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../utils/post_manager.dart';
import '../widgets/comment_sheet.dart';

class PostItem extends StatelessWidget {

  final Map<String, dynamic> postData;
  final bool isMyPost;

  const PostItem({
    super.key,
    required this.postData,
    this.isMyPost = false,
  });

  @override
  Widget build(BuildContext context) {

    final int postId = int.parse(postData['postId'].toString());

    final String userName = postData['userName'] ?? "User";

    final String avatarUrl =
        postData['avatarUrl'] ?? 'https://i.pravatar.cc/150?img=8';

    final String title = postData['title'] ?? "";
    final String content = postData['content'] ?? "";

    final List<dynamic> imageUrls = postData['images'] ?? [];

    final int likeCount = postData['likeCount'] ?? 0;
    final int commentCount = postData['commentCount'] ?? 0;

    final bool isLiked = postData['isLiked'] ?? false;

    String timeAgo = "Mới đây";

    if (postData['createdAt'] != null) {
      try {
        DateTime dt = DateTime.parse(postData['createdAt']);
        timeAgo = DateFormat('dd/MM/yyyy HH:mm').format(dt);
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// HEADER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [

                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(avatarUrl),
                ),

                const SizedBox(width: 12),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      userName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Text(
                      timeAgo,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                IconButton(
                  icon: const Icon(
                    Icons.more_horiz,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => _showPostOptions(context),
                )
              ],
            ),
          ),



          /// TEXT CONTENT
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
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                const SizedBox(height: 4),

                Text(
                  content,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),



          /// IMAGE
          if (imageUrls.isNotEmpty)
            SizedBox(
              height: 400,
              child: PageView.builder(
                itemCount: imageUrls.length,
                controller: PageController(viewportFraction: 0.95),
                itemBuilder: (context, index) {

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: DecorationImage(
                        image: NetworkImage(imageUrls[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),



          /// INTERACTION
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [

                /// LIKE
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    postManager.toggleLike(postId);
                  },
                  child: Row(
                    children: [

                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          isLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          key: ValueKey(isLiked),
                          color: isLiked
                              ? Colors.red
                              : AppColors.textSecondary,
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

                /// COMMENT
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {

                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => CommentSheet(postId: postId),
                    );

                  },
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

                const Spacer(),

                /// BOOKMARK
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    // TODO: bookmark feature
                  },
                  child: const Icon(
                    Icons.bookmark_border_rounded,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPostOptions(BuildContext context) {

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {

        return Container(
          padding: const EdgeInsets.only(bottom: 20),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              const SizedBox(height: 10),

              if (isMyPost)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    "Xóa bài viết",
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () {
                    Navigator.pop(context);

                    // TODO: gọi API delete post
                  },
                )
              else
                ListTile(
                  leading: const Icon(
                    Icons.report_gmailerrorred_rounded,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    "Báo cáo bài viết",
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () {
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text("Đã gửi báo cáo"),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}