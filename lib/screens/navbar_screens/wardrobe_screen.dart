import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import '../../utils/route_transitions.dart';
import '../../widgets/clothing_item.dart';
import '../../services/item_service.dart';
import '../ai_suggestion_screen.dart';
import '../clothing_detail_screen.dart';
import '../../utils/upload_utils.dart';
import '../../screens/suggestion_screen.dart';
import '../../screens/try_on_screen.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  Timer? _debounce;
  final List<dynamic> _allItems = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  final int _pageSize = 20;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  String _selectedFilter = "All";
  bool _isSearchVisible = false;
  final Map<String, bool> _styleVisibility = {};

  @override
  void initState() {
    super.initState();
    _fetchItems();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        if (!_isLoading && _hasMore) _fetchItems();
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

  // LOGIC LẤY FILTER TỰ ĐỘNG
  List<String> _getDynamicFilters() {
    Set<String> filters = {"All"};
    for (var item in _allItems) {
      if (item['category'] != null) filters.add(item['category']);
      if (item['style'] != null) filters.add(item['style']);
    }
    return filters.toList();
  }

  // FETCH DỮ LIỆU VỚI LOGIC PHÂN TRANG GỐC
  Future<void> _fetchItems({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _allItems.clear();
    }
    setState(() => _isLoading = true);
    try {
      final response = await ItemService().getMyItemsPaginated(
          _currentPage, _pageSize,
          searchQuery: _searchController.text
      );
      final List<dynamic> newItems = response['items'] ?? [];
      final int totalPages = response['totalPages'] ?? 1;
      setState(() {
        _allItems.addAll(newItems);
        _currentPage++;
        if (_currentPage > totalPages || newItems.isEmpty) _hasMore = false;
        for (var item in newItems) {
          final style = item['style'] ?? 'Others';
          _styleVisibility.putIfAbsent(style, () => true);
        }
      });
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      setState(() => _isLoading = false);
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

  // LOGIC SEARCH VỚI DEBOUNCE (LẮNG NGHE NGƯỜI DÙNG GÕ)
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _handleRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filters = _getDynamicFilters();
    final List<dynamic> filteredItems = _selectedFilter == "All"
        ? _allItems
        : _allItems.where((i) => i['category'] == _selectedFilter || i['style'] == _selectedFilter).toList();

    Map<String, List<dynamic>> groupedItems = {};
    for (var item in filteredItems) {
      final s = item['style'] ?? 'Others';
      if (!groupedItems.containsKey(s)) groupedItems[s] = [];
      groupedItems[s]!.add(item);
    }

    List<Widget> slivers = [];
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
                  Text(style.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0, color: Colors.black45)),
                  Icon(isVisible ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.black26),
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
                    title: item['itemName'] ?? "",
                    imageUrl: item['primaryImageUrl'],
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => ClothingDetailScreen(itemData: item)));
                      _handleRefresh();
                    },
                    onLongPress: () {
                      HapticFeedback.mediumImpact();
                      _showActionMenu(context, item); // HIỆN MENU KHI HOLD
                    },
                  );
                },
                childCount: items.length,
              ),
            ),
          ),
        );
      }
    });

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
                backgroundColor:Colors.white ,
                child: filteredItems.isEmpty && !_isLoading
                    ? _buildEmptyState()
                    : CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  slivers: slivers,
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
            const Text("My Wardrobe", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: Colors.black))
          else
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(fontWeight: FontWeight.w600,color: Colors.black),
                onChanged: _onSearchChanged, // LẮNG NGHE GÕ PHÍM VỚI BOUNCE
                decoration: const InputDecoration(hintText: "Search items...", border: InputBorder.none, hintStyle: TextStyle(color: Colors.black26)),
              ),
            ),
          IconButton(
            icon: Icon(_isSearchVisible ? Icons.close : Icons.search, color: Colors.black),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(child: _CustomActionButton(icon: Icons.add, label: "Add", isPrimary: true, onTap: () async {
            final result = await UploadUtils.showUploadMenu(context);
            if (result == true) _handleRefresh();
          })),
          const SizedBox(width: 8),
          Expanded(child: _CustomActionButton(icon: Icons.history, label: "History", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SuggestionScreen())))),
          const SizedBox(width: 8),
          Expanded(child: _CustomActionButton(icon: Icons.face, label: "Try-On", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TryOnScreen())))),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(List<String> filters) {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 5),
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
                child: Text(name.toUpperCase(), style: TextStyle(color: isSelected ? Colors.black : Colors.black26, fontSize: 13, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600, letterSpacing: 0)),
              ),
            ),
          );
        },
      ),
    );
  }

  // HIỂN THỊ MENU KHI NHẤN GIỮ (HOLD)
  void _showActionMenu(BuildContext context, dynamic item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2))),
            ListTile(
              leading: const Icon(Icons.auto_awesome, color: Colors.black),
              title: const Text("AI Outfit Suggestion", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, SlideRoute(page: AISuggestionScreen(selectedItem: item)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text("Remove from Wardrobe", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(context);
                final bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text("Confirm"),
                    content: const Text("Delete this item?"),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Cancel")),
                      TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("Delete")),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ItemService().deleteItem(item['itemId']);
                  _handleRefresh();
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.inventory_2_outlined, size: 64, color: Colors.black12), SizedBox(height: 16), Text("NO ITEMS FOUND", style: TextStyle(color: Colors.black26, fontWeight: FontWeight.w900))]));
  }
}

class _CustomActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  const _CustomActionButton({required this.icon, required this.label, required this.onTap, this.isPrimary = false});

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
          border: isPrimary ? null : Border.all(color: Colors.black.withOpacity(0.08)),
        ),
        child: Column(
          children: [
            Icon(icon, color: isPrimary ? Colors.white : Colors.black, size: 20),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: isPrimary ? Colors.white : Colors.black, fontSize: 11, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}