import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../managers/comment_manager.dart';
import '../../models/comment_model.dart';
import 'edit_comment_sheet.dart';
import 'reply_item.dart';

class CommentItem extends StatelessWidget {
  final CommentModel comment;

  const CommentItem({
    super.key,
    required this.comment,
  });

  DateTime? _parseUtcToLocal(dynamic raw) {
    if (raw == null) {
      return null;
    }

    try {
      String value = raw.toString().trim();

      if (value.isEmpty) {
        return null;
      }

      if (!value.endsWith('Z') && !value.contains('+')) {
        value += 'Z';
      }

      return DateTime.parse(value).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _formatTime(dynamic rawCreatedAt) {
    final localDate = _parseUtcToLocal(rawCreatedAt);

    if (localDate == null) {
      return '';
    }

    final now = DateTime.now();
    final diff = now.difference(localDate);

    if (diff.isNegative || diff.inSeconds < 30) {
      return 'Just now';
    }

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    }

    if (diff.inHours < 24) {
      return '${diff.inHours}h';
    }

    if (diff.inDays < 7) {
      return '${diff.inDays}d';
    }

    return DateFormat('dd/MM/yyyy • HH:mm').format(localDate);
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<CommentManager>();

    final bool repliesExpanded = manager.isRepliesExpanded(comment.commentId);
    final bool loadingReplies = manager.isLoadingReplies(comment.commentId);
    final bool hasReplies = manager.hasRepliesFor(comment.commentId);
    final bool hasMoreReplies = manager.hasMoreRepliesFor(comment.commentId);
    final bool isSubmittingReply = manager.isSubmittingReply(comment.commentId);
    final bool isDeleting = manager.isDeletingComment(comment.commentId);
    final bool isUpdating = manager.isUpdatingComment(comment.commentId);

    final String replyLabel = _buildReplyLabel(
      hasReplies: hasReplies,
      replyCount: comment.replyCount,
      expanded: repliesExpanded,
    );

    final String timeText = _formatTime(comment.createdAt);

    return Opacity(
      opacity: isDeleting ? 0.45 : 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: const Color(0xFFF1F1F1),
                  backgroundImage:
                  comment.avatarUrl != null && comment.avatarUrl!.isNotEmpty
                      ? NetworkImage(comment.avatarUrl!)
                      : null,
                  child: comment.avatarUrl == null || comment.avatarUrl!.isEmpty
                      ? const Icon(
                    Icons.person,
                    size: 16,
                    color: Colors.black26,
                  )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7F7),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.black.withOpacity(0.05),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              comment.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13.5,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              comment.content,
                              style: const TextStyle(
                                fontSize: 14.5,
                                height: 1.35,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Wrap(
                          spacing: 14,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (timeText.isNotEmpty)
                              Text(
                                timeText,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black45,
                                ),
                              ),
                            GestureDetector(
                              onTap: manager.isLikingComment(comment.commentId) ||
                                  isDeleting
                                  ? null
                                  : () => manager.toggleLike(comment),
                              child: Text(
                                comment.isLiked ? 'Liked' : 'Like',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: comment.isLiked
                                      ? Colors.redAccent
                                      : Colors.black45,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: isSubmittingReply || isDeleting
                                  ? null
                                  : () => _showReplyInput(context, manager),
                              child: Text(
                                isSubmittingReply ? 'Replying...' : 'Reply',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black45,
                                ),
                              ),
                            ),
                            if (hasReplies)
                              GestureDetector(
                                onTap: isDeleting
                                    ? null
                                    : () => manager.toggleReplies(comment),
                                child: Text(
                                  replyLabel,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black45,
                                  ),
                                ),
                              ),
                            if (isUpdating)
                              const Text(
                                'Updating...',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black38,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: manager.isLikingComment(comment.commentId) ||
                          isDeleting
                          ? null
                          : () => manager.toggleLike(comment),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Column(
                          children: [
                            manager.isLikingComment(comment.commentId)
                                ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                                : Icon(
                              comment.isLiked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 18,
                              color: comment.isLiked
                                  ? Colors.redAccent
                                  : Colors.black38,
                            ),
                            if (comment.likeCount > 0) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${comment.likeCount}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black45,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      enabled: !isDeleting && !isUpdating,
                      icon: const Icon(
                        Icons.more_horiz,
                        color: Colors.black38,
                        size: 20,
                      ),
                      color: Colors.white,
                      surfaceTintColor: Colors.transparent,
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditCommentSheet(context, manager);
                        }

                        if (value == 'delete') {
                          _confirmDeleteComment(context, manager);
                        }
                      },
                      itemBuilder: (_) {
                        return const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: Colors.black,
                                ),
                                SizedBox(width: 10),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: Colors.redAccent,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ];
                      },
                    ),
                  ],
                ),
              ],
            ),
            if (loadingReplies && comment.replies.isEmpty)
              const Padding(
                padding: EdgeInsets.only(left: 44, top: 8),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                ),
              ),
            if (repliesExpanded && comment.replies.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 44, top: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...comment.replies.map((e) => ReplyItem(reply: e)),
                    if (hasMoreReplies) ...[
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: loadingReplies
                            ? null
                            : () => manager.loadMoreReplies(comment),
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          child: loadingReplies
                              ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Loading more replies...',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black45,
                                ),
                              ),
                            ],
                          )
                              : const Text(
                            'See more replies',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.black45,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _buildReplyLabel({
    required bool hasReplies,
    required int replyCount,
    required bool expanded,
  }) {
    if (!hasReplies) {
      return 'Reply';
    }

    if (expanded) {
      return 'Hide replies';
    }

    if (replyCount <= 1) {
      return 'View reply';
    }

    return 'View $replyCount replies';
  }

  void _showEditCommentSheet(
      BuildContext context,
      CommentManager manager,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return EditCommentSheet(
          title: 'Edit comment',
          initialText: comment.content,
          isSubmitting: () => manager.isUpdatingComment(comment.commentId),
          onSubmit: (text) async {
            return manager.updateCommentContent(
              commentId: comment.commentId,
              content: text,
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteComment(
      BuildContext context,
      CommentManager manager,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Delete comment?',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'This comment and its replies will be removed.',
            style: TextStyle(
              color: Colors.black54,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'CANCEL',
                style: TextStyle(
                  color: Colors.black45,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'DELETE',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final success = await manager.deleteCommentById(comment.commentId);

    if (!context.mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete comment.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showReplyInput(BuildContext context, CommentManager manager) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return _ReplyInputSheet(
          comment: comment,
          manager: manager,
        );
      },
    );
  }
}

class _ReplyInputSheet extends StatefulWidget {
  final CommentModel comment;
  final CommentManager manager;

  const _ReplyInputSheet({
    required this.comment,
    required this.manager,
  });

  @override
  State<_ReplyInputSheet> createState() => _ReplyInputSheetState();
}

class _ReplyInputSheetState extends State<_ReplyInputSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();

    if (text.isEmpty ||
        widget.manager.isSubmittingReply(widget.comment.commentId)) {
      return;
    }

    await widget.manager.createReply(widget.comment, text);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.manager,
      builder: (_, __) {
        final submitting =
        widget.manager.isSubmittingReply(widget.comment.commentId);

        return PopScope(
          canPop: !submitting,
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 120),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7F7),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.black.withOpacity(0.06),
                          ),
                        ),
                        child: TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 4,
                          autofocus: true,
                          enabled: !submitting,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _submit(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: submitting
                                ? 'Replying...'
                                : 'Reply ${widget.comment.userName}...',
                            hintStyle: const TextStyle(
                              color: Colors.black38,
                              fontWeight: FontWeight.w500,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: submitting
                            ? const Color(0xFFE0E0E0)
                            : Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: submitting
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                            : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                        ),
                        onPressed: submitting ? null : _submit,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}