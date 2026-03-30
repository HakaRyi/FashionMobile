import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
// ---> BẮT ĐẦU SỬA
// Import các thư viện cần thiết, loại bỏ import màn hình cá nhân của mình
import '../services/account_service.dart';
import '../../services/post_service.dart';
import '../../utils/route_transitions.dart';
import '../screens/public_wardrobe_screen.dart'; // Giữ lại tủ đồ
import '../../widgets/post_item.dart';
import '../../models/post_feed_model.dart';
import '../utils/stat_skeleton_item.dart';
// import ChatScreen nếu có

class OtherProfileScreen extends StatefulWidget {
  final int userId;

  const OtherProfileScreen({super.key, required this.userId});

  @override
  State<OtherProfileScreen> createState() => _OtherProfileScreenState();
}

class _OtherProfileScreenState extends State<OtherProfileScreen> {
  late Future<Map<String, dynamic>?> _profileFuture;
  late Future<List<PostFeedModel>> _postsFuture;
  bool isFollowing = false;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _profileFuture = AccountService().getUserProfile(widget.userId.toString());
      _postsFuture = PostService().fetchUserPosts(userId: widget.userId);
    });
  }

  void _toggleFollow() {
    setState(() {
      isFollowing = !isFollowing;
    });
  }

  @override
  Widget build(BuildContext context) {
    const double coverHeight = 280.0;
    const double profileOverlap = 80.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _profileFuture,
        builder: (context, profileSnapshot) {
          if (profileSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.pink),
            );
          }

          final user = profileSnapshot.data;
          final String avatar = user?['avatar'] ?? "";
          final String name = user?['username'] ?? "Người dùng";
          final String email = user?['email'] ?? "Đang cập nhật...";
          final String bio =
              user?['description'] ?? "Chưa có giới thiệu về bản thân.";
          final String followerCount = (user?['followerCount'] ?? user?['followers'] ?? 0).toString();
          final String followingCount = (user?['followingCount'] ?? user?['following'] ?? 0).toString();

          return RefreshIndicator(
            onRefresh: () async => _refreshData(),
            color: Colors.pink,
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: coverHeight + 50,
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: avatar.isNotEmpty
                            ? NetworkImage(avatar)
                            : const NetworkImage(
                          "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTNh6H5iL48BL9Ad0XApi7Q7hNrpNpukI3Xfw&s",
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.4),
                            Colors.transparent,
                            Colors.black.withOpacity(0.9),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverAppBar(
                      backgroundColor: Colors.transparent,
                      pinned: true,
                      elevation: 0,
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          shadows: [
                            Shadow(color: Colors.black45, blurRadius: 5),
                          ],
                        ),
                      ),
                      centerTitle: true,
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: coverHeight - kToolbarHeight - profileOverlap,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.purpleAccent,
                                      Colors.pinkAccent,
                                    ],
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 42,
                                  backgroundColor: AppColors.surface,
                                  backgroundImage: avatar.isNotEmpty
                                      ? NetworkImage(avatar)
                                      : const AssetImage(
                                      'assets/images/default_avatar.png')
                                  as ImageProvider,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      FutureBuilder<List<PostFeedModel>>(
                                        future: _postsFuture,
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                            return const StatSkeletonItem();
                                          }
                                          final postCount = snapshot.hasData ? snapshot.data!.length.toString() : "0";
                                          return _buildStatItem(postCount, "Posts");
                                        },
                                      ),
                                      _buildStatItem(followerCount, "Followers"),
                                      _buildStatItem(followingCount, "Following"),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(30),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                margin: const EdgeInsets.only(top: 12),
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    email,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    bio,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Row Các nút chức năng
                                  Row(
                                    children: [
                                      // Nút Follow
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: _toggleFollow,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isFollowing
                                                ? Colors.white24 // Màu xám khi đã follow
                                                : Colors.pink, // Màu hồng khi chưa follow
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                          ),
                                          child: Text(
                                            isFollowing ? "Đang theo dõi" : "Theo dõi",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              fontSize: 13,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Nút Nhắn tin
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            // Navigator.push(context, SlideRoute(page: ChatScreen(userId: widget.userId)));
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.pinkAccent
                                                .withOpacity(0.8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                          ),
                                          child: const Text(
                                            "Nhắn tin",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              fontSize: 13,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Nút Xem tủ đồ
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => Navigator.push(
                                            context,
                                            SlideRoute(
                                              // Truyền userId vào PublicWardrobeScreen nếu màn hình đó hỗ trợ xem của người khác
                                              page: const PublicWardrobeScreen(),
                                            ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            side: const BorderSide(
                                              color: Colors.pink, // Viền màu hồng cho nổi bật
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                          ),
                                          child: const Text(
                                            "Xem tủ đồ công khai",
                                            style: TextStyle(fontSize: 13, color: Colors.pinkAccent),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    FutureBuilder<List<PostFeedModel>>(
                      future: _postsFuture,
                      builder: (context, postSnapshot) {
                        if (postSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.all(40),
                                child: CircularProgressIndicator(
                                  color: Colors.pink,
                                ),
                              ),
                            ),
                          );
                        }

                        if (postSnapshot.hasError) {
                          return SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Center(
                                child: Text(
                                  'Tải bài viết thất bại: ${postSnapshot.error}',
                                  style:
                                  const TextStyle(color: Colors.white54),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          );
                        }

                        final posts = postSnapshot.data ?? [];

                        if (posts.isEmpty) {
                          return const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: Center(
                                child: Text(
                                  "Chưa có bài viết nào.",
                                  style: TextStyle(color: Colors.white38),
                                ),
                              ),
                            ),
                          );
                        }

                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                                (context, index) {
                              final post = posts[index];

                              return Container(
                                color: AppColors.background,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: PostItem(
                                  post: post,
                                  // Đặt isMyPost = false để nó render giống trang Home, ẩn các thao tác sửa/xóa/trạng thái cá nhân
                                  isMyPost: false,
                                  onRefresh: () => _refreshData(),
                                ),
                              );
                            },
                            childCount: posts.length,
                          ),
                        );
                      },
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 100),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
// <--- KẾT THÚC SỬA