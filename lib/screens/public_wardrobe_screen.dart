import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class _PublicWardrobeScreenState extends State<PublicWardrobeScreen>
    with SingleTickerProviderStateMixin {
  final WardrobeService _wardrobeService = WardrobeService();
  final ItemService _itemService = ItemService();

  bool _isLoading = true;
  String? _error;

  Map<String, dynamic>? _profile;
  List<PublicWardrobeItemModel> _items = [];

  String _selectedFilter = 'All';

  late AnimationController _fabricController;

  @override
  void initState() {
    super.initState();

    _fabricController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _loadData();
  }

  @override
  void dispose() {
    _fabricController.dispose();
    super.dispose();
  }

  String _normalizeError(Object error) {
    final text = error.toString();

    if (text.startsWith('Exception: ')) {
      return text.replaceFirst('Exception: ', '').trim();
    }

    return text;
  }

  List<String> _getDynamicFilters() {
    final filters = <String>{'All'};

    for (final item in _items) {
      final category = item.category?.trim();

      if (category != null && category.isNotEmpty) {
        filters.add(category);
      }
    }

    return filters.toList();
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
      return 'MY WARDROBE';
    }

    return "$_userName's Wardrobe".toUpperCase();
  }

  bool _isOwnItem(PublicWardrobeItemModel item) {
    return widget.isOwnerView || (item.isOwner ?? false);
  }

  List<PublicWardrobeItemModel> get _filteredItems {
    if (_selectedFilter == 'All') {
      return _items;
    }

    return _items.where((item) => item.category == _selectedFilter).toList();
  }

  Future<void> _toggleSaveItem(PublicWardrobeItemModel item) async {
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

      final newSavedState = !(item.isSaved ?? false);

      setState(() {
        final index = _items.indexWhere((i) => i.itemId == item.itemId);

        if (index != -1) {
          _items[index] = item.copyWith(isSaved: newSavedState);
        }
      });

      AppToast.show(
        context,
        newSavedState ? 'Saved to favorites!' : 'Removed from favorites!',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      AppToast.show(
        context,
        _normalizeError(e),
        isError: true,
      );
    }
  }

  void _showActionMenu(BuildContext context, PublicWardrobeItemModel item) {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  item.itemName?.trim().isNotEmpty == true
                      ? item.itemName!.toUpperCase()
                      : 'UNNAMED ITEM',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSheetAction(
                  icon: Icons.auto_awesome,
                  title: 'AI Mix & Match',
                  subtitle: 'Find outfits that match this item',
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
                _buildSheetAction(
                  icon: Icons.face,
                  title: 'Virtual Try-on',
                  subtitle: 'Preview this item on your model',
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

  Widget _buildSheetAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 4,
      ),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: Colors.black,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w900,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Colors.black45,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        color: Colors.black12,
        size: 14,
      ),
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
    final filters = _getDynamicFilters();
    final filteredItems = _filteredItems;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _fabricController,
              builder: (context, child) {
                return CustomPaint(
                  painter: FabricPainter(_fabricController.value),
                );
              },
            ),
          ),
          Positioned.fill(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(
                color: Colors.black,
              ),
            )
                : _error != null
                ? _buildError()
                : RefreshIndicator(
              onRefresh: _loadData,
              color: Colors.black,
              backgroundColor: Colors.white,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  _buildSliverAppBar(),
                  SliverToBoxAdapter(
                    child: _buildProfileSummary(),
                  ),
                  if (widget.isOwnerView)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding:
                        const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        child: _buildOwnerNotice(),
                      ),
                    ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _CategoryHeaderDelegate(
                      child: _buildCategoryTabs(filters),
                    ),
                  ),
                  if (_items.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(
                        widget.isOwnerView
                            ? 'You have no public wardrobe items yet.'
                            : 'This user has no public items yet.',
                      ),
                    )
                  else if (filteredItems.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(
                        'No items found in this category.',
                      ),
                    )
                  else
                    SliverPadding(
                      padding:
                      const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      sliver: SliverGrid(
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.72,
                        ),
                        delegate: SliverChildBuilderDelegate(
                              (context, index) {
                            final item = filteredItems[index];

                            return PublicClothingItem(
                              itemId: item.itemId,
                              title: item.itemName ?? '',
                              imageUrl: item.thumbnailUrl ?? '',
                              isSaved: item.isSaved ?? false,
                              showSaveButton: !_isOwnItem(item),
                              likes: 0,
                              isForSale: item.isForSale,
                              listedPrice: item.listedPrice,
                              onTap: () => _openItemDetail(item),
                              onSave: () => _toggleSaveItem(item),
                              onLongPress: () {
                                _showActionMenu(context, item);
                              },
                            );
                          },
                          childCount: filteredItems.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: const Color(0xFFF5F5F5),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.black,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        _title,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
      centerTitle: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            _avatarUrl != null
                ? Image.network(
              _avatarUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return _buildPlaceholderCover();
              },
            )
                : _buildPlaceholderCover(),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.25),
                    Colors.white.withOpacity(0.75),
                    const Color(0xFFF5F5F5),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 78,
                    height: 78,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _avatarUrl != null
                          ? Image.network(
                        _avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return _avatarPlaceholderIcon();
                        },
                      )
                          : _avatarPlaceholderIcon(),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.isOwnerView
                                ? 'Public wardrobe preview'
                                : 'Public wardrobe collection',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSummary() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                '$_totalPublicItems',
                'ITEMS',
              ),
            ),
            _verticalDivider(),
            Expanded(
              child: _buildStatItem(
                '$_countFollower',
                'FOLLOWERS',
              ),
            ),
            _verticalDivider(),
            Expanded(
              child: _buildStatItem(
                '$_countFollowing',
                'FOLLOWING',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 34,
      color: const Color(0xFFEDEDED),
    );
  }

  Widget _buildCategoryTabs(List<String> filters) {
    return Container(
      color: const Color(0xFFF5F5F5),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: SizedBox(
        height: 40,
        child: filters.length <= 1
            ? Align(
          alignment: Alignment.centerLeft,
          child: _categoryChip(
            name: 'All',
            isSelected: true,
          ),
        )
            : ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final name = filters[index];
            final isSelected = _selectedFilter == name;

            return _categoryChip(
              name: name,
              isSelected: isSelected,
            );
          },
        ),
      ),
    );
  }

  Widget _categoryChip({
    required String name,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = name;
        });
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.black.withOpacity(0.06),
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ]
              : null,
        ),
        child: Text(
          name.toUpperCase(),
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black54,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderCover() {
    return Container(
      color: const Color(0xFFEDEDED),
      child: const Center(
        child: Icon(
          Icons.checkroom,
          color: Colors.black26,
          size: 84,
        ),
      ),
    );
  }

  Widget _avatarPlaceholderIcon() {
    return Container(
      color: const Color(0xFFF1F1F1),
      child: const Icon(
        Icons.person,
        color: Colors.black26,
        size: 36,
      ),
    );
  }

  Widget _buildOwnerNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.black,
            size: 22,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'This is your public wardrobe view. Other users can see these public items, but owner-only actions are hidden here.',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
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
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: _cardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.black,
                size: 48,
              ),
              const SizedBox(height: 12),
              const Text(
                'Failed to load public wardrobe',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? 'An unknown error occurred',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loadData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'TRY AGAIN',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 72,
              color: Colors.black12,
            ),
            const SizedBox(height: 16),
            Text(
              message.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black26,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
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
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black45,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: Colors.black.withOpacity(0.05),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}

