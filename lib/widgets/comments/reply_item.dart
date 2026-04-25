import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/comment_reply_model.dart';

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
    final String timeText = _formatTime(reply.createdAt);

    return Padding(
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}