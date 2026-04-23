import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/try_on_source_item.dart';
import '../models/wardrobe_item_model.dart';
import '../services/item_service.dart';
import '../services/wardrobe_service.dart';
import '../widgets/public_clothing_item.dart';
import '../utils/app_toast.dart';
import '../utils/route_transitions.dart';
import '../screens/ai_suggestion_screen.dart';
import '../screens/try_on_screen.dart';
import '../screens/public_item_detail_screen.dart';

class PublicWardrobeScreen extends StatefulWidget {
  final int accountId;

  const PublicWardrobeScreen({
    super.key,
    required this.accountId,
  });

  @override
  State<PublicWardrobeScreen> createState() => _PublicWardrobeScreenState();
}

class _PublicWardrobeScreenState extends State<PublicWardrobeScreen> with SingleTickerProviderStateMixin {
  final WardrobeService _wardrobeService = WardrobeService();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  String? _error;

  Map<String, dynamic>? _profile;
  List<WardrobeItemModel> _items = [];

  String _selectedFilter = "All";

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
    _scrollController.dispose();
    super.dispose();
  }

  List<String> _getDynamicFilters() {
    Set<String> filters = {"All"};
    for (var item in _items) {
      if (item.category != null && item.category!.isNotEmpty) {
        filters.add(item.category!);
      }
    }
    return filters.toList();
  }

  void _showActionMenu(BuildContext context, WardrobeItemModel item) {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.itemName.toUpperCase(),
                style: const TextStyle(
                  color: Colors.black45,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.auto_awesome, color: Colors.black),
                title: const Text("AI Mix & Match", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                      context,
                      SlideRoute(page: AISuggestionScreen(selectedItem: item))
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.face, color: Colors.black),
                title: const Text("Virtual Try-on", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(sheetContext);
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

      if (mounted) {
        setState(() {
          _profile = profile;
          _items = items;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
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
    if (name == null || name.isEmpty) return 'User';
    return name;
  }

  String? get _avatarUrl {
    final url = _profile?['avatarUrl']?.toString();
    if (url == null || url.isEmpty) return null;
    return url;
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
    final filters = _getDynamicFilters();
    final List<WardrobeItemModel> filteredItems = _selectedFilter == "All"
        ? _items
        : _items.where((i) => i.category == _selectedFilter).toList();

    Map<String, List<WardrobeItemModel>> groupedItems = {};
    for (var item in filteredItems) {
      final cat = item.category ?? 'Others';
      if (!groupedItems.containsKey(cat)) groupedItems[cat] = [];
      groupedItems[cat]!.add(item);
    }

    return Scaffold(
      backgroundColor: Colors.white,
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
                ? const Center(child: CircularProgressIndicator(color: Colors.black))
                : _error != null
                ? _buildError()
                : RefreshIndicator(
              onRefresh: _loadData,
              color: Colors.black,
              backgroundColor: Colors.white,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  SliverAppBar(
                    expandedHeight: 240.0,
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        "$_userName's Wardrobe".toUpperCase(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: Colors.black,
                        ),
                      ),
                      centerTitle: true,
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          _avatarUrl != null
                              ? Image.network(
                            _avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholderCover(),
                          )
                              : _buildPlaceholderCover(),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withOpacity(0.8),
                                  Colors.white.withOpacity(0.2),
                                  Colors.white,
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
                          _buildStatItem("$_totalPublicItems", "ITEMS"),
                          _buildStatItem("$_countFollower", "FOLLOWERS"),
                          _buildStatItem("$_countFollowing", "FOLLOWING"),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: _buildCategoryTabs(filters),
                  ),

                  if (_items.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 60),
                        child: Center(
                          child: Text(
                            "This user has no public items yet.",
                            style: TextStyle(color: Colors.black45, fontSize: 14, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final category = groupedItems.keys.elementAt(index);
                          final itemsInCategory = groupedItems[category]!;
                          return CategoryDrawerShelf(
                            categoryName: category,
                            items: itemsInCategory,
                            scrollController: _scrollController,
                            onItemTap: (item) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PublicItemDetailScreen(itemId: item.itemId),
                                ),
                              );
                            },
                            onItemSave: (item) async {
                              bool success = item.isSaved ? await ItemService().unsaveItem(item.itemId) : await ItemService().saveItem(item.itemId);
                              if (success && mounted) {
                                setState(() {
                                  final itemIndex = _items.indexWhere((i) => i.itemId == item.itemId);
                                  if (itemIndex != -1) {
                                    _items[itemIndex] = item.copyWith(isSaved: !item.isSaved);
                                  }
                                });
                                AppToast.show(context, item.isSaved ? "Unsaved!" : "Saved to favorites!");
                              }
                            },
                            onItemLongPress: (item) => _showActionMenu(context, item),
                          );
                        },
                        childCount: groupedItems.length,
                      ),
                    ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(List<String> filters) {
    if (filters.length <= 1) return const SizedBox.shrink();

    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 5, bottom: 15),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final name = filters[index];
          final isSelected = _selectedFilter == name;
          return Padding(
            padding: const EdgeInsets.only(right: 25),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedFilter = name);
                HapticFeedback.selectionClick();
              },
              child: Container(
                decoration: BoxDecoration(border: isSelected ? const Border(bottom: BorderSide(color: Colors.black, width: 2)) : null),
                alignment: Alignment.center,
                child: Text(
                    name.toUpperCase(),
                    style: TextStyle(
                        color: isSelected ? Colors.black : Colors.black26,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                        letterSpacing: 0
                    )
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaceholderCover() {
    return Container(
      color: Colors.black12,
      child: const Center(
        child: Icon(Icons.checkroom, color: Colors.black26, size: 80),
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
            const Icon(Icons.error_outline, color: Colors.black, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Failed to load public wardrobe',
              style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: const Text('Try Again', style: TextStyle(color: Colors.white)),
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
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 22),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
      ],
    );
  }
}

class CategoryDrawerShelf extends StatefulWidget {
  final String categoryName;
  final List<WardrobeItemModel> items;
  final ScrollController scrollController;
  final Function(WardrobeItemModel) onItemTap;
  final Function(WardrobeItemModel) onItemSave;
  final Function(WardrobeItemModel) onItemLongPress;

  const CategoryDrawerShelf({
    super.key,
    required this.categoryName,
    required this.items,
    required this.scrollController,
    required this.onItemTap,
    required this.onItemSave,
    required this.onItemLongPress,
  });

  @override
  State<CategoryDrawerShelf> createState() => _CategoryDrawerShelfState();
}

class _CategoryDrawerShelfState extends State<CategoryDrawerShelf> {
  final GlobalKey _shelfKey = GlobalKey();
  double _revealProgress = 0.0;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_calculateProgress);
    WidgetsBinding.instance.addPostFrameCallback((_) => _calculateProgress());
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_calculateProgress);
    super.dispose();
  }

  void _calculateProgress() {
    if (_shelfKey.currentContext == null || !mounted) return;

    final RenderBox? box = _shelfKey.currentContext!.findRenderObject() as RenderBox?;
    if (box == null) return;

    final positionY = box.localToGlobal(Offset.zero).dy;
    final screenH = MediaQuery.of(context).size.height;
    final itemH = box.size.height;

    double progress = 1.0;

    if (positionY > screenH - 200) {
      progress = (screenH - positionY) / 200;
    }
    else if (positionY < 120) {
      progress = (positionY + itemH) / 120;
    }

    progress = progress.clamp(0.0, 1.0);

    if (_revealProgress != progress) {
      setState(() {
        _revealProgress = progress;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      key: _shelfKey,
      height: 280,
      margin: const EdgeInsets.only(bottom: 24),
      child: Stack(
        children: [
          Positioned.fill(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(left: 20, right: 20, top: 40),
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                return Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 16),
                  child: PublicClothingItem(
                    itemId: item.itemId,
                    title: item.itemName,
                    imageUrl: item.imageUrl ?? '',
                    isSaved: item.isSaved,
                    showSaveButton: !item.isOwner,
                    likes: 0,
                    onTap: () => widget.onItemTap(item),
                    onSave: () => widget.onItemSave(item),
                    onLongPress: () => widget.onItemLongPress(item),
                  ),
                );
              },
            ),
          ),

          Positioned(
            left: 20,
            top: 0,
            child: Text(
              widget.categoryName.toUpperCase(),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),

          Positioned(
            top: 40,
            bottom: 0,
            right: 0,
            width: screenWidth,
            child: IgnorePointer(
              ignoring: _revealProgress > 0.5,
              child: Transform.translate(
                offset: Offset(screenWidth * _revealProgress, 0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(-5, 0),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          border: Border(
                            left: BorderSide(color: Colors.white.withOpacity(0.15), width: 1),
                            top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
                            bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
                          ),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.lock_outline, color: Colors.white70, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                widget.categoryName.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FabricPainter extends CustomPainter {
  final double animationValue;

  FabricPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()..color = Colors.black.withOpacity(0.04)..style = PaintingStyle.fill;
    final paint2 = Paint()..color = Colors.black.withOpacity(0.06)..style = PaintingStyle.fill;
    final paint3 = Paint()..color = Colors.black.withOpacity(0.03)..style = PaintingStyle.fill;
    final paint4 = Paint()..color = Colors.black.withOpacity(0.05)..style = PaintingStyle.fill;
    final paint5 = Paint()..color = Colors.black.withOpacity(0.02)..style = PaintingStyle.fill;

    Path path1 = Path();
    path1.moveTo(0, size.height * 0.1);
    path1.quadraticBezierTo(size.width * 0.5, size.height * 0.2 + math.sin(animationValue * 2 * math.pi) * 60, size.width, size.height * 0.05);
    path1.lineTo(size.width, 0);
    path1.lineTo(0, 0);
    path1.close();

    Path path2 = Path();
    path2.moveTo(0, size.height * 0.8);
    path2.quadraticBezierTo(size.width * 0.4, size.height * 0.7 + math.cos(animationValue * 2 * math.pi) * 80, size.width * 0.8, size.height * 0.9);
    path2.quadraticBezierTo(size.width * 0.95, size.height * 0.95 + math.sin(animationValue * math.pi) * 30, size.width, size.height * 0.8);
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();

    Path path3 = Path();
    path3.moveTo(size.width * 0.2, 0);
    path3.quadraticBezierTo(size.width * 0.6 + math.sin(animationValue * 2 * math.pi + math.pi) * 80, size.height * 0.5, size.width, size.height * 0.4);
    path3.lineTo(size.width, 0);
    path3.close();

    Path path4 = Path();
    path4.moveTo(0, size.height * 0.4);
    path4.quadraticBezierTo(size.width * 0.3 + math.cos(animationValue * 2 * math.pi) * 50, size.height * 0.5 + math.sin(animationValue * 2 * math.pi) * 50, 0, size.height * 0.7);
    path4.close();

    Path path5 = Path();
    path5.moveTo(size.width, size.height * 0.3);
    path5.quadraticBezierTo(size.width * 0.7 + math.sin(animationValue * 2 * math.pi) * 70, size.height * 0.6 + math.cos(animationValue * 2 * math.pi) * 40, size.width, size.height * 0.7);
    path5.close();

    canvas.drawPath(path1, paint1);
    canvas.drawPath(path2, paint2);
    canvas.drawPath(path3, paint3);
    canvas.drawPath(path4, paint4);
    canvas.drawPath(path5, paint5);
  }

  @override
  bool shouldRepaint(covariant FabricPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}