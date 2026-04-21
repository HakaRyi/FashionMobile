import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../managers/comment_manager.dart';
import '../../models/comment_model.dart';
import 'reply_item.dart';

class CommentItem extends StatelessWidget {
  final CommentModel comment;

  const CommentItem({
    super.key,
    required this.comment,
  });

  DateTime? _parseUtcToLocal(dynamic raw) {
    if (raw == null) return null;

    try {
      String value = raw.toString().trim();
      if (value.isEmpty) return null;

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
    if (localDate == null) return '';

    final now = DateTime.now();
    final diff = now.difference(localDate);

    if (diff.isNegative || diff.inSeconds < 30) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} m';
    if (diff.inHours < 24) return '${diff.inHours} h';
    if (diff.inDays < 7) return '${diff.inDays} d';

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

    final String replyLabel = _buildReplyLabel(
      hasReplies: hasReplies,
      replyCount: comment.replyCount,
      expanded: repliesExpanded,
    );

    final String timeText = _formatTime(comment.createdAt);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: AppColors.backgroundSecondary,
                backgroundImage:
                comment.avatarUrl != null && comment.avatarUrl!.isNotEmpty
                    ? NetworkImage(comment.avatarUrl!)
                    : null,
                child: (comment.avatarUrl == null || comment.avatarUrl!.isEmpty)
                    ? const Icon(
                  Icons.person,
                  size: 16,
                  color: AppColors.textSecondary,
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
                        color: AppColors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.divider.withOpacity(0.8),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            comment.content,
                            style: const TextStyle(
                              fontSize: 14.5,
                              height: 1.35,
                              color: AppColors.textPrimary,
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
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          GestureDetector(
                            onTap: manager.isLikingComment(comment.commentId)
                                ? null
                                : () => manager.toggleLike(comment),
                            child: Text(
                              comment.isLiked ? "Liked" : "Like",
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: comment.isLiked
                                    ? Colors.redAccent
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: isSubmittingReply
                                ? null
                                : () => _showReplyInput(context, manager),
                            child: Text(
                              isSubmittingReply ? "Replying..." : "Reply",
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          if (hasReplies)
                            GestureDetector(
                              onTap: () => manager.toggleReplies(comment),
                              child: Text(
                                replyLabel,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: manager.isLikingComment(comment.commentId)
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
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : Icon(
                        comment.isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 18,
                        color: comment.isLiked
                            ? Colors.redAccent
                            : Colors.grey,
                      ),
                      if (comment.likeCount > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          "${comment.likeCount}",
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (loadingReplies && comment.replies.isEmpty)
            const Padding(
              padding: EdgeInsets.only(left: 44, top: 8),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
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
                            ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Loading more replies...",
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        )
                            : const Text(
                          "See more replies",
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
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
    );
  }

  String _buildReplyLabel({
    required bool hasReplies,
    required int replyCount,
    required bool expanded,
  }) {
    if (!hasReplies) return "Reply";

    if (expanded) {
      if (replyCount <= 0) return "Hide reply";
      if (replyCount == 1) return "Hide reply";
      return "Hide reply";
    }

    if (replyCount <= 0) return "View reply";
    if (replyCount == 1) return "View reply";
    return "View $replyCount replies";
  }

  void _showReplyInput(BuildContext context, CommentManager manager) {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return _ReplyInputSheet(
          comment: comment,
          controller: controller,
          manager: manager,
        );
      },
    );
  }
}

class _ReplyInputSheet extends StatefulWidget {
  final CommentModel comment;
  final TextEditingController controller;
  final CommentManager manager;

  const _ReplyInputSheet({
    required this.comment,
    required this.controller,
    required this.manager,
  });

  @override
  State<_ReplyInputSheet> createState() => _ReplyInputSheetState();
}

class _ReplyInputSheetState extends State<_ReplyInputSheet> {
  Future<void> _submit() async {
    final text = widget.controller.text.trim();
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

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 14,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppColors.divider,
                    ),
                  ),
                  child: TextField(
                    controller: widget.controller,
                    minLines: 1,
                    maxLines: 4,
                    autofocus: true,
                    enabled: !submitting,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: submitting
                          ? "Replying..."
                          : "Reply ${widget.comment.userName}...",
                      hintStyle: const TextStyle(
                        color: AppColors.textSecondary,
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
                      ? Colors.grey.shade400
                      : AppColors.textPink,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: submitting
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.send_rounded, color: Colors.white),
                  onPressed: submitting ? null : _submit,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}