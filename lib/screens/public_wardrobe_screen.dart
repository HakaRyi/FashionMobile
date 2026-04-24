import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../models/public_wardrobe_item_model.dart';
import '../models/try_on_source_item.dart';
import '../screens/ai_suggestion_screen.dart';
import '../screens/public_item_detail_screen.dart';
import '../screens/try_on_screen.dart';
import '../services/item_service.dart';
import '../services/wardrobe_service.dart';
import '../utils/app_toast.dart';
import '../utils/route_transitions.dart';
import '../widgets/public_clothing_item.dart';

class PublicWardrobeScreen extends StatefulWidget {
  final int accountId;
  final bool isOwnerView;

  const PublicWardrobeScreen({
    super.key,
    required this.accountId,
    this.isOwnerView = false,
  });

  @override
  State<PublicWardrobeScreen> createState() => _PublicWardrobeScreenState();
}

class _PublicWardrobeScreenState extends State<PublicWardrobeScreen> {
  final WardrobeService _wardrobeService = WardrobeService();
  final ItemService _itemService = ItemService();

  bool _isLoading = true;
  String? _error;

  Map<String, dynamic>? _profile;
  List<PublicWardrobeItemModel> _items = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String _normalizeError(Object error) {
    final text = error.toString();

    if (text.startsWith('Exception: ')) {
      return text.replaceFirst('Exception: ', '').trim();
    }

    return text;
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final profile = await _wardrobeService.getPublicProfile(widget.accountId);
      final items = await _wardrobeService.getPublicWardrobeItems(
        widget.accountId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = profile;
        _items = items;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = _normalizeError(e);
      });
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  String get _userName {
    final name = _profile?['userName']?.toString().trim();

    if (name == null || name.isEmpty) {
      return 'User';
    }

    return name;
  }

  String? get _avatarUrl {
    final url = _profile?['avatarUrl']?.toString().trim();

    if (url == null || url.isEmpty) {
      return null;
    }

    return url;
  }

  int get _totalPublicItems {
    final value = _profile?['totalPublicItems'];

    if (value is int) {
      return value;
    }

    if (value is String) {
      return int.tryParse(value) ?? _items.length;
    }

    return _items.length;
  }

  int get _countFollower {
    final value = _profile?['countFollower'];

    if (value is int) {
      return value;
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }

  int get _countFollowing {
    final value = _profile?['countFollowing'];

    if (value is int) {
      return value;
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }

  String get _title {
    if (widget.isOwnerView) {
      return 'My Wardrobe';
    }

    return "$_userName's Wardrobe";
  }

  bool _isOwnItem(PublicWardrobeItemModel item) {
    return widget.isOwnerView || (item.isOwner ?? false);
  }

  Future<void> _toggleSaveItem(int index) async {
    final item = _items[index];

    if (_isOwnItem(item)) {
      AppToast.show(context, 'You cannot save your own item.');
      return;
    }

    try {
      if (item.isSaved == true) {
        await _itemService.unsaveItem(item.itemId);
      } else {
        await _itemService.saveItem(item.itemId);
      }

      if (!mounted) {
        return;
      }

      final bool newSavedState = !(item.isSaved ?? false);

      setState(() {
        _items[index] = item.copyWith(
          isSaved: newSavedState,
        );
      });

      AppToast.show(
        context,
        newSavedState ? 'Saved to favorites!' : 'Removed from favorites!',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      AppToast.show(context, _normalizeError(e));
    }
  }

  void _showActionMenu(BuildContext context, PublicWardrobeItemModel item) {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.menu,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.itemName?.trim().isNotEmpty == true
                      ? item.itemName!
                      : 'Unnamed item',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(
                    Icons.auto_awesome,
                    color: AppColors.text,
                  ),
                  title: const Text(
                    'AI outfit suggestion',
                    style: TextStyle(color: AppColors.text),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      SlideRoute(
                        page: AISuggestionScreen(selectedItem: item),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.face,
                    color: AppColors.text,
                  ),
                  title: const Text(
                    'Virtual try-on',
                    style: TextStyle(color: AppColors.text),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TryOnScreen(
                          sourceItem: TryOnSourceItem(
                            itemId: item.itemId,
                            itemName: item.itemName,
                            imageUrl: item.thumbnailUrl,
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
          ),
        );
      },
    );
  }

  void _openItemDetail(PublicWardrobeItemModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PublicItemDetailScreen(
          itemId: item.itemId,
          isOwnerView: _isOwnItem(item),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: AppColors.textPink,
        ),
      )
          : _error != null
          ? _buildError()
          : RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.textPink,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 240,
              pinned: true,
              backgroundColor: AppColors.background,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  _title,
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
                        return _buildHeaderPlaceholder();
                      },
                    )
                        : _buildHeaderPlaceholder(),
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
                    _buildStatItem(
                      '$_totalPublicItems',
                      widget.isOwnerView
                          ? 'Public items'
                          : 'Public items',
                    ),
                    _buildStatItem(
                      '$_countFollower',
                      'Followers',
                    ),
                    _buildStatItem(
                      '$_countFollowing',
                      'Following',
                    ),
                  ],
                ),
              ),
            ),
            if (widget.isOwnerView)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                  child: _buildOwnerNotice(),
                ),
              ),
            if (_items.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 40,
                  ),
                  child: Center(
                    child: Text(
                      widget.isOwnerView
                          ? 'You have no public wardrobe items yet.'
                          : 'This user has no public wardrobe items yet.',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final item = _items[index];
                      final isOwnItem = _isOwnItem(item);

                      return PublicClothingItem(
                        itemId: item.itemId,
                        title: item.itemName ?? '',
                        imageUrl: item.thumbnailUrl ?? '',
                        isSaved: item.isSaved ?? false,
                        showSaveButton: !isOwnItem,
                        likes: 0,
                        isForSale: item.isForSale,
                        listedPrice: item.listedPrice,
                        onTap: () => _openItemDetail(item),
                        onSave: () => _toggleSaveItem(index),
                        onLongPress: () =>
                            _showActionMenu(context, item),
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

  Widget _buildHeaderPlaceholder() {
    return Container(
      color: Colors.black26,
      child: const Icon(
        Icons.person,
        color: Colors.white,
        size: 80,
      ),
    );
  }

  Widget _buildOwnerNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.textPink,
            size: 22,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'This is your public wardrobe view. Other users can see these public items, but owner-only actions are hidden here.',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
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
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text(
              'Failed to load wardrobe',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textPink,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
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