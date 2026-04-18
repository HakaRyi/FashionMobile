// lib/screens/public_wardrobe_screen.dart
import 'package:fashion_mobile/screens/public_item_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../models/try_on_source_item.dart';
import '../models/wardrobe_item_model.dart';
import '../services/item_service.dart';
import '../services/wardrobe_service.dart';
import '../widgets/public_clothing_item.dart';
import '../utils/app_toast.dart';
import '../utils/route_transitions.dart';
import '../screens/ai_suggestion_screen.dart';
import '../screens/try_on_screen.dart';
class PublicWardrobeScreen extends StatefulWidget {
  final int accountId;

  const PublicWardrobeScreen({
    super.key,
    required this.accountId,
  });

  @override
  State<PublicWardrobeScreen> createState() => _PublicWardrobeScreenState();
}

class _PublicWardrobeScreenState extends State<PublicWardrobeScreen> {
  final WardrobeService _wardrobeService = WardrobeService();

  bool _isLoading = true;
  String? _error;

  Map<String, dynamic>? _profile;
  List<WardrobeItemModel> _items = [];
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  void _showActionMenu(BuildContext context, WardrobeItemModel item) {
    // Rung nhẹ một cái cho cảm giác thật
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.menu,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tiêu đề nhỏ cho Menu
              Text(
                item.itemName,
                style: const TextStyle(color: AppColors.text, fontSize: 12),
              ),
              const SizedBox(height: 10),

              // Option 1: AI Gợi ý phối đồ
              ListTile(
                leading: const Icon(Icons.auto_awesome, color: AppColors.text),
                title: const Text("AI gợi ý phối đồ", style: TextStyle(color: AppColors.text)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                      context,
                      SlideRoute(page: AISuggestionScreen(selectedItem: item))
                  );
                },
              ),

              // Option 2: Thử đồ ảo (Try-on)
              ListTile(
                leading: const Icon(Icons.face, color: AppColors.text),
                title: const Text("Thử đồ ảo", style: TextStyle(color: AppColors.text)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  // Đăng chuyển hướng qua màn hình TryOnScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TryOnScreen(
                        sourceItem: TryOnSourceItem(
                          itemId: item.itemId,
                          itemName: item.itemName,
                          imageUrl: item.imageUrl,
                          brand: item.brand,
                          category: item.category,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final profile = await _wardrobeService.getPublicProfile(widget.accountId);
      final items = await _wardrobeService.getPublicWardrobeItems(widget.accountId);

      setState(() {
        _profile = profile;
        _items = items;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String get _userName {
    final name = _profile?['userName']?.toString().trim();
    if (name == null || name.isEmpty) return 'Người dùng';
    return name;
  }

  String? get _avatarUrl {
    final url = _profile?['avatarUrl']?.toString();
    if (url == null || url.isEmpty) return null;
    return url;
  }

  String get _description {
    final desc = _profile?['description']?.toString().trim();
    if (desc == null || desc.isEmpty) return 'Chưa có mô tả';
    return desc;
  }

  int get _totalPublicItems {
    final value = _profile?['totalPublicItems'];
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? _items.length;
    return _items.length;
  }

  int get _countFollower {
    final value = _profile?['countFollower'];
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  int get _countFollowing {
    final value = _profile?['countFollowing'];
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 240.0,
              pinned: true,
              backgroundColor: AppColors.background,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  "$_userName's Wardrobe",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    _avatarUrl != null
                        ? Image.network(
                      _avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return Container(
                          color: AppColors.text,
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 80,
                          ),
                        );
                      },
                    )
                        : Container(
                      color: Colors.black26,
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 80,
                      ),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.background,
                          ],
                        ),
                      ),
                    ),
                    // Positioned(
                    //   left: 16,
                    //   right: 16,
                    //   bottom: 70,
                    //   child: Column(
                    //     crossAxisAlignment: CrossAxisAlignment.start,
                    //     children: [
                    //       Text(
                    //         _userName,
                    //         style: const TextStyle(
                    //           color: Colors.white,
                    //           fontSize: 22,
                    //           fontWeight: FontWeight.bold,
                    //         ),
                    //       ),
                    //       const SizedBox(height: 6),
                    //       Text(
                    //         _description,
                    //         maxLines: 2,
                    //         overflow: TextOverflow.ellipsis,
                    //         style: const TextStyle(
                    //           color: Colors.white70,
                    //           fontSize: 13,
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem("$_totalPublicItems", "Item public"),
                    _buildStatItem("$_countFollower", "Follower"),
                    _buildStatItem("$_countFollowing", "Following"),
                  ],
                ),
              ),
            ),

            if (_items.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  child: Center(
                    child: Text(
                      "Người dùng này chưa có món đồ công khai nào.",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final item = _items[index];
                      return PublicClothingItem(
                        itemId: item.itemId,
                        title: item.itemName,
                        imageUrl: item.imageUrl ?? '',
                        isSaved: item.isSaved,
                        showSaveButton: !item.isOwner,
                        likes: 0,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PublicItemDetailScreen(itemId: item.itemId),
                            ),
                          );
                        },
                        onSave: () async {
                          bool success = false;
                          bool currentStatus = item.isSaved;
                          // Dùng service để save/unsave dựa vào trạng thái hiện tại
                          if (item.isSaved) {
                            success = await ItemService().unsaveItem(item.itemId);
                          } else {
                            success = await ItemService().saveItem(item.itemId);
                          }

                          if (success && mounted) {
                            setState(() {
                              // Cập nhật state local để tim đổi màu ngay lập tức
                              _items[index] = item.copyWith(isSaved: !item.isSaved);
                            });
                            AppToast.show(context, item.isSaved ? "Đã bỏ lưu!" : "Đã lưu vào yêu thích!");
                          }
                        },
                        onLongPress: () => _showActionMenu(context, item),
                      );
                    },
                    childCount: _items.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 30),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Không thể tải tủ đồ công khai',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Đã có lỗi xảy ra',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}