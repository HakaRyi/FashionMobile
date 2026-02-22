import 'package:fashion_mobile/widgets/post_item.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_colors.dart';
import '../../screens/settings_screen.dart';
import '../../screens/create_post_screens.dart';
import '../public_wardrobe_screen.dart';
import '../../utils/route_transitions.dart';
import '../../services/post_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _email = "Đang tải...";
  String _displayName = "User";
  String _avatarUrl = "";
  late Future<List<dynamic>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    // Khởi tạo Future gọi API ngay từ đầu
    _postsFuture = PostService().fetchMyPosts();
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _email = prefs.getString('email') ?? "unknown@";
      _avatarUrl = prefs.getString('avatar') ?? "";
      _displayName = prefs.getString('username') ?? "unknown_user";
    });
  }

  @override
  Widget build(BuildContext context) {
    final double coverHeight = 280.0;
    final double profileOverlap = 80.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Lớp 1: Ảnh Cover Nền (Blur nhẹ dựa trên Avatar)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: coverHeight + 50,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: _avatarUrl.isNotEmpty
                      ? NetworkImage(_avatarUrl)
                      : const NetworkImage("https://images.unsplash.com/photo-1496747611176-843222e1e57c?q=80&w=2073&auto=format&fit=crop"),
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
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Lớp 2: Nội dung cuộn chính
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. AppBar trong suốt
              SliverAppBar(
                backgroundColor: Colors.transparent,
                pinned: true,
                elevation: 0,
                title: Text(
                  _displayName,
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

              // 2. Header Info (Avatar + Stats động từ API)
              FutureBuilder<List<dynamic>>(
                future: _postsFuture,
                builder: (context, snapshot) {
                  String postCount = snapshot.hasData ? snapshot.data!.length.toString() : "0";

                  return SliverToBoxAdapter(
                    child: SizedBox(
                      height: coverHeight - kToolbarHeight - profileOverlap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Avatar Profile
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                                gradient: const LinearGradient(
                                  colors: [Colors.purpleAccent, Colors.pinkAccent],
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 42,
                                backgroundColor: AppColors.surface,
                                backgroundImage: _avatarUrl.isNotEmpty
                                    ? NetworkImage(_avatarUrl)
                                    : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Thống kê Stats
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatItem(postCount, "Posts"),
                                    _buildStatItem("0", "Follower"),
                                    _buildStatItem("0", "Following"),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
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
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
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
                              _displayName,
                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _email,
                              style: const TextStyle(color: Colors.white54, fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "Giới thiệu về bản thân",
                              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePostScreen())),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.textPink,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    child: const Text("Tạo Bài Đăng", style: TextStyle(fontWeight: FontWeight.bold)),
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

              // 4. Grid bài viết thực tế từ FutureBuilder
              FutureBuilder<List<dynamic>>(
                future: _postsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: AppColors.textPink))),
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(40),
                        child: const Center(
                          child: Text("Bạn chưa có bài viết nào.", style: TextStyle(color: Colors.white38)),
                        ),
                      ),
                    );
                  }

                  final posts = snapshot.data!;
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        return Container(
                          color: AppColors.background,
                          child: Column(
                            children: [
                              PostItem(postData: posts[index]), // Đảm bảo PostItem nhận dữ liệu
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

              const SliverToBoxAdapter(child: SizedBox(height: 100)), // Padding dưới cùng
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}