import 'dart:async';
import 'package:fashion_mobile/services/follow_service.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/search_model.dart';
import '../../services/search_service.dart';
import '../../utils/global_event_bus.dart';
import '../../utils/route_transitions.dart';
import '../other_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final SearchService _searchService = SearchService();
  final FollowService _followService = FollowService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  StreamSubscription? _profileUpdateSubscription;

  List<SearchHistoryModel> _history = [];
  List<UserSuggestionModel> _suggestions = [];
  List<UserSuggestionModel> _searchResults = [];

  bool _isLoadingInitial = true;
  bool _isLoadingSearch = false;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _profileUpdateSubscription = GlobalEventBus()
        .eventBus
        .on<ProfileUpdateEvent>()
        .listen((event) async {
      if (mounted) {
        final status = await _followService.checkIsFollowing(event.targetUserId);

        setState(() {
          for (var user in _suggestions) {
            if (user.accountId == event.targetUserId) {
              user.isFollowing = status;
            }
          }
          for (var user in _searchResults) {
            if (user.accountId == event.targetUserId) {
              user.isFollowing = status;
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _profileUpdateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final results = await Future.wait([
        _searchService.getSearchHistory(),
        _searchService.getTopInfluencers(),
      ]);

      if (mounted) {
        setState(() {
          _history = results[0] as List<SearchHistoryModel>;
          _suggestions = results[1] as List<UserSuggestionModel>;
          _isLoadingInitial = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingInitial = false);
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    setState(() {
      _searchQuery = query;
    });

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
        _isLoadingSearch = false;
      });
      return;
    }

    setState(() => _isLoadingSearch = true);

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final results = await _searchService.searchUsers(query.trim());
        if (mounted && _searchQuery == query) {
          setState(() {
            _searchResults = results;
            _isLoadingSearch = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoadingSearch = false);
        }
      }
    });
  }

  Future<void> _onSubmitSearch(String query) async {
    if (query.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    await _searchService.addSearchHistory(query.trim());
    final updatedHistory = await _searchService.getSearchHistory();
    if (mounted) {
      setState(() {
        _history = updatedHistory;
      });
    }
  }

  Future<void> _clearHistory() async {
    setState(() => _history.clear());
    await _searchService.clearSearchHistory();
  }

  void _navigateToProfile(int accountId) {
    Navigator.push(
      context,
      SlideRoute(page: OtherProfileScreen(userId: accountId)),
    );
  }

  Future<void> _handleToggleFollow(UserSuggestionModel user) async {
    final bool currentFollowState = user.isFollowing;

    setState(() {
      user.isFollowing = !currentFollowState;
    });

    final success = currentFollowState
        ? await _followService.unfollowUser(user.accountId)
        : await _followService.followUser(user.accountId);

    if (!success && mounted) {
      setState(() {
        user.isFollowing = currentFollowState;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update, please try again!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Nền xám nhạt cho đồng bộ Minimalist
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        titleSpacing: 20,
        title: const Text(
          "Search",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 26,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            if (_isLoadingInitial)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(
                  child: CircularProgressIndicator(color: Colors.black),
                ),
              )
            else if (_searchQuery.isEmpty) ...[
              if (_history.isNotEmpty) ...[
                _buildSectionTitleWithAction(
                    "RECENT SEARCHES",
                    "Clear",
                    _clearHistory
                ),
                _buildSearchHistory(),
              ],
              _buildSectionTitle("SUGGESTIONS FOR YOU"),
              _buildSuggestedProfiles(_suggestions),
            ] else ...[
              _buildSectionTitle("SEARCH RESULTS"),
              if (_isLoadingSearch)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  ),
                )
              else if (_searchResults.isEmpty)
                _buildEmptyState()
              else
                _buildSuggestedProfiles(_searchResults),
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          onSubmitted: _onSubmitSearch,
          textInputAction: TextInputAction.search,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: "Search by username or name...",
            hintStyle: TextStyle(color: Colors.black.withOpacity(0.3), fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: Colors.black),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.close, color: Colors.black, size: 20),
              onPressed: () {
                _searchController.clear();
                _onSearchChanged("");
                FocusScope.of(context).unfocus();
              },
            )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitleWithAction(String title, String actionTitle, VoidCallback onAction) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 16, top: 20, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionTitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black.withOpacity(0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHistory() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 0,
        children: _history.map((item) => ActionChip(
          label: Text(item.keyword),
          backgroundColor: Colors.white,
          side: BorderSide(color: Colors.black.withOpacity(0.08)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          labelStyle: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w500),
          onPressed: () {
            _searchController.text = item.keyword;
            _onSearchChanged(item.keyword);
          },
        )).toList(),
      ),
    );
  }

  Widget _buildSuggestedProfiles(List<UserSuggestionModel> users) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildProfileCard(user: users[index]),
        );
      },
    );
  }

  Widget _buildProfileCard({required UserSuggestionModel user}) {
    final avatar = user.avatarUrl.isNotEmpty
        ? NetworkImage(user.avatarUrl)
        : const AssetImage('assets/images/default_avatar.png') as ImageProvider;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToProfile(user.accountId),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black.withOpacity(0.05), width: 1),
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.surface,
                  backgroundImage: avatar,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName.isNotEmpty ? user.fullName : user.username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "@${user.username}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.5),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${user.followerCount} followers",
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.3),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildFollowButton(user),
            ],
          ),
        ),
      ),
    );
  }

  // HÀM NÀY LÀ HÀM BỊ THIẾU Ở TRÊN ĐÂY ÔNG ƠI
  Widget _buildFollowButton(UserSuggestionModel user) {
    final bool following = user.isFollowing;
    return GestureDetector(
      onTap: () => _handleToggleFollow(user),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: following ? Colors.white : Colors.black,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: following ? Colors.black.withOpacity(0.1) : Colors.black),
        ),
        child: Text(
          following ? "Following" : "Follow",
          style: TextStyle(
            color: following ? Colors.black : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 60, color: Colors.black12),
            SizedBox(height: 16),
            Text(
              "No user found",
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 32, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: Colors.black,
        ),
      ),
    );
  }
}