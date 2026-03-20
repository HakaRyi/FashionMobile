// lib/widgets/comments/comment_input.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../managers/comment_manager.dart';

class CommentInput extends StatefulWidget {
  const CommentInput({super.key});

  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit(CommentManager manager) async {
    final text = controller.text.trim();
    if (text.isEmpty || manager.isSubmittingComment) return;

    controller.clear();

    try {
      await manager.createComment(text);
    } catch (_) {
      if (mounted && controller.text.trim().isEmpty) {
        controller.text = text;
        controller.selection = TextSelection.fromPosition(
          TextPosition(offset: controller.text.length),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<CommentManager>(
      builder: (_, manager, __) {
        final isSubmitting = manager.isSubmittingComment;

        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.12),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey.shade300,
                  child: const Icon(Icons.person, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: 44,
                      maxHeight: 120,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.14),
                      ),
                    ),
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      minLines: 1,
                      maxLines: 4,
                      enabled: !isSubmitting,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submit(manager),
                      decoration: InputDecoration(
                        hintText: isSubmitting
                            ? "Posting..."
                            : "Add a comment...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isSubmitting
                        ? Colors.grey.shade400
                        : theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: isSubmitting ? null : () => _submit(manager),
                    icon: isSubmitting
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.send_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}