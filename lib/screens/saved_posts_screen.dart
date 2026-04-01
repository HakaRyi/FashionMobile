// lib/screens/saved_posts_screen.dart
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../managers/post_manager.dart';
import '../models/post_feed_model.dart';
import '../widgets/post_item.dart';

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _scrollController.addListener(_onScroll);
    postManager.addListener(_onManagerChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    postManager.removeListener(_onManagerChanged);
    super.dispose();
  }

  void _onManagerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadInitial() async {
    try {
      await postManager.fetchSavedPosts(refresh: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tải bài đã lưu thất bại: $e')),
      );
    }
  }

  Future<void> _refresh() async {
    await _loadInitial();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 250) {
      postManager.loadMoreSavedPosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<PostFeedModel> posts = postManager.savedPosts;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Bài viết đã lưu',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: postManager.isLoadingSaved && posts.isEmpty
          ? const Center(
        child: CircularProgressIndicator(color: Colors.pink),
      )
          : RefreshIndicator(
        onRefresh: _refresh,
        color: Colors.pink,
        child: posts.isEmpty
            ? ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 140),
            Icon(
              Icons.bookmark_border_rounded,
              size: 72,
              color: Colors.white24,
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'Bạn chưa lưu bài viết nào.',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        )
            : ListView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          itemCount: posts.length + (postManager.isLoadingMoreSaved ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= posts.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.pink,
                  ),
                ),
              );
            }

            final post = posts[index];

            return Container(
              color: AppColors.background,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: PostItem(
                post: post,
              ),
            );
          },
        ),
      ),
    );
  }
}