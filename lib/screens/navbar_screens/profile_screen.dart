// lib/screens/navbar_screens/profile_screen.dart
import 'dart:async';

import 'package:fashion_mobile/screens/order_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/app_colors.dart';
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

  Future<void> _refreshData() async {
    setState(() {
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
                            Shadow(
                              color: Colors.black45,
                              blurRadius: 5,
                            ),
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
                                    'assets/images/default_avatar.png',
                                  ) as ImageProvider,
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
                                              : '0';

                                          return _buildStatItem(
                                            postCount,
                                            'Posts',
                                          );
                                        },
                                      ),
                                      _buildStatItem(
                                        followerCount,
                                        'Followers',
                                      ),
                                      _buildStatItem(
                                        followingCount,
                                        'Following',
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
                                      color: Colors.black,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    email,
                                    style: const TextStyle(
                                      color: Colors.black38,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    bio,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildFilledButton(
                                          text: 'Create Post',
                                          onPressed: _openCreatePost,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildFilledButton(
                                          text: 'Order History',
                                          onPressed: _openOrderHistory,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildFilledButton(
                                          text: 'Wardrobe',
                                          onPressed: () =>
                                              _openMyWardrobe(accountId),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: FutureBuilder<double>(
                                          future: _walletFuture,
                                          builder: (context, walletSnapshot) {
                                            if (walletSnapshot
                                                .connectionState ==
                                                ConnectionState.waiting) {
                                              return _buildLoadingButton();
                                            }

                                            final double currentBalance =
                                            walletSnapshot.hasData
                                                ? walletSnapshot.data!
                                                : balance;

                                            return _buildFilledButton(
                                              text: 'Wapo Wallet',
                                              icon: Icons
                                                  .account_balance_wallet_outlined,
                                              onPressed: () =>
                                                  _showWapoPaySheet(
                                                    context,
                                                    currentBalance,
                                                  ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildFilledButton(
                                          text: 'Spending',
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                const ExpenseManagementScreen(),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildFilledButton(
                                          text: 'Saved',
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                const SavedPostsScreen(),
                                              ),
                                            );
                                          },
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
                                  color: Colors.pinkAccent,
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
                                  style:
                                  const TextStyle(color: Colors.black26),
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
                                  style: TextStyle(color: Colors.black26),
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

  Widget _buildFilledButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.pinkAccent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: icon == null
          ? Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        textAlign: TextAlign.center,
      )
          : Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingButton() {
    return OutlinedButton(
      onPressed: null,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
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