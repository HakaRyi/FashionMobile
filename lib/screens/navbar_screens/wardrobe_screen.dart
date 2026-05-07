import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/item_service.dart';
import '../../utils/upload_utils.dart';
import '../../widgets/clothing_item.dart';
import '../clothing_detail_screen.dart';
import '../collection_screen.dart';
import '../suggestion_screen.dart';
import '../try_on_screen.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  final ItemService _itemService = ItemService();

  Timer? _debounce;

  final List<dynamic> _allItems = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  final int _pageSize = 20;

  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;

  String _selectedFilter = 'All';
  bool _isSearchVisible = false;

  final Map<String, bool> _styleVisibility = {};

  @override
  void initState() {
    super.initState();

    _fetchItems();

    _scrollController.addListener(() {
      if (!_scrollController.hasClients) {
        return;
      }

      final shouldLoadMore =
          _scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200;

      if (shouldLoadMore && !_isLoading && _hasMore) {
        _fetchItems();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
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

    for (final item in _allItems) {
      if (item is! Map) {
        continue;
      }

      final category = item['category']?.toString().trim();
      final style = item['style']?.toString().trim();

      if (category != null && category.isNotEmpty) {
        filters.add(category);
      }

      if (style != null && style.isNotEmpty) {
        filters.add(style);
      }
    }

    return filters.toList();
  }

  Future<void> _fetchItems({bool refresh = false}) async {
    if (_isLoading) {
      return;
    }

    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _allItems.clear();
      _styleVisibility.clear();
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _itemService.getMyItemsPaginated(
        _currentPage,
        _pageSize,
        searchQuery: _searchController.text.trim(),
      );

      final List<dynamic> newItems = response['items'] is List
          ? response['items'] as List<dynamic>
          : <dynamic>[];

      final int totalPages = response['totalPages'] is int
          ? response['totalPages'] as int
          : int.tryParse(response['totalPages']?.toString() ?? '') ?? 1;

      if (!mounted) {
        return;
      }

      setState(() {
        _allItems.addAll(newItems);
        _currentPage++;

        if (_currentPage > totalPages || newItems.isEmpty) {
          _hasMore = false;
        }

        for (final item in newItems) {
          if (item is! Map) {
            continue;
          }

          final style = item['style']?.toString().trim();
          final styleName = style == null || style.isEmpty ? 'Others' : style;

          _styleVisibility.putIfAbsent(styleName, () => true);
        }
      });
    } catch (e) {
      debugPrint('Error loading wardrobe items: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_normalizeError(e)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    await _fetchItems(refresh: true);
  }

  void _toggleStyleVisibility(String style) {
    setState(() {
      _styleVisibility[style] = !(_styleVisibility[style] ?? true);
    });

    HapticFeedback.lightImpact();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _handleRefresh();
    });
  }

  Future<void> _deleteItem(dynamic item) async {
    if (item is! Map) {
      return;
    }

    final itemId = int.tryParse(item['itemId']?.toString() ?? '');

    if (itemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item information is invalid.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Confirm',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Delete this item?',
            style: TextStyle(color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black54),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Delete',
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

    try {
      await _itemService.deleteItem(itemId);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      await _handleRefresh();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_normalizeError(e)),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters = _getDynamicFilters();

    final List<dynamic> filteredItems = _selectedFilter == 'All'
        ? _allItems
        : _allItems.where((item) {
      if (item is! Map) {
        return false;
      }

      return item['category']?.toString() == _selectedFilter ||
          item['style']?.toString() == _selectedFilter;
    }).toList();

    final Map<String, List<dynamic>> groupedItems = {};

    for (final item in filteredItems) {
      if (item is! Map) {
        continue;
      }

      final style = item['style']?.toString().trim();
      final styleName = style == null || style.isEmpty ? 'Others' : style;

      groupedItems.putIfAbsent(styleName, () => []);
      groupedItems[styleName]!.add(item);
    }

    final List<Widget> slivers = [];

    groupedItems.forEach((style, items) {
      final bool isVisible = _styleVisibility[style] ?? true;

      slivers.add(
        SliverToBoxAdapter(
          child: InkWell(
            onTap: () => _toggleStyleVisibility(style),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    style.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0,
                      color: Colors.black45,
                    ),
                  ),
                  Icon(
                    isVisible
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: Colors.black26,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      if (isVisible) {
        slivers.add(
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final item = items[index];

                  return ClothingItem(
                    itemData: item,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClothingDetailScreen(
                            itemData: item as Map<String, dynamic>,
                          ),
                        ),
                      );

                      await _handleRefresh();
                    },
                    customActionIcon: Icons.delete_outline,
                    customActionLabel: 'Remove from Wardrobe',
                    customActionColor: Colors.redAccent,
                    onCustomAction: () => _deleteItem(item),
                  );
                },
                childCount: items.length,
              ),
            ),
          ),
        );
      }
    });

    if (_isLoading && _allItems.isNotEmpty) {
      slivers.add(
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(color: Colors.black),
            ),
          ),
        ),
      );
    }

    slivers.add(
      const SliverToBoxAdapter(
        child: SizedBox(height: 80),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildChicHeader(),
            _buildActionButtons(),
            _buildCategoryTabs(filters),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                color: Colors.black,
                backgroundColor: Colors.white,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    if (filteredItems.isEmpty && !_isLoading)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(),
                      )
                    else
                      ...slivers,
                  ],
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildChicHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 10, 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!_isSearchVisible)
            const Text(
              'My Wardrobe',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: Colors.black,
              ),
            )
          else
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                onChanged: _onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'Search items...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.black26),
                ),
              ),
            ),
          IconButton(
            icon: Icon(
              _isSearchVisible ? Icons.close : Icons.search,
              color: Colors.black,
            ),
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible;

                if (!_isSearchVisible) {
                  _searchController.clear();
                  _handleRefresh();
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      child: Row(
        children: [
          Expanded(
            child: _CustomActionButton(
              icon: Icons.add,
              label: 'Add',
              isPrimary: true,
              onTap: () async {
                final result = await UploadUtils.showUploadMenu(context);

                if (result == true) {
                  await _handleRefresh();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _CustomActionButton(
              icon: Icons.history,
              label: 'History',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SuggestionScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _CustomActionButton(
              icon: Icons.face,
              label: 'Try-On',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TryOnScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _CustomActionButton(
              icon: Icons.collections_bookmark_outlined,
              label: 'Collection',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CollectionScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(List<String> filters) {
    return Container(
      height: 85,
      margin: const EdgeInsets.only(
        top: 10,
        bottom: 5,
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final name = filters[index];
          final isSelected = _selectedFilter == name;

          return Padding(
            padding: const EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = name;
                });

                HapticFeedback.selectionClick();
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _getCategoryThumbnail(name, isSelected),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.only(bottom: 2),
                    decoration: BoxDecoration(
                      border: isSelected
                          ? const Border(
                        bottom: BorderSide(
                          color: Colors.black,
                          width: 2,
                        ),
                      )
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      name.toUpperCase(),
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.black38,
                        fontSize: 10,
                        fontWeight:
                        isSelected ? FontWeight.w900 : FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _getCategoryThumbnail(String category, bool isSelected) {
    final cat = category.toLowerCase();
    String assetPath = '';

    if (cat == 'all') {
      assetPath = 'assets/images/all.png';
    } else if (cat.contains('upper') ||
        cat.contains('top') ||
        cat.contains('shirt')) {
      assetPath = 'assets/images/aodo.png';
    } else if (cat.contains('lower') ||
        cat.contains('pant') ||
        cat.contains('skirt') ||
        cat.contains('jean')) {
      assetPath = 'assets/images/quanxanh.png';
    } else if (cat.contains('full') ||
        cat.contains('dress') ||
        cat.contains('jumpsuit')) {
      assetPath = 'assets/images/fullbody.png';
    } else if (cat.contains('footwear') || cat.contains('shoe')) {
      assetPath = 'assets/images/giay.png';
    } else if (cat.contains('accessory')) {
      assetPath = 'assets/images/phukien.png';
    } else if (cat.contains('casual')) {
      assetPath = 'assets/images/casual.png';
    } else if (cat.contains('formal') || cat.contains('suit')) {
      assetPath = 'assets/images/formalclothes.png';
    } else if (cat.contains('sport')) {
      assetPath = 'assets/images/sporty.png';
    } else if (cat.contains('streetwear') || cat.contains('street')) {
      assetPath = 'assets/images/streetwear.png';
    } else if (cat.contains('vintage') || cat.contains('retro')) {
      assetPath = 'assets/images/vintage.png';
    } else if (cat.contains('minimalist') || cat.contains('minimal')) {
      assetPath = 'assets/images/minimalist.png';
    } else {
      assetPath = 'assets/images/logowapo.png';
    }

    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: isSelected
            ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ]
            : null,
        image: DecorationImage(
          image: AssetImage(assetPath),
          fit: BoxFit.cover,
          colorFilter: isSelected
              ? null
              : ColorFilter.mode(
            Colors.white.withOpacity(0.5),
            BlendMode.lighten,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.black12,
          ),
          SizedBox(height: 16),
          Text(
            'NO ITEMS FOUND',
            style: TextStyle(
              color: Colors.black26,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _CustomActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isPrimary ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isPrimary
              ? null
              : Border.all(
            color: Colors.black.withOpacity(0.08),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isPrimary ? Colors.white : Colors.black,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.white : Colors.black,
                fontSize: 11,
                fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}