import 'package:flutter/material.dart';

import '../constants/post_status_values.dart';
import '../managers/post_manager.dart';
import '../models/post_feed_model.dart';
import '../widgets/post_item.dart';
import 'create_post_screens.dart';

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  @override
  void initState() {
    super.initState();
    _loadMyPosts();
  }

  Future<void> _loadMyPosts() async {
    await postManager.fetchMyPosts(page: 1, pageSize: 20);
  }

  Future<void> _refreshMyPosts() async {
    await _loadMyPosts();
  }

  void _openCreatePost() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => const CreatePostScreen(),
      ),
    )
        .then((_) async {
      await _loadMyPosts();
    });
  }

  bool _canEditPost(PostFeedModel post) {
    final status = post.status?.toLowerCase();

    return status != PostStatusValues.rejected.toLowerCase() &&
        status != 'airejected' &&
        status != 'blockedbyadmin';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      floatingActionButton: _buildFloatingButton(),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: postManager,
          builder: (context, _) {
            final posts = postManager.myPosts;

            return Column(
              children: [
                _buildHeader(posts.length),
                Expanded(
                  child: postManager.isLoadingMyPosts
                      ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.black,
                    ),
                  )
                      : posts.isEmpty
                      ? RefreshIndicator(
                    onRefresh: _refreshMyPosts,
                    color: Colors.black,
                    backgroundColor: Colors.white,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding:
                      const EdgeInsets.fromLTRB(20, 24, 20, 120),
                      children: [
                        SizedBox(
                          height:
                          MediaQuery.of(context).size.height *
                              0.68,
                          child: _buildEmptyState(),
                        ),
                      ],
                    ),
                  )
                      : RefreshIndicator(
                    onRefresh: _refreshMyPosts,
                    color: Colors.black,
                    backgroundColor: Colors.white,
                    child: ListView.separated(
                      padding:
                      const EdgeInsets.fromLTRB(16, 12, 16, 120),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: posts.length + 1,
                      separatorBuilder: (_, __) =>
                      const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _buildOverviewCard(posts);
                        }

                        final post = posts[index - 1];

                        return ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: PostItem(
                            post: post,
                            isMyPost: true,
                            onRefresh: _refreshMyPosts,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(int totalPosts) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MY POSTS',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  totalPosts == 0
                      ? 'Start building your fashion profile.'
                      : 'You have $totalPosts post(s) on your profile.',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 13.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _refreshMyPosts,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF5F5F5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(List<PostFeedModel> posts) {
    final total = posts.length;
    final published =
        posts.where((e) => e.status?.toLowerCase() == 'published').length;
    final verifying =
        posts.where((e) => e.status?.toLowerCase() == 'verifying').length;
    final rejected = posts.where((e) {
      final s = e.status?.toLowerCase();
      return s == 'rejected' || s == 'airejected' || s == 'blockedbyadmin';
    }).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'OVERVIEW',
            Icons.analytics_outlined,
          ),
          const SizedBox(height: 6),
          const Text(
            'Quickly track the review status of your posts.',
            style: TextStyle(
              color: Colors.black45,
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Total',
                  value: '$total',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.check_circle_rounded,
                  label: 'Published',
                  value: '$published',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.hourglass_top_rounded,
                  label: 'Reviewing',
                  value: '$verifying',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.report_gmailerrorred_rounded,
                  label: 'Rejected',
                  value: '$rejected',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.black.withOpacity(0.04),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.black,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton() {
    return FloatingActionButton.extended(
      elevation: 0,
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      onPressed: _openCreatePost,
      icon: const Icon(Icons.add_rounded),
      label: const Text(
        'CREATE POST',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 12,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: _cardDecoration(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF1F1F1),
                ),
                child: const Icon(
                  Icons.article_outlined,
                  size: 38,
                  color: Colors.black26,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'NO POSTS YET',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Create your first post to build a standout fashion profile. Posts with images will be reviewed by AI before becoming public.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black45,
                  fontSize: 14,
                  height: 1.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: _openCreatePost,
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'CREATE FIRST POST',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 0.4,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.black,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: Colors.black.withOpacity(0.05),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}