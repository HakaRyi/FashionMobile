import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../managers/post_manager.dart';
import '../widgets/post_item.dart';

class HashtagFeedScreen extends StatefulWidget {
  final String tag;

  const HashtagFeedScreen({
    super.key,
    required this.tag,
  });

  @override
  State<HashtagFeedScreen> createState() => _HashtagFeedScreenState();
}

class _HashtagFeedScreenState extends State<HashtagFeedScreen> {
  final PostManager _manager = postManager;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Lắng nghe sự kiện cuộn màn hình để tải thêm bài viết (Infinite Scroll)
    _scrollController.addListener(() {
      if (_scrollController.hasClients &&
          _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _manager.loadMorePostsByHashtag(tagName: widget.tag);
      }
    });

    // Kích hoạt gọi API tải luồng bài viết theo Tag lần đầu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _manager.fetchPostsByHashtag(tagName: widget.tag, refresh: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          '#${widget.tag}',
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFEEEEEE),
            height: 1,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: _manager,
        builder: (context, _) {
          // Lấy mảng dữ liệu bài viết theo hashtag từ biến lưu trữ tập trung của Manager
          final posts = _manager.hashtagPosts;

          // 1. Trạng thái Loading ban đầu
          if (_manager.isLoadingHashtagPosts && posts.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.textPink,
              ),
            );
          }

          // 2. Trạng thái Luồng rỗng (Empty State)
          if (posts.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => _manager.fetchPostsByHashtag(tagName: widget.tag, refresh: true),
              color: AppColors.textPink,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.tag_rounded,
                          size: 64,
                          color: Colors.grey.withOpacity(0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No posts found for #${widget.tag}',
                          style: const TextStyle(
                            color: Colors.black45,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          // 3. Hiển thị Luồng danh sách bài viết kèm kéo thả để Refresh và tải thêm phân trang
          return RefreshIndicator(
            onRefresh: () => _manager.fetchPostsByHashtag(tagName: widget.tag, refresh: true),
            color: AppColors.textPink,
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              itemCount: posts.length + 1 + (_manager.isLoadingMoreHashtagPosts ? 1 : 0),
              itemBuilder: (context, index) {
                // Header hiển thị tổng số lượng bài viết lấy về
                if (index == 0) {
                  return Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'There are ${posts.length} ${posts.length == 1 ? "post" : "posts"} related to this topic',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }

                // Kiểm tra hiển thị thanh Progress xoay tròn ở cuối danh sách khi đang tải trang tiếp theo (Load More)
                if (index == posts.length + 1) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.textPink,
                      ),
                    ),
                  );
                }

                // Trả về từng item bài viết tương ứng
                final postItemData = posts[index - 1];
                return PostItem(
                  key: ValueKey('tag_feed_${postItemData.postId}'),
                  post: postItemData,
                );
              },
            ),
          );
        },
      ),
    );
  }
}