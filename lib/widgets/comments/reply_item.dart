// lib/widgets/comments/reply_item.dart
import 'package:flutter/material.dart';

import '../../models/comment_reply_model.dart';

class ReplyItem extends StatelessWidget {
  final CommentReplyModel reply;

  const ReplyItem({
    super.key,
    required this.reply,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.grey.shade300,
            backgroundImage:
            reply.avatarUrl != null && reply.avatarUrl!.isNotEmpty
                ? NetworkImage(reply.avatarUrl!)
                : null,
            child: (reply.avatarUrl == null || reply.avatarUrl!.isEmpty)
                ? const Icon(Icons.person, size: 14)
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style.copyWith(
                        fontSize: 14,
                        height: 1.35,
                      ),
                      children: [
                        TextSpan(
                          text: "${reply.userName} ",
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: reply.content),
                      ],
                    ),
                  ),
                ),
                if (reply.likeCount > 0) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      "${reply.likeCount} likes",
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
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
}