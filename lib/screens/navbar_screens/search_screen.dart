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
  final FollowService _followService = FollowService() ;
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
        const SnackBar(content: Text('Không thể thực hiện, vui lòng thử lại!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          "Tìm kiếm",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
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
                  child: CircularProgressIndicator(color: Colors.pinkAccent),
                ),
              )
            else if (_searchQuery.isEmpty) ...[
              if (_history.isNotEmpty) ...[
                _buildSectionTitleWithAction(
                    "Lịch sử tìm kiếm",
                    "Xóa",
                    _clearHistory
                ),
                _buildSearchHistory(),
              ],
              _buildSectionTitle("Gợi ý cho bạn"),
              _buildSuggestedProfiles(_suggestions),
            ] else ...[
              _buildSectionTitle("Kết quả tìm kiếm"),
              if (_isLoadingSearch)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.pinkAccent),
                  ),
                )
              else if (_searchResults.isEmpty)
                _buildEmptyState()
              else
                _buildSuggestedProfiles(_searchResults),
            ],
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
          color: Colors.pink.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.pink.withOpacity(0.1)),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          onSubmitted: _onSubmitSearch,
          textInputAction: TextInputAction.search,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: "Tìm kiếm người dùng hoặc xu hướng...",
            hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: Colors.pinkAccent),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionTitle,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
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
        runSpacing: 8,
        children: _history.map((item) => ActionChip(
          label: Text(item.keyword),
          avatar: const Icon(Icons.history, size: 16, color: AppColors.textPrimary),
          backgroundColor: Colors.grey[800],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          onPressed: () {
            _searchController.text = item.keyword;
            _onSearchChanged(item.keyword);
          },
        )).toList(),
      ),
    );
  }

  Widget _buildSuggestedProfiles(List<UserSuggestionModel> users) {
    return Column(
      children: [
        const Divider(
          height: 1,
          thickness: 1,
          color: Color(0xFF2C2C2C),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: users.length,
          padding: EdgeInsets.zero,
          itemBuilder: (context, index) {
            final user = users[index];
            return Column(
              children: [
                _buildProfileCard(
                  user: user,
                ),
                if (index < users.length - 1)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 90,
                    color: Color(0xFF2C2C2C),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildProfileCard({required UserSuggestionModel user}) {
    final avatarUrl = user.avatarUrl.isNotEmpty
        ? user.avatarUrl
        : 'https://i.pravatar.cc/150?u=${user.accountId}';

    return InkWell(
      onTap: () => _navigateToProfile(user.accountId),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.pinkAccent.withOpacity(0.3), width: 2),
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white10,
                backgroundImage: NetworkImage(avatarUrl),
                onBackgroundImageError: (_, __) {},
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName.isNotEmpty ? user.fullName : user.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "@${user.username}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.pinkAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${user.followerCount} người theo dõi",
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _handleToggleFollow(user),
              style: ElevatedButton.styleFrom(
                backgroundColor: user.isFollowing ? Colors.white24 : Colors.pinkAccent.withOpacity(0.1),
                foregroundColor: user.isFollowing ? Colors.white : Colors.pinkAccent,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                user.isFollowing ? "Đang theo dõi" : "Theo dõi",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 60, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              "Không tìm thấy người dùng",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Thử tìm kiếm với một từ khóa khác xem sao.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
// <--- KẾT THÚC SỬA

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 20, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}