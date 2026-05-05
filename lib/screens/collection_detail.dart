import 'package:flutter/material.dart';
import '../../services/item_service.dart';
import '../../widgets/animated_fabric_background.dart';
import '../../widgets/clothing_item.dart';
import 'clothing_detail_screen.dart';

class CollectionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> collectionData;

  const CollectionDetailScreen({super.key, required this.collectionData});

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  final Map<String, PageController> _controllers = {};
  Map<String, List<dynamic>>? _currentGroupedData;

  late Map<String, dynamic> _localCollectionData;
  bool _wasModified = false;
  @override
  void initState() {
    super.initState();
    _localCollectionData = Map<String, dynamic>.from(widget.collectionData);
    final items = _localCollectionData['items'] as List<dynamic>? ?? [];
    _currentGroupedData = _groupAndSortItems(items);
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  int _getCategoryPriority(String cat) {
    cat = cat.toLowerCase();
    if (cat.contains('accessory')) return 1;
    if (cat.contains('upper')) return 2;
    if (cat.contains('lower')) return 3;
    if (cat.contains('full')) return 4;
    if (cat.contains('footwear')) return 5;
    return 6;
  }

  Map<String, List<dynamic>> _groupAndSortItems(List<dynamic> items) {
    Map<String, List<dynamic>> grouped = {};
    for (var item in items) {
      String cat = item['category'] ?? "Others";
      if (!grouped.containsKey(cat)) grouped[cat] = [];
      grouped[cat]!.add(item);
    }
    var sortedKeys = grouped.keys.toList()
      ..sort((a, b) => _getCategoryPriority(a).compareTo(_getCategoryPriority(b)));
    return {for (var key in sortedKeys) key: grouped[key]!};
  }

  void _showUpdateCollectionDialog() {
    if (_currentGroupedData == null || _currentGroupedData!.isEmpty) return;

    List<int> selectedItemIds = [];

    _currentGroupedData!.forEach((category, items) {
      if (items.isEmpty) return;

      if (_controllers.containsKey(category) && _controllers[category]!.hasClients) {
        final controller = _controllers[category]!;
        int currentPage = controller.page?.round() ?? controller.initialPage;
        int actualIndex = currentPage % items.length;
        int itemId = items[actualIndex]['itemId'] ?? items[actualIndex]['id'] ?? 0;
        if (itemId != 0) selectedItemIds.add(itemId);
      } else {
        int itemId = items[0]['itemId'] ?? items[0]['id'] ?? 0;
        if (itemId != 0) selectedItemIds.add(itemId);
      }
    });

    // Truyền sẵn Title và Description cũ từ API GET
    final titleController = TextEditingController(text: _localCollectionData['title']);
    final descController = TextEditingController(text: _localCollectionData['description']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Update Collection", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                hintText: "Enter title",
                hintStyle: TextStyle(color: Colors.black54),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              maxLines: 2,
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                hintText: "Enter description",
                hintStyle: TextStyle(color: Colors.black54),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              Navigator.pop(ctx);
              _updateCollectionToApi(titleController.text, descController.text, selectedItemIds);
            },
            child: const Text("Update", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateCollectionToApi(String title, String desc, List<int> itemIds) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.white)),
      );

      final collectionId = _localCollectionData['collectionId'];
      await ItemService().updateCollection(collectionId, title, desc, itemIds);

      if (mounted) {
        Navigator.pop(context); // Tắt loading
        setState(() {
          _wasModified = true;
          _localCollectionData['title'] = title;
          _localCollectionData['description'] = desc;
          _controllers.clear();
          final oldItems = _localCollectionData['items'] as List<dynamic>? ?? [];
          final newItems = oldItems.where((item) {
            int id = item['itemId'] ?? item['id'] ?? 0;
            return itemIds.contains(id);
          }).toList();

          _localCollectionData['items'] = newItems;
          _currentGroupedData = _groupAndSortItems(newItems);
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Collection updated successfully!", style: TextStyle(color: Colors.white)), backgroundColor: Colors.black));

      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update: $e"), backgroundColor: Colors.red));
      }
    }
  }
  void _removeItem(int itemIdToRemove) {
    List<int> currentItemIds = [];
    final items = _localCollectionData['items'] as List<dynamic>? ?? [];

    for (var item in items) {
      int id = item['itemId'] ?? 0;
      if (id != 0 && id != itemIdToRemove) {
        currentItemIds.add(id);
      }
    }
    if (currentItemIds.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Empty Collection", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          content: const Text("This is the last item. Do you want to delete this collection entirely?", style: TextStyle(color: Colors.black)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel", style: TextStyle(color: Colors.black54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              onPressed: () async {
                Navigator.pop(ctx);

                final title = _localCollectionData['title'] ?? '';
                final desc = _localCollectionData['description'] ?? '';
                _updateCollectionToApi(title, desc, currentItemIds);
              },
              child: const Text("Delete All", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }
    final title = _localCollectionData['title'] ?? '';
    final desc = _localCollectionData['description'] ?? '';
    _updateCollectionToApi(title, desc, currentItemIds);
  }
  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          if (didPop) return;
          Navigator.pop(context, _wasModified);
        },
        child:Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text("COLLECTION DETAIL",
            style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w900)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),

          onPressed: () => Navigator.pop(context, _wasModified),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note, color: Colors.black, size: 28),
            tooltip: "Edit & Update",
            onPressed: _showUpdateCollectionDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: AnimatedFabricBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildHeaderInfo(),
                if (_currentGroupedData != null)
                  ..._currentGroupedData!.entries.map((entry) => _buildSnapCarousel(entry.key, entry.value)).toList(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
        ),
    );
  }

  Widget _buildHeaderInfo() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 5, 20, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.collections_bookmark, size: 18, color: Colors.black45),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _localCollectionData['title'] ?? 'Untitled',
                  style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _localCollectionData['description'] ?? 'No description provided.',
            style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildSnapCarousel(String categoryName, List<dynamic> items) {
    String displayTitle = categoryName.toUpperCase();
    if (displayTitle == "UPPER_BODY") displayTitle = "TOPS & JACKETS";
    if (displayTitle == "LOWER_BODY") displayTitle = "PANTS & SKIRTS";
    if (displayTitle == "FOOTWEAR") displayTitle = "SHOES";
    if (displayTitle == "ACCESSORY") displayTitle = "ACCESSORIES";
    if (items.isEmpty) return const SizedBox.shrink();

    final bool shouldLoop = items.length >= 3;
    final int itemCount = shouldLoop ? 1000 : items.length;
    final int initialPage = shouldLoop ? (itemCount ~/ 2) - ((itemCount ~/ 2) % items.length) : 0;

    final controller = _controllers.putIfAbsent(
      categoryName,
          () => PageController(viewportFraction: 0.45, initialPage: initialPage),
    );

    return Column(
      key: ValueKey('$categoryName-${items.length}'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(25, 15, 20, 0),
          child: Text(
            displayTitle.toUpperCase(),
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: 0, color: Colors.black),
          ),
        ),
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: controller,
            padEnds: true,
            physics: items.length <= 1 ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              final item = items[index % items.length];

              return AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  double value = 0.0;
                  if (controller.position.hasContentDimensions) {
                    value = (controller.page ?? initialPage.toDouble()) - index;
                  } else {
                    value = (initialPage.toDouble()) - index;
                  }
                  double scale = (1 - (value.abs() * 0.2)).clamp(0.8, 1.0);
                  double opacity = (1 - (value.abs() * 0.5)).clamp(0.4, 1.0);

                  return Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: opacity,
                      child: _buildCarouselItem(item),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCarouselItem(dynamic item) {
    int currentItemId = item['itemId'] ?? 0;
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ClothingDetailScreen(itemData: item, showEditButton: false)));
      },
      child: Center(
        child: AspectRatio(
          aspectRatio: 0.75,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: ClothingItem(
                  itemData: item,
                customActionIcon: Icons.playlist_remove,
                customActionLabel: "Remove from Collection",
                customActionColor: Colors.redAccent,
                onCustomAction: () => _removeItem(currentItemId),
              ),
            ),
          ),
        ),
      ),
    );
  }
}