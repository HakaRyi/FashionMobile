import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../managers/post_manager.dart';
import '../models/my_post_model.dart';

class MyPostItem extends StatelessWidget {
  final MyPostModel post;
  final VoidCallback? onEdit;

  const MyPostItem({
    super.key,
    required this.post,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final statusText = postManager.getMyPostStatusText(post.status);
    final statusStyle = _getStatusStyle(post.status);

    return Container(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(statusText, statusStyle),
          if (post.images.isNotEmpty) _buildImageSection(),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildActionRow(),
                const SizedBox(height: 10),
                _buildTitle(),
                if ((post.content ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _buildCaption(),
                ],
                const SizedBox(height: 10),
                _buildMetaRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String statusText, _PostStatusStyle style) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.purpleAccent, Colors.pinkAccent],
              ),
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.surface,
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              post.title?.trim().isNotEmpty == true
                  ? post.title!
                  : 'Bài viết #${post.postId}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildStatusChip(statusText, style),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 4 / 5,
          child: Image.network(
            post.images.first,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.white10,
              alignment: Alignment.center,
              child: const Icon(
                Icons.broken_image_outlined,
                color: Colors.white38,
                size: 40,
              ),
            ),
          ),
        ),
        if (post.images.length > 1)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.collections_outlined,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${post.images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionRow() {
    final actions = <Widget>[
      if (post.canEdit)
        _buildActionButton(
          icon: Icons.edit_outlined,
          label: 'Sửa',
          onTap: onEdit,
          isPrimary: true,
        ),
      if (post.canHide)
        _buildActionButton(
          icon: Icons.visibility_off_outlined,
          label: 'Ẩn',
          onTap: () async {
            try {
              await postManager.hideMyPost(post.postId);
            } catch (_) {}
          },
        ),
      if (post.canUnhide)
        _buildActionButton(
          icon: Icons.visibility_outlined,
          label: 'Hiện',
          onTap: () async {
            try {
              await postManager.unhideMyPost(post.postId);
            } catch (_) {}
          },
        ),
      if (post.canDelete)
        _buildActionButton(
          icon: Icons.delete_outline_rounded,
          label: 'Xóa',
          onTap: () async {
            try {
              await postManager.deleteMyPost(post.postId);
            } catch (_) {}
          },
          isDanger: true,
        ),
    ];

    if (actions.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: actions,
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool isPrimary = false,
    bool isDanger = false,
  }) {
    final bgColor = isPrimary
        ? Colors.pink
        : isDanger
        ? Colors.redAccent.withOpacity(0.14)
        : Colors.white.withOpacity(0.06);

    final fgColor = isPrimary
        ? Colors.white
        : isDanger
        ? const Color(0xFFFF9A9A)
        : AppColors.textPrimary;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: fgColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: fgColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    final title = post.title?.trim();
    if (title == null || title.isEmpty) {
      return const SizedBox.shrink();
    }

    return Text(
      title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 1.35,
      ),
    );
  }

  Widget _buildCaption() {
    return Text(
      post.content!,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.white.withOpacity(0.82),
        fontSize: 13.5,
        height: 1.5,
      ),
    );
  }

  Widget _buildMetaRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildMetaChip(
          icon: post.isPubliclyVisible
              ? Icons.public
              : Icons.lock_outline_rounded,
          text: post.isPubliclyVisible ? 'Công khai' : 'Riêng tư',
        ),
        _buildMetaChip(
          icon: Icons.visibility_outlined,
          text: post.visibility,
        ),
        _buildMetaChip(
          icon: Icons.tag,
          text: '#${post.postId}',
        ),
      ],
    );
  }

  Widget _buildMetaChip({
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String text, _PostStatusStyle style) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: style.textColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  _PostStatusStyle _getStatusStyle(String? status) {
    final value = (status ?? '').toLowerCase();

    if (value == 'published') {
      return _PostStatusStyle(
        backgroundColor: const Color(0xFF22C55E).withOpacity(0.16),
        textColor: const Color(0xFF86EFAC),
      );
    }

    if (value == 'verifying' || value == 'draft') {
      return _PostStatusStyle(
        backgroundColor: const Color(0xFFF59E0B).withOpacity(0.16),
        textColor: const Color(0xFFFCD34D),
      );
    }

    if (value == 'airejected' ||
        value == 'rejected' ||
        value == 'blockedbyadmin') {
      return _PostStatusStyle(
        backgroundColor: const Color(0xFFEF4444).withOpacity(0.16),
        textColor: const Color(0xFFFCA5A5),
      );
    }

    if (value == 'hiddenbyowner') {
      return _PostStatusStyle(
        backgroundColor: const Color(0xFF64748B).withOpacity(0.16),
        textColor: const Color(0xFFCBD5E1),
      );
    }

    return _PostStatusStyle(
      backgroundColor: Colors.white.withOpacity(0.08),
      textColor: AppColors.textPrimary,
    );
  }
}

class _PostStatusStyle {
  final Color backgroundColor;
  final Color textColor;

  _PostStatusStyle({
    required this.backgroundColor,
    required this.textColor,
  });
}