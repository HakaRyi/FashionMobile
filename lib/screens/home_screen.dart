import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/main_app_bar.dart';
import '../widgets/post_item.dart';
import '../widgets/create_post_header.dart';
import '../utils/post_manager.dart';
import '../services/post_service.dart'; // Import PostService để gọi API

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isVisible = false;
  late Future<List<dynamic>> _newsfeedFuture;

  @override
  void initState() {
    super.initState();
    // Khởi tạo gọi API lấy danh sách bài viết chung
    _newsfeedFuture = PostService().getAllPosts();

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
      }
    });
  }

  // Hàm xử lý vuốt để làm mới (Pull to Refresh)
  Future<void> _handleRefresh() async {
    setState(() {
      _newsfeedFuture = PostService().getAllPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // Bọc toàn bộ bằng RefreshIndicator
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppColors.textPink,
        backgroundColor: AppColors.surface,
        edgeOffset: 100, // Đẩy vòng xoay xuống dưới AppBar
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          opacity: _isVisible ? 1.0 : 0.0,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // 1. App Bar
              const SliverAppBar(
                floating: true,
                snap: true,
                backgroundColor: AppColors.background,
                elevation: 0,
                flexibleSpace: MainAppBar(),
                toolbarHeight: 60,
              ),

              // 2. Khu vực tạo bài viết & Tiến trình upload
              SliverToBoxAdapter(
                child: ListenableBuilder(
                  listenable: postManager,
                  builder: (context, child) {
                    return Column(
                      children: [
                        const CreatePostHeader(),
                        if (postManager.isUploading || postManager.uploadProgress > 0)
                          _buildUploadProgressCard(),
                      ],
                    );
                  },
                ),
              ),

              // 3. Tiêu đề bản tin
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

              // 4. Danh sách bài viết động từ API
              FutureBuilder<List<dynamic>>(
                future: _newsfeedFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(color: AppColors.textPink),
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.feed_outlined, size: 50, color: Colors.white24),
                              const SizedBox(height: 16),
                              const Text(
                                "Không có bài viết nào mới.",
                                style: TextStyle(color: Colors.white38),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final posts = snapshot.data!;
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        return Column(
                          children: [
                            const SizedBox(height: 4),
                            // Truyền dữ liệu thật vào PostItem
                            PostItem(postData: posts[index]),
                            if (index < posts.length - 1)
                              const Divider(
                                color: AppColors.divider,
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                              ),
                          ],
                        );
                      },
                      childCount: posts.length,
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget hiển thị tiến trình upload bài viết
  Widget _buildUploadProgressCard() {
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
              const Text(
                "Đang xử lý bài viết...",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(
                "${(postManager.uploadProgress * 100).toInt()}%",
                style: const TextStyle(color: AppColors.textPink, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: postManager.uploadProgress,
              backgroundColor: Colors.white10,
              color: AppColors.textPink,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}