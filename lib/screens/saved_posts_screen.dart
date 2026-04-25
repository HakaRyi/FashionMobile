import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../managers/post_manager.dart';
import '../models/public_wardrobe_item_model.dart';
import '../services/item_service.dart';
import '../utils/app_toast.dart';
import '../widgets/clothing_item.dart';
import '../widgets/post_item.dart';
import 'clothing_detail_screen.dart';

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  final ItemService _itemService = ItemService();

  List<PublicWardrobeItemModel> _savedItems = [];
  bool _isLoadingItems = false;

  @override
  void initState() {
    super.initState();

    postManager.addListener(_onManagerChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadInitialData();
      }
    });
  }

  @override
  void dispose() {
    postManager.removeListener(_onManagerChanged);
    super.dispose();
  }

  void _onManagerChanged() {
    if (!mounted) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _loadInitialData() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoadingItems = true;
    });

    try {
      await Future.wait([
        postManager.fetchSavedPosts(refresh: true),
        _fetchSavedItems(),
      ]);
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingItems = false;
        });
      }
    }
  }

  Future<void> _fetchSavedItems() async {
    final items = await _itemService.getSavedItems();

    if (!mounted) {
      return;
    }

    setState(() {
      _savedItems = items;
    });
  }

  Future<void> _handleUnsave(int itemId) async {
    try {
      await _itemService.unsaveItem(itemId);

      if (!mounted) {
        return;
      }

      AppToast.show(context, 'Removed from saved items.');
      await _fetchSavedItems();
    } catch (e) {
      if (!mounted) {
        return;
      }

      AppToast.show(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Map<String, dynamic> _mapSavedItemToData(PublicWardrobeItemModel item) {
    final imageUrl = item.thumbnailUrl ?? '';

    return {
      'itemId': item.itemId,
      'itemName': item.itemName ?? '',
      'title': item.itemName ?? '',

      'itemType': item.itemType ?? '',
      'category': item.category ?? '',
      'subCategory': item.subCategory ?? '',
      'style': item.style ?? '',
      'gender': item.gender ?? '',

      'mainColor': item.mainColor ?? '',
      'subColor': item.subColor ?? '',
      'material': item.material ?? '',
      'pattern': item.pattern ?? '',
      'fit': item.fit ?? '',
      'size': item.size ?? '',
      'brand': item.brand ?? '',
      'description': item.description ?? '',

      'imageUrl': imageUrl,
      'primaryImageUrl': imageUrl,
      'thumbnailUrl': imageUrl,

      'createdAt': item.createdAt?.toIso8601String(),
      'updateAt': null,

      'isPublic': true,
      'status': 1,

      'isSaved': item.isSaved ?? true,
      'isOwner': item.isOwner ?? false,
      'isForSale': item.isForSale,
      'listedPrice': item.listedPrice,
      'condition': item.condition,
    };
  }

  void _openItemDetail(PublicWardrobeItemModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClothingDetailScreen(
          itemData: _mapSavedItemToData(item),
          showEditButton: false,
        ),
      ),
    );
  }

  void _showUnsaveOptions(PublicWardrobeItemModel item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                item.itemName?.trim().isNotEmpty == true
                    ? item.itemName!
                    : 'This item',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(
                  Icons.bookmark_remove,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Unsave the item',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _handleUnsave(item.itemId);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _refreshPosts() async {
    await postManager.fetchSavedPosts(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF5F5F5),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          title: const Text(
            'My saved',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.black,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.black54,
            tabs: [
              Tab(text: 'Posts'),
              Tab(text: 'Items'),
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
      return const Center(
        child: CircularProgressIndicator(color: Colors.black),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshPosts,
      color: Colors.black,
      backgroundColor: Colors.white,
      child: posts.isEmpty
          ? _buildEmptyState(
        Icons.bookmark_outline,
        'No posts saved yet.',
      )
          : ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          return PostItem(post: posts[index]);
        },
      ),
    );
  }

  Widget _buildItemsTab() {
    if (_isLoadingItems && _savedItems.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.black),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchSavedItems,
      color: Colors.black,
      backgroundColor: Colors.white,
      child: _savedItems.isEmpty
          ? _buildEmptyState(
        Icons.checkroom_outlined,
        'No items have been saved yet.',
      )
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
          final itemData = _mapSavedItemToData(item);

          return ClothingItem(
            itemData: itemData,
            onTap: () => _openItemDetail(item),
            customActionIcon: Icons.bookmark_remove,
            customActionLabel: 'Unsave Item',
            customActionColor: Colors.orange,
            onCustomAction: () => _showUnsaveOptions(item),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Icon(
          icon,
          size: 80,
          color: AppColors.text,
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            message,
            style: const TextStyle(color: AppColors.text),
          ),
        ),
      ],
    );
  }
}