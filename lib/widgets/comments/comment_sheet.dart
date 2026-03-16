// lib/widgets/comments/comment_sheet.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../managers/comment_manager.dart';
import 'comment_input.dart';
import 'comment_item.dart';

class CommentSheet extends StatelessWidget {
  final int postId;
  final ScrollController? scrollController;

  const CommentSheet({
    super.key,
    required this.postId,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CommentManager()..loadComments(postId),
      child: _CommentSheetView(
        postId: postId,
        externalScrollController: scrollController,
      ),
    );
  }
}

class _CommentSheetView extends StatefulWidget {
  final int postId;
  final ScrollController? externalScrollController;

  const _CommentSheetView({
    required this.postId,
    this.externalScrollController,
  });

  @override
  State<_CommentSheetView> createState() => _CommentSheetViewState();
}

class _CommentSheetViewState extends State<_CommentSheetView> {
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();

    _controller = widget.externalScrollController ?? ScrollController();

    _controller.addListener(() {
      if (!_controller.hasClients) return;

      final position = _controller.position;
      if (position.pixels >= position.maxScrollExtent - 250) {
        context.read<CommentManager>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    if (widget.externalScrollController == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<CommentManager>();

    return Column(
      children: [
        Container(
          height: 44,
          alignment: Alignment.center,
          child: Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => manager.refresh(widget.postId),
            child: Builder(
              builder: (_) {
                if (manager.isInitialLoading && manager.comments.isEmpty) {
                  return ListView(
                    controller: _controller,
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 160),
                      Center(
                        child: CircularProgressIndicator(),
                      ),
                    ],
                  );
                }

                if (manager.comments.isEmpty) {
                  return ListView(
                    controller: _controller,
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      Center(
                        child: Text(
                          "No comments yet",
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    ],
                  );
                }

                return ListView.builder(
                  controller: _controller,
                  physics: const AlwaysScrollableScrollPhysics(),
                  keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount:
                  manager.comments.length + (manager.isLoadingMore ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i >= manager.comments.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }

                    return CommentItem(
                      comment: manager.comments[i],
                    );
                  },
                );
              },
            ),
          ),
        ),
        const CommentInput(),
      ],
    );
  }
}