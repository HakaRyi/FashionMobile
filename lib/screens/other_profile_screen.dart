// lib/screens/other_profile_screen.dart
import 'dart:async';
import 'package:fashion_mobile/screens/user_storefront_screen.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/post_feed_model.dart';
import '../services/account_service.dart';
import '../services/chat_service.dart';
import '../services/follow_service.dart';
import '../services/post_service.dart';
import '../utils/global_event_bus.dart';
import '../utils/route_transitions.dart';
import '../utils/stat_skeleton_item.dart';
import '../widgets/post_item.dart';
import 'chat_screen.dart';
import 'public_wardrobe_screen.dart';

class OtherProfileScreen extends StatefulWidget {
  final int userId;

  const OtherProfileScreen({super.key, required this.userId});

  @override
  State<OtherProfileScreen> createState() => _OtherProfileScreenState();
}

class _OtherProfileScreenState extends State<OtherProfileScreen> {
  late Future<Map<String, dynamic>?> _profileFuture;
  late Future<List<PostFeedModel>> _postsFuture;

  final FollowService _followService = FollowService();
  StreamSubscription? _profileUpdateSubscription;
  bool _isActionFromMe = false;

  bool isFollowing = false;
  bool isLoadingFollow = true;

  int _followerOffset = 0;

  @override
  void initState() {
    super.initState();
    _refreshData();
    _profileUpdateSubscription = GlobalEventBus().eventBus.on<ProfileUpdateEvent>().listen((event) {
      if (mounted && !_isActionFromMe) {
        _silentRefresh();
      }
    });
  }

  @override
  void dispose() {
    _profileUpdateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() {
      _profileFuture = AccountService().getUserProfile(widget.userId.toString());
      _postsFuture = PostService().fetchUserPosts(userId: widget.userId);
      _followerOffset = 0;
    });
    _checkFollowStatus();
  }

  Future<void> _handleStartChat(String name, String avatar) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.black)),
    );
    try {
      final groupId = await ChatService().createOrGet1v1Room(widget.userId);
      Navigator.pop(context);
      if (groupId != null) {
        Navigator.push(
          context,
          SlideRoute(
            page: ChatScreen(
              groupId: groupId,
              userName: name,
              avatarUrl: avatar,
              isOnline: true,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not connect to chat room!')),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      debugPrint("Lỗi điều hướng: $e");
    }
  }

  Future<void> _silentRefresh() async {
    try {
      final status = await _followService.checkIsFollowing(widget.userId);
      final profile = await AccountService().getUserProfile(widget.userId.toString());
      if (mounted) {
        setState(() {
          isFollowing = status;
          _profileFuture = Future.value(profile);
          _followerOffset = 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _checkFollowStatus() async {
    setState(() => isLoadingFollow = true);

    try {
      final status = await _followService.checkIsFollowing(widget.userId);
      if (mounted) {
        setState(() {
          isFollowing = status;
          isLoadingFollow = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          isLoadingFollow = false;
        });
      }
    }
  }

  Future<void> _toggleFollow() async {
    if (isFollowing) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Unfollow?',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              'Are you sure you want to unfollow this user?',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Unfollow',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );

      if (confirm != true) return;
    }

    final currentStatus = isFollowing;
    _isActionFromMe = true;

    setState(() {
      isFollowing = !currentStatus;
      _followerOffset += isFollowing ? 1 : -1;
    });

    try {
      final success = currentStatus
          ? await _followService.unfollowUser(widget.userId)
          : await _followService.followUser(widget.userId);

      if (!success && mounted) {
        setState(() {
          isFollowing = currentStatus;
          _followerOffset += isFollowing ? 1 : -1;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Action failed, please try again!'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          isFollowing = currentStatus;
          _followerOffset += isFollowing ? 1 : -1;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Action failed, please try again!'),
          ),
        );
      }
    } finally {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _isActionFromMe = false;
      });
    }
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
                  style: const TextStyle(color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final user = profileSnapshot.data;

          if (user == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'User information not found.',
                  style: TextStyle(color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final String avatar = (user['avatar'] ?? '').toString();
          final String name = (user['username'] ?? 'User').toString();
          final String email = (user['email'] ?? 'Updating...').toString();
          final String bio = (user['description'] ?? 'No bio available.').toString();

          final int baseFollowerCount = (user['followerCount'] ?? user['followers'] ?? 0) as int;
          final String followerCount = (baseFollowerCount + _followerOffset).toString();
          final String followingCount = (user['followingCount'] ?? user['following'] ?? 0).toString();

          final ImageProvider avatarProvider = avatar.isNotEmpty
              ? NetworkImage(avatar)
              : const AssetImage('assets/images/default_avatar.png');

          final ImageProvider coverProvider = avatar.isNotEmpty
              ? NetworkImage(avatar)
              : const NetworkImage('https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTNh6H5iL48BL9Ad0XApi7Q7hNrpNpukI3Xfw&s');

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
                        image: coverProvider,
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
                            Colors.white, // Vuốt tiệp màu với container nền trắng bên dưới
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
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      title: Text(
                        name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(color: Colors.black87, blurRadius: 10),
                          ],
                        ),
                      ),
                      centerTitle: true,
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: coverHeight - kToolbarHeight - profileOverlap,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [Colors.black87, Colors.black45],
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 42,
                                  backgroundColor: Colors.white,
                                  backgroundImage: avatarProvider,
                                ),
                              ),
                              const SizedBox(width: 16),
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
                                          final postCount = snapshot.hasData ? snapshot.data!.length.toString() : '0';
                                          return _buildStatItem(postCount, 'POSTS');
                                        },
                                      ),
                                      _buildStatItem(followerCount, 'FOLLOWERS'),
                                      _buildStatItem(followingCount, 'FOLLOWING'),
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
                          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
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
                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
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
                                  const SizedBox(height: 24),

                                  // Hàng nút 1: Follow & Message
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: isLoadingFollow ? null : _toggleFollow,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isFollowing ? Colors.black12 : Colors.black,
                                            foregroundColor: isFollowing ? Colors.black : Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            elevation: 0,
                                          ),
                                          child: isLoadingFollow
                                              ? const SizedBox(
                                            height: 16,
                                            width: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                              : Text(
                                            isFollowing ? 'FOLLOWING' : 'FOLLOW',
                                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.0),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => _handleStartChat(name, avatar),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.black,
                                            side: const BorderSide(color: Colors.black, width: 1.5),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                          ),
                                          child: const Text(
                                            'MESSAGE',
                                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.0),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // Hàng nút 2: Wardrobe & Visit Store
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              SlideRoute(page: PublicWardrobeScreen(accountId: widget.userId)),
                                            );
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.black,
                                            side: BorderSide(color: Colors.black.withOpacity(0.2), width: 1.5),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                          ),
                                          child: const Text(
                                            'WARDROBE',
                                            style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              SlideRoute(page: UserStorefrontScreen(userId: widget.userId, userName: name)),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: Colors.black,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              side: const BorderSide(color: Colors.black, width: 1.5),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            elevation: 0,
                                          ),
                                          child: const Text(
                                            'VISIT STORE',
                                            style: TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1.0),
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
                        if (postSnapshot.connectionState == ConnectionState.waiting) {
                          return const SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.all(40),
                                child: CircularProgressIndicator(color: Colors.black),
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
                                  style: const TextStyle(color: Colors.black54),
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
                                  style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
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
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: PostItem(
                                  post: post,
                                  isMyPost: false,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}