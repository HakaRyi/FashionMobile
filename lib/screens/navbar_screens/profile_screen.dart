import 'package:fashion_mobile/widgets/post_item.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_colors.dart';
import '../../screens/settings_screen.dart';
import '../../screens/create_post_screens.dart';
import '../public_wardrobe_screen.dart';
import '../../utils/route_transitions.dart';
import '../../services/post_service.dart';
import '../../services/account_service.dart'; // Đảm bảo ông đã tạo file này như tui hướng dẫn

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>?> _profileFuture;
  late Future<List<dynamic>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  // Hàm để load hoặc reload dữ liệu
  void _refreshData() {
    setState(() {
      _profileFuture = AccountService().getMyProfile();
      _postsFuture = PostService().fetchMyPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final double coverHeight = 280.0;
    final double profileOverlap = 80.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _profileFuture,
        builder: (context, profileSnapshot) {
          if (profileSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.pink));
          }

          // Lấy dữ liệu từ API Account, nếu lỗi thì dùng dữ liệu mặc định
          final user = profileSnapshot.data;
          final String avatar = user?['avatar'] ?? "";
          final String name = user?['username'] ?? "User";
          final String email = user?['email'] ?? "unknown@gmail.com";
          final String bio = user?['description'] ?? "Chưa có giới thiệu về bản thân.";

          return RefreshIndicator(
            onRefresh: () async => _refreshData(),
            color: Colors.pink,
            child: Stack(
              children: [
                // Lớp 1: Ảnh Cover Nền (Lấy chính avatar làm mờ)
                Positioned(
                  top: 0, left: 0, right: 0,
                  height: coverHeight + 50,
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: avatar.isNotEmpty ? NetworkImage(avatar) : const NetworkImage("https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTNh6H5iL48BL9Ad0XApi7Q7hNrpNpukI3Xfw&s"),
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

                // Lớp 2: Nội dung cuộn chính
                CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  slivers: [
                    // 1. AppBar
                    SliverAppBar(
                      backgroundColor: Colors.transparent,
                      pinned: true,
                      elevation: 0,
                      title: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          shadows: [Shadow(color: Colors.black45, blurRadius: 5)],
                        ),
                      ),
                      centerTitle: true,
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.more_horiz, color: Colors.white),
                          onPressed: () {
                            Navigator.push(context, SlideRoute(page: const SettingsScreen()));
                          },
                        ),
                      ],
                    ),

                    // 2. Header Info (Avatar + Stats thực tế từ API Account)
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: coverHeight - kToolbarHeight - profileOverlap,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(colors: [Colors.purpleAccent, Colors.pinkAccent]),
                                ),
                                child: CircleAvatar(
                                  radius: 42,
                                  backgroundColor: AppColors.surface,
                                  backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildStatItem(user?['postCount']?.toString() ?? "0", "Posts"),
                                      _buildStatItem(user?['followerCount']?.toString() ?? "0", "Followers"),
                                      _buildStatItem(user?['followingCount']?.toString() ?? "0", "Following"),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 3. Body: Tên, Bio và Nút hành động
                    SliverToBoxAdapter(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                margin: const EdgeInsets.only(top: 12),
                                width: 40, height: 4,
                                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                                  Text(email, style: const TextStyle(color: Colors.white54, fontSize: 14)),
                                  const SizedBox(height: 12),
                                  Text(bio, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePostScreen())),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.pink,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                          ),
                                          child: const Text("Tạo Bài Đăng", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => Navigator.push(context, SlideRoute(page: const PublicWardrobeScreen())),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            side: const BorderSide(color: Colors.white24),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                          ),
                                          child: const Text("Tủ Đồ"),
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

                    // 4. Grid bài viết từ FutureBuilder (Lấy từ PostService)
                    FutureBuilder<List<dynamic>>(
                      future: _postsFuture,
                      builder: (context, postSnapshot) {
                        if (postSnapshot.connectionState == ConnectionState.waiting) {
                          return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: Colors.pink))));
                        }

                        if (!postSnapshot.hasData || postSnapshot.data!.isEmpty) {
                          return const SliverToBoxAdapter(
                            child: Padding(padding: EdgeInsets.all(40),
                                child: Center(child: Text("Chưa có bài viết nào.", style: TextStyle(color: Colors.white38)))),
                          );
                        }

                        final posts = postSnapshot.data!;
                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                                (context, index) {
                              return Container(
                                color: AppColors.background,
                                child: Column(
                                  children: [
                                    PostItem(postData: posts[index],
                                              isMyPost: true,),
                                    if (index < posts.length - 1)
                                      const Divider(color: AppColors.divider, height: 1, indent: 16, endIndent: 16),
                                  ],
                                ),
                              );
                            },
                            childCount: posts.length,
                          ),
                        );
                      },
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}