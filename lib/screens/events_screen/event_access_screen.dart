import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../models/post_feed_model.dart';
import '../../services/event_service.dart';
import '../../widgets/post_item.dart';

class EventAccessScreen extends StatelessWidget {
  final EventModel event;

  const EventAccessScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070707),
      body: FutureBuilder<List<PostFeedModel>>(
        future: EventService().getEventPosts(event.eventId),
        builder: (context, snapshot) {
          // Xử lý khi đang tải hoặc lỗi
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
          }

          final posts = snapshot.data ?? [];

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Header ảnh nền sự kiện cực đẹp
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                backgroundColor: const Color(0xFF1E1E1E),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    event.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        shadows: [Shadow(color: Colors.black, blurRadius: 10)]
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(event.imageUrl, fit: BoxFit.cover),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.transparent,
                              const Color(0xFF0D0D0D)
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Thanh thống kê số người tham gia thật từ Event
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                              "CUỘC THI ĐANG DIỄN RA",
                              style: TextStyle(color: Colors.pinkAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)
                          ),
                          const SizedBox(height: 4),
                          Text(
                              "Tổng cộng ${posts.length} bài dự thi",
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                          ),
                        ],
                      ),
                      Icon(Icons.check, size: 32, color: Colors.pinkAccent),
                    ],
                  ),
                ),
              ),

              // 3. Danh sách bài đăng thật từ API (Tái sử dụng PostItem xịn của ông)
              posts.isEmpty
                  ? const SliverFillRemaining(
                child: Center(
                  child: Text("Chưa có bài đăng nào tham gia sự kiện này", style: TextStyle(color: Colors.white38)),
                ),
              )
                  : SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: PostItem(post: posts[index]),
                    );
                  },
                  childCount: posts.length,
                ),
              ),

              // Padding ở cuối để không bị cấn thanh điều hướng
              const SliverToBoxAdapter(child: SizedBox(height: 50)),
            ],
          );
        },
      ),
    );
  }
}