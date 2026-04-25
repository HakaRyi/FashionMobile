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
      if (!_controller.hasClients) {
        return;
      }

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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Comments',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F1F1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${manager.comments.length}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => manager.refresh(widget.postId),
            color: Colors.black,
            backgroundColor: Colors.white,
            child: Builder(
              builder: (_) {
                if (manager.isInitialLoading && manager.comments.isEmpty) {
                  return ListView(
                    controller: _controller,
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 160),
                      Center(
                        child: CircularProgressIndicator(
                          color: Colors.black,
                        ),
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
                        child: Icon(
                          Icons.mode_comment_outlined,
                          size: 50,
                          color: Colors.black26,
                        ),
                      ),
                      SizedBox(height: 12),
                      Center(
                        child: Text(
                          'No comments yet',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black54,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      SizedBox(height: 6),
                      Center(
                        child: Text(
                          'Be the first to comment',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black38,
                            fontWeight: FontWeight.w600,
                          ),
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
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
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