import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/social_service.dart';
import '../utils/post_manager.dart';

class CommentSheet extends StatefulWidget {
  final int postId;

  const CommentSheet({super.key, required this.postId});

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  List comments = [];
  bool loading = true;
  bool sending = false;

  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    loadComments();
  }

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> loadComments() async {
    try {
      final result = await SocialService.getComments(widget.postId);

      if (!mounted) return;

      setState(() {
        comments = result;
        loading = false;
      });
    } catch (e) {
      debugPrint("Load comment error: $e");

      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  Future<void> sendComment() async {
    if (sending) return;

    final text = controller.text.trim();

    if (text.isEmpty) return;

    controller.clear();

    sending = true;

    /// optimistic UI
    final fake = {
      "userName": "Bạn",
      "content": text
    };

    setState(() {
      comments.insert(0, fake);
    });

    if (scrollController.hasClients) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }

    try {
      final result =
      await SocialService.createComment(widget.postId, text);

      if (result != null) {
        setState(() {
          comments[0] = result;
        });

        postManager.increaseCommentCount(widget.postId);
      }
    } catch (e) {
      debugPrint("Send comment error: $e");
    }

    sending = false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),

          const Text(
            "Bình luận",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const Divider(),

          /// COMMENT LIST
          Expanded(
            child: loading
                ? const Center(
                child: CircularProgressIndicator())
                : comments.isEmpty
                ? const Center(
              child: Text(
                "Chưa có bình luận",
                style: TextStyle(color: Colors.white38),
              ),
            )
                : ListView.builder(
              controller: scrollController,
              reverse: true,
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final c = comments[index];

                return ListTile(
                  leading: const CircleAvatar(
                    radius: 16,
                  ),
                  title: Text(
                    c['userName'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    c['content'] ?? '',
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          /// INPUT
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: "Viết bình luận...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  IconButton(
                    icon: sending
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textPink,
                      ),
                    )
                        : const Icon(
                      Icons.send,
                      color: AppColors.textPink,
                    ),
                    onPressed: sendComment,
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}