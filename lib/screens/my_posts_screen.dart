import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../managers/post_manager.dart';
import '../models/my_post_model.dart';
import '../widgets/my_post_item.dart';
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

  void _openEditPost(MyPostModel post) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => CreatePostScreen(
          postToEdit: {
            'postId': post.postId,
            'title': post.title,
            'content': post.content,
            'imageUrls': post.images,
            'status': post.status,
            'visibility': post.visibility,
          },
        ),
      ),
    )
        .then((_) async {
      await _loadMyPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: _buildFloatingButton(),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: postManager,
          builder: (context, _) {
            final posts = postManager.myPosts;

            return Column(
              children: [
                _buildModernHeader(posts.length),
                Expanded(
                  child: postManager.isLoadingMyPosts
                      ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.textPink,
                    ),
                  )
                      : posts.isEmpty
                      ? RefreshIndicator(
                    onRefresh: _refreshMyPosts,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding:
                      const EdgeInsets.fromLTRB(20, 24, 20, 120),
                      children: [
                        SizedBox(
                          height:
                          MediaQuery.of(context).size.height * 0.68,
                          child: _buildEmptyState(),
                        ),
                      ],
                    ),
                  )
                      : RefreshIndicator(
                    onRefresh: _refreshMyPosts,
                    child: ListView.separated(
                      padding:
                      const EdgeInsets.fromLTRB(16, 12, 16, 120),
                      physics:
                      const AlwaysScrollableScrollPhysics(),
                      itemCount: posts.length + 1,
                      separatorBuilder: (_, __) =>
                      const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _buildOverviewCard(posts);
                        }

                        final post = posts[index - 1];

                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: MyPostItem(
                              post: post,
                              onEdit: post.canEdit
                                  ? () => _openEditPost(post)
                                  : null,
                            ),
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

  Widget _buildModernHeader(int totalPosts) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.textPink.withOpacity(0.95),
            const Color(0xFFFF8FB7),
            const Color(0xFFFFB6CF),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPink.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.22),
              ),
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
                  'Bài viết của tôi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  totalPosts == 0
                      ? 'Bắt đầu xây dựng profile thời trang của bạn'
                      : 'Bạn đang có $totalPosts bài viết trên hồ sơ',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    fontSize: 13.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _refreshMyPosts,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(List<MyPostModel> posts) {
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
      decoration: BoxDecoration(
        color: const Color(0xFF1B1C22),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tổng quan',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Theo dõi nhanh trạng thái bài viết của bạn',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Tổng bài',
                  value: '$total',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.check_circle_rounded,
                  label: 'Công khai',
                  value: '$published',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.hourglass_top_rounded,
                  label: 'Đang duyệt',
                  value: '$verifying',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.report_gmailerrorred_rounded,
                  label: 'Từ chối',
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textPink, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            AppColors.textPink,
            AppColors.textPink.withOpacity(0.82),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPink.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        elevation: 0,
        backgroundColor: Colors.transparent,
        onPressed: _openCreatePost,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Tạo bài viết',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
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
          decoration: BoxDecoration(
            color: const Color(0xFF17181D),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.16),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.textPink.withOpacity(0.28),
                      AppColors.textPink.withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.article_outlined,
                    size: 34,
                    color: AppColors.textPink,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Chưa có bài viết nào',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Hãy đăng bài đầu tiên để xây dựng profile cá nhân thật nổi bật. Bài viết có ảnh sẽ được AI kiểm duyệt trước khi hiển thị công khai.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 22),
              ElevatedButton(
                onPressed: _openCreatePost,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: AppColors.textPink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded),
                    SizedBox(width: 8),
                    Text(
                      'Tạo bài viết ngay',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}