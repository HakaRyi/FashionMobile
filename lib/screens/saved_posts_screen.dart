// lib/screens/saved_posts_screen.dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../managers/post_manager.dart';
import '../models/post_feed_model.dart';
import '../widgets/post_item.dart';
import '../widgets/clothing_item.dart';
import '../services/item_service.dart';
import 'clothing_detail_screen.dart';
import '../utils/app_toast.dart';
class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  final ItemService _itemService = ItemService();
  List<dynamic> _savedItems = [];
  bool _isLoadingItems = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    postManager.addListener(_onManagerChanged);
  }

  @override
  void dispose() {
    postManager.removeListener(_onManagerChanged);
    super.dispose();
  }

  void _onManagerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingItems = true);
    try {
      await Future.wait([
        postManager.fetchSavedPosts(refresh: true),
        _fetchSavedItems(),
      ]);
    } finally {
      if (mounted) setState(() => _isLoadingItems = false);
    }
  }
  void _showUnsaveOptions(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom:20),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            Text(
              item['itemName'] ?? "Món đồ này",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.bookmark_remove, color: Colors.redAccent),
              title: const Text("Bỏ lưu món đồ", style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                Navigator.pop(context); // Đóng bottom sheet
                _handleUnsave(item['itemId']);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
  Future<void> _handleUnsave(int itemId) async {
    final success = await _itemService.unsaveItem(itemId);
    if (success) {
      if (mounted) {
        AppToast.show(context, "Đã bỏ lưu món đồ!");
      }
      _fetchSavedItems();
    } else {
      if (mounted) {
        AppToast.show(context, "Thao tác thất bại!", isError: true);
      }
    }
  }
  Future<void> _fetchSavedItems() async {
    final items = await _itemService.getSavedItems();
    if (mounted) {
      setState(() {
        _savedItems = items;
      });
    }
  }

  void _openItemDetail(Map<String, dynamic> itemData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClothingDetailScreen(
          itemData: itemData,
          showEditButton: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          centerTitle: true,
          title: const Text('Nội dung đã lưu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            indicatorColor: Colors.pink,
            labelColor: Colors.pink,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: "Bài viết"),
              Tab(text: "Món đồ"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPostsTab(),
            _buildItemsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsTab() {
    final posts = postManager.savedPosts;
    if (postManager.isLoadingSaved && posts.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Colors.pink));
    }
    return RefreshIndicator(
      onRefresh: () => postManager.fetchSavedPosts(refresh: true),
      child: posts.isEmpty
          ? _buildEmptyState(Icons.bookmark_outline, "Chưa lưu bài viết nào")
          : ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: posts.length,
        itemBuilder: (context, index) => PostItem(post: posts[index]),
      ),
    );
  }

  Widget _buildItemsTab() {
    if (_isLoadingItems && _savedItems.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Colors.pink));
    }
    return RefreshIndicator(
      onRefresh: _fetchSavedItems,
      child: _savedItems.isEmpty
          ? _buildEmptyState(Icons.checkroom_outlined, "Chưa lưu món đồ nào")
          : GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: _savedItems.length,
        itemBuilder: (context, index) {
          final item = _savedItems[index];
          return ClothingItem(
            title: item['itemName'] ?? "Không tên",
            imageUrl: item['primaryImageUrl'],
            onTap: () => _openItemDetail(item),
            onLongPress: () => _showUnsaveOptions(item)
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Icon(icon, size: 80, color: Colors.white10),
        const SizedBox(height: 16),
        Center(child: Text(message, style: const TextStyle(color: Colors.white38))),
      ],
    );
  }
}