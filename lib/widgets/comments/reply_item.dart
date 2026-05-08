import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../managers/comment_manager.dart';
import '../../models/comment_reply_model.dart';
import 'edit_comment_sheet.dart';

class ReplyItem extends StatelessWidget {
  final CommentReplyModel reply;

  const ReplyItem({
    super.key,
    required this.reply,
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

    final String timeText = _formatTime(reply.createdAt);
    final bool isUpdating = manager.isUpdatingComment(reply.commentId);
    final bool isDeleting = manager.isDeletingComment(reply.commentId);

    return Opacity(
      opacity: isDeleting ? 0.45 : 1,
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFFF1F1F1),
              backgroundImage:
              reply.avatarUrl != null && reply.avatarUrl!.isNotEmpty
                  ? NetworkImage(reply.avatarUrl!)
                  : null,
              child: reply.avatarUrl == null || reply.avatarUrl!.isEmpty
                  ? const Icon(
                Icons.person,
                size: 14,
                color: Colors.black26,
              )
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7F7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.black.withOpacity(0.05),
                      ),
                    ),
                    child: RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style.copyWith(
                          fontSize: 14,
                          height: 1.35,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          TextSpan(
                            text: '${reply.userName} ',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                          TextSpan(text: reply.content),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        if (timeText.isNotEmpty)
                          Text(
                            timeText,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Colors.black45,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (reply.likeCount > 0)
                          Text(
                            '${reply.likeCount} likes',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Colors.black45,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        if (isUpdating)
                          const Text(
                            'Updating...',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.black38,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              enabled: !isUpdating && !isDeleting,
              icon: const Icon(
                Icons.more_horiz,
                color: Colors.black38,
                size: 19,
              ),
              color: Colors.white,
              surfaceTintColor: Colors.transparent,
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditReplySheet(context, manager);
                }

                if (value == 'delete') {
                  _confirmDeleteReply(context, manager);
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
      ),
    );
  }

  void _showEditReplySheet(
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
          title: 'Edit reply',
          initialText: reply.content,
          isSubmitting: () => manager.isUpdatingComment(reply.commentId),
          onSubmit: (text) async {
            return manager.updateCommentContent(
              commentId: reply.commentId,
              content: text,
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteReply(
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
            'Delete reply?',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'This reply will be removed.',
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

    final success = await manager.deleteCommentById(reply.commentId);

    if (!context.mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete reply.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}