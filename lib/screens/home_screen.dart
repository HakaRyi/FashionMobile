// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../managers/post_manager.dart';
import '../utils/notification_manager.dart';
import '../widgets/create_post_header.dart';
import '../widgets/main_app_bar.dart';
import '../widgets/post_item.dart';
import 'trending_hashtags_screen.dart';

class HomeScreen extends StatefulWidget {
  final int? focusPostId;

  const HomeScreen({
    super.key,
    this.focusPostId,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isVisible = false;
  final ScrollController _scrollController = ScrollController();
  int? _highlightPostId;
  bool _isJumpingToSharedPost = false;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (_scrollController.hasClients &&
          _scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200) {
        postManager.loadMore();
      }
    });

    notificationManager.initialize();
    notificationManager.fetchNotificationHistory();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeHome();
      }
    });
  }

  Future<void> _initializeHome() async {
    try {
      await postManager.fetchInitialFeed();

      if (widget.focusPostId != null) {
        await _focusSharedPost(widget.focusPostId!);
      }
    } catch (e) {
      debugPrint('Error loading feed: $e'); // Đã đổi sang tiếng Anh
    } finally {
      await Future.delayed(const Duration(milliseconds: 150));
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
      }
    }
  }

  Future<void> _focusSharedPost(int postId) async {
    if (_isJumpingToSharedPost) return;
    _isJumpingToSharedPost = true;

    try {
      final post = await postManager.ensurePostAtTop(postId);

      if (post == null || !mounted) return;

      setState(() {
        _highlightPostId = postId;
      });

      await WidgetsBinding.instance.endOfFrame;
      await WidgetsBinding.instance.endOfFrame;

      if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _highlightPostId = null;
        });
      }
    } catch (e) {
      debugPrint('Focus shared post error: $e');
    } finally {
      _isJumpingToSharedPost = false;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await postManager.fetchInitialFeed();

    if (widget.focusPostId != null) {
      await _focusSharedPost(widget.focusPostId!);
    }
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
            backgroundColor: AppColors.background,
            edgeOffset: 100,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _isVisible ? 1.0 : 0.0,
              child: CustomScrollView(
                controller: _scrollController,
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
                        if (postManager.isUploading ||
                            postManager.uploadProgress > 0)
                          _buildUploadProgressCard(),
                      ],
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "What's New",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: 0.2,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TrendingHashtagsScreen(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.trending_up_rounded,
                              size: 24,
                              color: AppColors.textPrimary,
                            ),
                            splashRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (postManager.posts.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: postManager.isLoading
                            ? const CircularProgressIndicator(
                          color: AppColors.textPink,
                        )
                            : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.style_outlined,
                              size: 60,
                              color: AppColors.borderPrimary,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No outfits shared yet.', // Đã đổi sang tiếng Anh
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final post = postManager.posts[index];
                          final bool isHighlighted =
                              post.postId == _highlightPostId;

                          return Column(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                decoration: BoxDecoration(
                                  color: isHighlighted
                                      ? AppColors.textPink.withOpacity(0.05)
                                      : Colors.transparent,
                                ),
                                child: PostItem(
                                  key: ValueKey(post.postId),
                                  post: post,
                                ),
                              ),
                              if (index < postManager.posts.length - 1)
                                const Divider(
                                  color: AppColors.divider,
                                  height: 12,
                                  thickness: 6,
                                ),
                            ],
                          );
                        },
                        childCount: postManager.posts.length,
                      ),
                    ),
                  if (postManager.isLoadingMore)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.textPink,
                          ),
                        ),
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

    // Đã chuyển logic kiểm tra chuỗi tiếng Việt sang tiếng Anh
    final isUpdating =
    postManager.statusMessage.toLowerCase().contains('update');

    final progressColor = isFinishedUpload
        ? Colors.green
        : (isUpdating ? Colors.blueAccent : AppColors.textPink);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderPrimary),
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
                  color: isFinishedUpload ? Colors.green : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!isFinishedUpload)
                Text(
                  '${(postManager.uploadProgress * 100).toInt()}%',
                  style: TextStyle(
                    color: progressColor,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: postManager.uploadProgress,
              backgroundColor: AppColors.borderPrimary,
              color: progressColor,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}