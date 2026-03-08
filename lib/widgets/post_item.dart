import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'package:intl/intl.dart';

import '../screens/create_post_screens.dart';
class PostItem extends StatelessWidget {
  final Map<String, dynamic> postData;
  final bool isMyPost;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PostItem({
    super.key,
    required this.postData,
    this.isMyPost = false,
    this.onEdit,
    this.onDelete,});

  @override
  Widget build(BuildContext context) {
    final String userName = postData['userName'] ?? "User";
    final String avatarUrl = postData['avatarUrl'] ?? 'https://i.pravatar.cc/150?img=8';
    final String title = postData['title'] ?? "";
    final String content = postData['content'] ?? "";
    final List<dynamic> imageUrls = postData['imageUrls'] ?? [];

    String timeAgo = "Mới đây";
    if (postData['createdAt'] != null) {
      DateTime dt = DateTime.parse(postData['createdAt']);
      timeAgo = DateFormat('dd/MM/yyyy HH:mm').format(dt);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Avatar và Tên
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(avatarUrl)
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        userName,
                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)
                    ),
                    Text(
                        timeAgo,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: AppColors.textSecondary),
                  onPressed: () => _showPostOptions(context),
                )
              ],
            ),
          ),

          // 2. Nội dung văn bản (Title và Content)
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
                        fontWeight: FontWeight.bold
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),

          // 3. Hình ảnh bài viết
          // 3. Hình ảnh bài viết (Hỗ trợ nhiều ảnh)
          if (imageUrls.isNotEmpty)
            Column(
              children: [
                SizedBox(
                  height: 400, // Bạn có thể dùng AspectRatio như cũ nếu muốn
                  child: PageView.builder(
                    itemCount: imageUrls.length,
                    controller: PageController(viewportFraction: 0.95), // Hiển thị mờ mép ảnh tiếp theo
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

                // Hiển thị số lượng ảnh nếu có > 1 ảnh
                if (imageUrls.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      "Vuốt để xem thêm (${imageUrls.length} ảnh)",
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ),
              ],
            ),

          // 4. Các nút tương tác (Like, Comment)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _interaction(Icons.favorite_rounded, postData['likeCount']?.toString() ?? "0"),
                const SizedBox(width: 24),
                _interaction(Icons.mode_comment_rounded, "0"),
                const Spacer(),
                const Icon(Icons.bookmark_border_rounded, color: AppColors.textSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _interaction(IconData icon, String count) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 24),
        const SizedBox(width: 6),
        Text(count, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ],
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
              if (isMyPost) ...[
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: AppColors.textPrimary),
                  title: const Text(
                    "Chỉnh sửa bài viết",
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreatePostScreen(
                          postToEdit: postData,
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: const Text(
                    "Xóa bài viết",
                    style: TextStyle(color: Colors.redAccent, fontSize: 16),
                  ),
                  onTap: () {
                    Navigator.pop(context);
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
                    child: const Icon(Icons.report_gmailerrorred_rounded, color: Colors.redAccent, size: 22),
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
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Đã gửi báo cáo")),
                    );
                  },
                ),
                const Divider(color: Colors.white10, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.visibility_off_outlined, color: AppColors.textPrimary),
                  title: const Text(
                    "Không quan tâm",
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                  ),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text("Xóa bài viết?", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Bạn có chắc chắn muốn xóa bài viết này không? Hành động này không thể hoàn tác.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (onDelete != null) onDelete!();
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}