class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _CategoryHeaderDelegate({
    required this.child,
  });

  @override
  double get minExtent => 60;

  @override
  double get maxExtent => 60;

  @override
  Widget build(
      BuildContext context,
      double shrinkOffset,
      bool overlapsContent,
      ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _CategoryHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

class FabricPainter extends CustomPainter {
  final double animationValue;

  FabricPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = Colors.black.withOpacity(0.025)
      ..style = PaintingStyle.fill;
    final paint2 = Paint()
      ..color = Colors.black.withOpacity(0.035)
      ..style = PaintingStyle.fill;
    final paint3 = Paint()
      ..color = Colors.black.withOpacity(0.02)
      ..style = PaintingStyle.fill;

    final path1 = Path()
      ..moveTo(0, size.height * 0.12)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.2 + math.sin(animationValue * 2 * math.pi) * 50,
        size.width,
        size.height * 0.08,
      )
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();

    final path2 = Path()
      ..moveTo(0, size.height * 0.8)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.7 + math.cos(animationValue * 2 * math.pi) * 70,
        size.width,
        size.height * 0.88,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final path3 = Path()
      ..moveTo(size.width, size.height * 0.24)
      ..quadraticBezierTo(
        size.width * 0.72 + math.sin(animationValue * 2 * math.pi) * 60,
        size.height * 0.54,
        size.width,
        size.height * 0.72,
      )
      ..close();

    canvas.drawPath(path1, paint1);
    canvas.drawPath(path2, paint2);
    canvas.drawPath(path3, paint3);
  }

  @override
  bool shouldRepaint(covariant FabricPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}