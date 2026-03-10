import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/main_app_bar.dart';
import '../widgets/post_item.dart';
import '../widgets/create_post_header.dart';
import '../utils/post_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    postManager.fetchPosts();

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
      }
    });
  }

  Future<void> _handleRefresh() async {
    await postManager.fetchPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListenableBuilder(
        listenable: postManager,
        builder: (context, child) {
          return RefreshIndicator(
            onRefresh: _handleRefresh,
            color: AppColors.textPink,
            backgroundColor: AppColors.surface,
            edgeOffset: 100,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: _isVisible ? 1.0 : 0.0,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  const SliverAppBar(
                    floating: true,
                    snap: true,
                    backgroundColor: AppColors.background,
                    elevation: 0,
                    flexibleSpace: MainAppBar(),
                    toolbarHeight: 60,
                  ),
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const CreatePostHeader(),
                        if (postManager.isUploading || postManager.uploadProgress > 0)
                          _buildUploadProgressCard(),
                      ],
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Bản tin mới nhất",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Icon(Icons.tune_rounded, size: 20, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                  if (postManager.posts.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: postManager.isLoading
                            ? const CircularProgressIndicator(color: AppColors.textPink)
                            : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.feed_outlined, size: 50, color: Colors.white24),
                            const SizedBox(height: 16),
                            const Text(
                              "Chưa có bài viết nào.",
                              style: TextStyle(color: Colors.white38),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          return Column(
                            children: [
                              const SizedBox(height: 4),
                              PostItem(postData: postManager.posts[index]),
                              if (index < postManager.posts.length - 1)
                                const Divider(
                                  color: AppColors.divider,
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                ),
                            ],
                          );
                        },
                        childCount: postManager.posts.length,
                      ),
                    ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 80),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUploadProgressCard() {
    final isFinishedUpload = postManager.uploadProgress >= 1.0;
    // Nếu status message chứa từ "cập nhật", dùng màu xanh dương để phân biệt với upload mới
    final isUpdating = postManager.statusMessage.toLowerCase().contains("cập nhật");
    final progressColor = isFinishedUpload
        ? Colors.orangeAccent
        : (isUpdating ? Colors.blueAccent : AppColors.textPink);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                postManager.statusMessage,
                style: TextStyle(
                  color: isFinishedUpload ? Colors.orangeAccent : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!isFinishedUpload)
                Text(
                  "${(postManager.uploadProgress * 100).toInt()}%",
                  style: TextStyle(color: progressColor, fontWeight: FontWeight.bold),
                )
              else
                const Icon(Icons.hourglass_bottom, color: Colors.orangeAccent, size: 20)
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: postManager.uploadProgress,
              backgroundColor: Colors.white10,
              color: progressColor,
              minHeight: 8,
            ),
          ),
          if (isFinishedUpload)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "Hệ thống đang xử lý...",
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontStyle: FontStyle.italic),
              ),
            )
        ],
      ),
    );
  }
}