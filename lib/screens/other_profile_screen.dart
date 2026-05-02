// lib/screens/other_profile_screen.dart
import 'dart:async';

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

  const OtherProfileScreen({
    super.key,
    required this.userId,
  });

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

    _profileUpdateSubscription =
        GlobalEventBus().eventBus.on<ProfileUpdateEvent>().listen((event) {
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
      _profileFuture = AccountService().getUserProfile(
        widget.userId.toString(),
      );
      _postsFuture = PostService().fetchUserPosts(
        userId: widget.userId,
      );
      _followerOffset = 0;
    });

    _checkFollowStatus();
  }

  Future<void> _handleStartChat(String name, String avatar) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(
            color: Colors.pink,
          ),
        );
      },
    );

    try {
      final groupId = await ChatService().createOrGet1v1Room(widget.userId);

      if (!mounted) {
        return;
      }

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
          const SnackBar(
            content: Text('Could not connect to chat room!'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      Navigator.pop(context);
      print("Lỗi điều hướng: $e");
    }
  }

  Future<void> _silentRefresh() async {
    try {
      final status = await _followService.checkIsFollowing(widget.userId);
      final profile = await AccountService().getUserProfile(
        widget.userId.toString(),
      );

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
    setState(() {
      isLoadingFollow = true;
    });

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
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.black54,
                  ),
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

      if (confirm != true) {
        return;
      }
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
        if (mounted) {
          _isActionFromMe = false;
        }
      });
    }
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
              child: CircularProgressIndicator(
                color: Colors.pink,
              ),
            );
          }

          if (profileSnapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load profile: ${profileSnapshot.error}',
                  style: const TextStyle(
                    color: Colors.white70,
                  ),
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
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final String avatar = (user['avatar'] ?? '').toString();
          final String name = (user['username'] ?? 'User').toString();
          final String description =
          (user['description'] ?? 'No description available.').toString();

          final int baseFollowerCount =
          (user['followerCount'] ?? user['followers'] ?? 0) as int;

          final String followerCount =
          (baseFollowerCount + _followerOffset).toString();

          final String followingCount =
          (user['followingCount'] ?? user['following'] ?? 0).toString();

          final ImageProvider avatarProvider = avatar.isNotEmpty
              ? NetworkImage(avatar)
              : const AssetImage('assets/images/default_avatar.png');

          final ImageProvider coverProvider = avatar.isNotEmpty
              ? NetworkImage(avatar)
              : const NetworkImage(
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTNh6H5iL48BL9Ad0XApi7Q7hNrpNpukI3Xfw&s',
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
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      title: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          shadows: [
                            Shadow(
                              color: Colors.white,
                              blurRadius: 5,
                            ),
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
                                  backgroundImage: avatarProvider,
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
                              padding:
                              const EdgeInsets.fromLTRB(20, 20, 10, 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          description.trim().isEmpty
                                              ? 'No description available.'
                                              : description,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.black38,
                                            fontSize: 14,
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        SlideRoute(
                                          page: PublicWardrobeScreen(
                                            accountId: widget.userId,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                            Colors.black.withOpacity(0.2),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.checkroom_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: GestureDetector(
                                      onTap: isLoadingFollow
                                          ? null
                                          : _toggleFollow,
                                      child: Container(
                                        height: 46,
                                        decoration: BoxDecoration(
                                          color: isFollowing
                                              ? Colors.transparent
                                              : Colors.black,
                                          borderRadius:
                                          BorderRadius.circular(12),
                                          border: isFollowing
                                              ? Border.all(
                                            color: Colors.black12,
                                            width: 1.5,
                                          )
                                              : null,
                                        ),
                                        alignment: Alignment.center,
                                        child: isLoadingFollow
                                            ? SizedBox(
                                          height: 16,
                                          width: 16,
                                          child:
                                          CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: isFollowing
                                                ? Colors.black
                                                : Colors.white,
                                          ),
                                        )
                                            : FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            isFollowing
                                                ? 'Following'
                                                : 'Follow',
                                            maxLines: 1,
                                            style: TextStyle(
                                              color: isFollowing
                                                  ? Colors.black
                                                  : Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 1,
                                    child: GestureDetector(
                                      onTap: () =>
                                          _handleStartChat(name, avatar),
                                      child: Container(
                                        height: 46,
                                        decoration: BoxDecoration(
                                          color: Colors.transparent,
                                          borderRadius:
                                          BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.black12,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.messenger_outline_rounded,
                                              size: 17,
                                              color: Colors.black,
                                            ),
                                            SizedBox(width: 5),
                                            Flexible(
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  'Chat',
                                                  maxLines: 1,
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontWeight:
                                                    FontWeight.w800,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
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
                                  'Failed to load posts: ${postSnapshot.error}',
                                  style: const TextStyle(
                                    color: Colors.black26,
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
                                    color: Colors.black26,
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
                                color: AppColors.background,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}