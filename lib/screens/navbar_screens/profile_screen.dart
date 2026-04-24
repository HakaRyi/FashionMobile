import 'dart:async';

import 'package:fashion_mobile/screens/order_history_screen.dart';
import 'package:flutter/material.dart';

import '../../models/post_feed_model.dart';
import '../../screens/create_post_screens.dart';
import '../../screens/expense_management_screen.dart';
import '../../screens/public_wardrobe_screen.dart';
import '../../screens/saved_posts_screen.dart';
import '../../screens/settings_screen.dart';
import '../../services/account_service.dart';
import '../../services/post_service.dart';
import '../../services/wallet_service.dart';
import '../../utils/global_event_bus.dart';
import '../../utils/route_transitions.dart';
import '../../utils/stat_skeleton_item.dart';
import '../../widgets/post_item.dart';
import '../../widgets/wapo_pay_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>?> _profileFuture;
  late Future<List<PostFeedModel>?> _postsFuture;
  late Future<double?> _walletFuture;

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

  Future<void> _refreshData() async {
    setState(() {
      _profileFuture = AccountService().getMyProfile();
      _postsFuture = PostService().fetchMyPosts().catchError(
            (_) => <PostFeedModel>[],
      );
      _walletFuture = WalletService().getMyWalletBalance().catchError(
            (_) => 0.0,
      );
    });
  }

  void _showWapoPaySheet(BuildContext context, double balance) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return WapoPaySheet(initialBalance: balance);
      },
    );
  }

  int? _parseAccountId(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString());
  }

  String _safeString(dynamic value, String fallback) {
    final text = value?.toString().trim();

    if (text == null || text.isEmpty) {
      return fallback;
    }

    return text;
  }

  double _safeDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  Future<void> _openSettings() async {
    final result = await Navigator.push(
      context,
      SlideRoute(page: const SettingsScreen()),
    );

    if (result == true && mounted) {
      _refreshData();
    }
  }

  Future<void> _openCreatePost() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreatePostScreen(),
      ),
    );

    if (mounted) {
      _refreshData();
    }
  }

  Future<void> _openOrderHistory() async {
    await Navigator.push(
      context,
      SlideRoute(
        page: const OrderHistoryScreen(),
      ),
    );

    if (mounted) {
      _refreshData();
    }
  }

  void _openMyWardrobe(int? accountId) {
    if (accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account information not found.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      SlideRoute(
        page: PublicWardrobeScreen(
          accountId: accountId,
          isOwnerView: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double coverHeight = 280.0;
    const double profileOverlap = 80.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _profileFuture,
        builder: (context, profileSnapshot) {
          if (profileSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.black),
            );
          }

          if (profileSnapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load profile: ${profileSnapshot.error}',
                  style: const TextStyle(color: Colors.black),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final user = profileSnapshot.data;

          final String avatar = _safeString(user?['avatar'], '');
          final String name = _safeString(user?['username'], 'User');
          final String email = _safeString(user?['email'], 'unknown@gmail.com');
          final String bio = _safeString(
            user?['description'],
            'No self-introduction yet.',
          );

          final double balance = _safeDouble(user?['balance']);

          final String followerCount = _safeString(
            user?['followerCount'] ?? user?['followers'],
            '0',
          );

          final String followingCount = _safeString(
            user?['followingCount'] ?? user?['following'],
            '0',
          );

          final int? accountId = _parseAccountId(
            user?['id'] ?? user?['accountId'] ?? user?['userId'],
          );

          return RefreshIndicator(
            onRefresh: _refreshData,
            color: Colors.black,
            backgroundColor: Colors.white,
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
                          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTNh6H5iL48BL9Ad0XApi7Q7hNrpNpukI3Xfw&s',
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
                            Colors.black.withOpacity(0.5),
                            Colors.transparent,
                            Colors.white,
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
                          fontSize: 18,
                          letterSpacing: 1.2,
                          shadows: [
                            Shadow(
                              color: Colors.black87,
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      centerTitle: true,
                      actions: [
                        IconButton(
                          icon: const Icon(
                            Icons.settings_outlined,
                            color: Colors.white,
                          ),
                          onPressed: _openSettings,
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
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.black87,
                                      Colors.black45,
                                    ],
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 42,
                                  backgroundColor: Colors.white,
                                  backgroundImage: avatar.isNotEmpty
                                      ? NetworkImage(avatar)
                                      : const AssetImage(
                                    'assets/images/default_avatar.png',
                                  ) as ImageProvider,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                    children: [
                                      FutureBuilder<List<PostFeedModel>?>(
                                        future: _postsFuture,
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const StatSkeletonItem();
                                          }

                                          final postCount =
                                          (snapshot.data?.length ?? 0)
                                              .toString();

                                          return _buildStatItem(
                                            postCount,
                                            'POSTS',
                                          );
                                        },
                                      ),
                                      _buildStatItem(
                                        followerCount,
                                        'FOLLOWERS',
                                      ),
                                      _buildStatItem(
                                        followingCount,
                                        'FOLLOWING',
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
                          color: Colors.white,
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
                                  color: Colors.black12,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                              const EdgeInsets.fromLTRB(20, 20, 20, 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    email,
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    bio,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 10,
                                bottom: 20,
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.only(
                                  left: 20,
                                  right: 20,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildHangerButton(
                                      title: 'Create\nPost',
                                      icon: Icons.add_a_photo_outlined,
                                      onTap: _openCreatePost,
                                    ),
                                    _buildHangerButton(
                                      title: 'Wardrobe',
                                      icon: Icons.door_sliding_outlined,
                                      onTap: () => _openMyWardrobe(accountId),
                                    ),
                                    FutureBuilder<double?>(
                                      future: _walletFuture,
                                      builder: (context, walletSnapshot) {
                                        final isLoading =
                                            walletSnapshot.connectionState ==
                                                ConnectionState.waiting;

                                        final currentBalance =
                                            walletSnapshot.data ?? balance;

                                        return _buildHangerButton(
                                          title: isLoading ? '...' : 'Wallet',
                                          icon: Icons
                                              .account_balance_wallet_outlined,
                                          onTap: isLoading
                                              ? () {}
                                              : () => _showWapoPaySheet(
                                            context,
                                            currentBalance,
                                          ),
                                        );
                                      },
                                    ),
                                    _buildHangerButton(
                                      title: 'Orders',
                                      icon: Icons.receipt_long_outlined,
                                      onTap: _openOrderHistory,
                                    ),
                                    _buildHangerButton(
                                      title: 'Spending',
                                      icon: Icons.analytics_outlined,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                            const ExpenseManagementScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                    _buildHangerButton(
                                      title: 'Saved',
                                      icon: Icons.bookmark_border,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                            const SavedPostsScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Divider(
                              color: Colors.black12,
                              thickness: 1,
                              height: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                    FutureBuilder<List<PostFeedModel>?>(
                      future: _postsFuture,
                      builder: (context, postSnapshot) {
                        if (postSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.all(40),
                                child: CircularProgressIndicator(
                                  color: Colors.black,
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
                                  'Failed to load posts: ${postSnapshot.error}',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                  ),
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
                                  'No posts yet.',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w500,
                                  ),
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
                                color: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: PostItem(
                                  post: post,
                                  isMyPost: true,
                                  onRefresh: _refreshData,
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
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: Colors.white24,
          width: 0.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              shadows: [
                Shadow(
                  color: Colors.black54,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              shadows: [
                Shadow(
                  color: Colors.black87,
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHangerButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          children: [
            const Icon(
              Icons.checkroom,
              color: Colors.black,
              size: 32,
            ),
            Transform.translate(
              offset: const Offset(0, -5),
              child: Container(
                height: 72,
                width: 60,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.black,
                    width: 2,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(2),
                    topRight: Radius.circular(2),
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      offset: Offset(3, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: Colors.black,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}