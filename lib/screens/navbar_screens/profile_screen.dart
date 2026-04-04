// lib/screens/navbar_screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_colors.dart';
import '../../screens/create_post_screens.dart';
import '../../screens/expense_management_screen.dart';
import '../../screens/saved_posts_screen.dart';
import '../../screens/settings_screen.dart';
import '../../services/account_service.dart';
import '../../services/post_service.dart';
import '../../utils/route_transitions.dart';
import '../../utils/stat_skeleton_item.dart';
import '../../widgets/wapo_pay_sheet.dart';
import '../order_manager_screen.dart';
import '../public_wardrobe_screen.dart';
import '../../widgets/post_item.dart';
import '../../models/post_feed_model.dart';
import '../../services/wallet_service.dart';
import 'dart:async';
import '../../utils/global_event_bus.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>?> _profileFuture;
  late Future<List<PostFeedModel>> _postsFuture;
  late Future<double> _walletFuture;

  StreamSubscription? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _refreshData();
    _eventSubscription = GlobalEventBus().onProfileUpdateNeeded.listen((_) {
      if (mounted) {
        _refreshData();
      }
    });
  }
  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  void _refreshData() {
    setState(()  {
      _profileFuture = AccountService().getMyProfile();
      _postsFuture = PostService().fetchMyPosts();
      _walletFuture = WalletService().getMyWalletBalance();
    });
  }

  void _showWapoPaySheet(BuildContext context, double balance) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return WapoPaySheet(initialBalance: balance);
      },
    );
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

          if (profileSnapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Tải hồ sơ thất bại: ${profileSnapshot.error}',
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final user = profileSnapshot.data;
          final String avatar = user?['avatar'] ?? "";
          final String name = user?['username'] ?? "User";
          final String email = user?['email'] ?? "unknown@gmail.com";
          final String bio =
              user?['description'] ?? "Chưa có giới thiệu về bản thân.";
          final double balance = (user?['balance'] ?? 0.0).toDouble();
          final String followerCount =
          (user?['followerCount'] ?? user?['followers'] ?? 0).toString();
          final String followingCount =
          (user?['followingCount'] ?? user?['following'] ?? 0).toString();

          final int? accountId = _parseAccountId(
            user?['id'] ?? user?['accountId'] ?? user?['userId'],
          );

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
                      actions: [
                        IconButton(
                          icon: const Icon(
                            Icons.more_horiz,
                            color: Colors.white,
                          ),
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              SlideRoute(page: const SettingsScreen()),
                            );
                            if (result == true) {
                              _refreshData();
                            }
                          },
                        ),
                      ],
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
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                    children: [
                                      FutureBuilder<List<PostFeedModel>>(
                                        future: _postsFuture,
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const StatSkeletonItem();
                                          }
                                          final postCount = snapshot.hasData
                                              ? snapshot.data!.length.toString()
                                              : "0";
                                          return _buildStatItem(
                                            postCount,
                                            "Posts",
                                          );
                                        },
                                      ),
                                      _buildStatItem(
                                        followerCount,
                                        "Followers",
                                      ),
                                      _buildStatItem(
                                        followingCount,
                                        "Following",
                                      ),
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

                                  // Row 1
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                              const CreatePostScreen(),
                                            ),
                                          ).then((_) => _refreshData()),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.pink,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                          ),
                                          child: const Text(
                                            "Tạo Bài Đăng",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              fontSize: 13,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => Navigator.push(
                                            context,
                                            SlideRoute(
                                              page:
                                              const OrderManagementScreen(),
                                            ),
                                          ),
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
                                            "Quản Lý Đơn",
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

                                  // Row 2
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () {
                                            if (accountId == null) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    "Không tìm thấy thông tin tài khoản.",
                                                  ),
                                                ),
                                              );
                                              return;
                                            }

                                            Navigator.push(
                                              context,
                                              SlideRoute(
                                                page: PublicWardrobeScreen(
                                                  accountId: accountId,
                                                ),
                                              ),
                                            );
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            side: const BorderSide(
                                              color: Colors.white24,
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
                                            "Tủ Đồ",
                                            style: TextStyle(fontSize: 13),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: FutureBuilder<double>(
                                          future: _walletFuture,
                                          builder: (context, walletSnapshot) {
                                            if (walletSnapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return OutlinedButton(
                                                onPressed: null,
                                                style:
                                                OutlinedButton.styleFrom(
                                                  foregroundColor: Colors.white,
                                                  side: const BorderSide(
                                                    color: Colors.white24,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                    BorderRadius.circular(
                                                        12),
                                                  ),
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    vertical: 12,
                                                  ),
                                                ),
                                                child: const Row(
                                                  mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                                  children: [
                                                    SizedBox(
                                                      width: 16,
                                                      height: 16,
                                                      child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }

                                            final double currentBalance =
                                            walletSnapshot.hasData
                                                ? walletSnapshot.data!
                                                : balance;

                                            return OutlinedButton(
                                              onPressed: () =>
                                                  _showWapoPaySheet(
                                                    context,
                                                    currentBalance,
                                                  ),
                                              style:
                                              OutlinedButton.styleFrom(
                                                foregroundColor: Colors.white,
                                                side: const BorderSide(
                                                  color: Colors.white24,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                      12),
                                                ),
                                                padding:
                                                const EdgeInsets.symmetric(
                                                  vertical: 12,
                                                ),
                                              ),
                                              child: const Row(
                                                mainAxisAlignment:
                                                MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .account_balance_wallet_outlined,
                                                    size: 16,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    "Wapo",
                                                    style:
                                                    TextStyle(fontSize: 13),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  // Row 3
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                              const ExpenseManagementScreen(),
                                            ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            side: const BorderSide(
                                              color: Colors.white24,
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
                                            "Chi Tiêu",
                                            style: TextStyle(fontSize: 13),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                              const SavedPostsScreen(),
                                            ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            side: const BorderSide(
                                              color: Colors.white24,
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
                                            "Đã Lưu",
                                            style: TextStyle(fontSize: 13),
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
                                  isMyPost: true,
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

  int? _parseAccountId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
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