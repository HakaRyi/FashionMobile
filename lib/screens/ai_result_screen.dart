import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../models/wardrobe_item_model.dart';
import '../widgets/animated_fabric_background.dart';
import '../widgets/clothing_item.dart';
import '../services/item_service.dart';
import 'clothing_detail_screen.dart';

class AIResultScreen extends StatefulWidget {
  final dynamic baseItem;
  final String prompt;
  final bool useMyWardrobe;
  final bool includeSavedItems;
  final bool useMyStylePreferences;
  final bool useMyPhysicalProfile;
  final List<int> targetWardrobeIds;

  const AIResultScreen({
    super.key,
    required this.baseItem,
    required this.prompt,
    required this.useMyWardrobe,
    required this.includeSavedItems,
    required this.useMyStylePreferences,
    required this.useMyPhysicalProfile,
    required this.targetWardrobeIds,
  });

  @override
  State<AIResultScreen> createState() => _AIResultScreenState();
}

class _AIResultScreenState extends State<AIResultScreen> {
  late Future<List<dynamic>> _recommendationsFuture;
  final Map<String, PageController> _controllers = {};

  int get _baseItemId {
    if (widget.baseItem is WardrobeItemModel) return widget.baseItem.itemId;
    return widget.baseItem['itemId'] ?? 0;
  }

  String get _baseItemName {
    if (widget.baseItem is WardrobeItemModel) return widget.baseItem.itemName;
    return widget.baseItem['itemName'] ?? "Item";
  }

  String? get _baseItemImage {
    if (widget.baseItem is WardrobeItemModel) return widget.baseItem.imageUrl;
    return widget.baseItem['primaryImageUrl'] ?? widget.baseItem['imageUrl'];
  }

  @override
  void initState() {
    super.initState();
    _recommendationsFuture = ItemService().getSmartRecommendations(
      referenceItemId: _baseItemId,
      prompt: widget.prompt,
      useMyWardrobe: widget.useMyWardrobe,
      useSavedItems: widget.includeSavedItems,
      useMyStylePreferences: widget.useMyStylePreferences,
      useMyPhysicalProfile: widget.useMyPhysicalProfile,
      targetWardrobeIds: widget.targetWardrobeIds,
      limit: 20,
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // Thứ tự ưu tiên sắp xếp danh mục
  int _getCategoryPriority(String cat) {
    cat = cat.toUpperCase();
    if (cat.contains('ACCESSORY')) return 1;
    if (cat.contains('UPPER_BODY')) return 2;
    if (cat.contains('LOWER_BODY')) return 3;
    if (cat.contains('FULL_BODY')) return 4;
    if (cat.contains('FOOTWEAR')) return 5;
    return 6;
  }

  Map<String, List<dynamic>> _groupAndSortItems(List<dynamic> items) {
    Map<String, List<dynamic>> grouped = {};
    for (var item in items) {
      String cat = item['category']?.toString().toUpperCase() ?? "OTHERS";
      if (!grouped.containsKey(cat)) grouped[cat] = [];
      grouped[cat]!.add(item);
    }
    var sortedKeys = grouped.keys.toList()
      ..sort((a, b) => _getCategoryPriority(a).compareTo(_getCategoryPriority(b)));

    return {for (var key in sortedKeys) key: grouped[key]!};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text("AI STYLIST RESULT",
            style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 0)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text("DONE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: AnimatedFabricBackground(
          child: SafeArea(
            child: FutureBuilder<List<dynamic>>(
        future: _recommendationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2));
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)));
          }

          final results = snapshot.data ?? [];
          if (results.isEmpty) {
            return const Center(child: Text("No items found matching your request.", style: TextStyle(color: Colors.black38)));
          }

          final groupedData = _groupAndSortItems(results);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildResultHeader(),
                ...groupedData.entries.map((entry) => _buildSnapCarousel(entry.key, entry.value)).toList(),
                const SizedBox(height: 60),
              ],
            ),
          );
        },
            ),
          ),
      ),
    );
  }

  Widget _buildResultHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 5, 20, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Hero(
            tag: 'item_$_baseItemId',
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: _baseItemImage != null
                    ? Image.network(_baseItemImage!, width: 50, height: 65, fit: BoxFit.contain)
                    : Container(width: 50, height: 65, color: const Color(0xFFF9F9F9), child: const Icon(Icons.checkroom, color: Colors.black12, size: 20)),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("STYLING WITH", style: TextStyle(color: Colors.black26, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0)),
                const SizedBox(height: 2),
                Text(_baseItemName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w800)),
                if (widget.prompt.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text("“${widget.prompt}”", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textPink, fontSize: 10, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600)),
                ]
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
            child: const Text("AI MATCH", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildSnapCarousel(String categoryName, List<dynamic> items) {
    String displayTitle = categoryName;
    if (displayTitle == "UPPER_BODY") displayTitle = "TOPS & JACKETS";
    if (displayTitle == "LOWER_BODY") displayTitle = "PANTS & SKIRTS";
    if (displayTitle == "FOOTWEAR") displayTitle = "SHOES";
    if (displayTitle == "ACCESSORY") displayTitle = "ACCESSORIES";

    final bool shouldLoop = items.length >= 3;
    final int itemCount = shouldLoop ? 1000 : items.length;
    final int initialPage = shouldLoop ? (itemCount ~/ 2) - ((itemCount ~/ 2) % items.length) : 0;

    final controller = _controllers.putIfAbsent(
      categoryName,
          () => PageController(viewportFraction: 0.45, initialPage: initialPage),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(25, 10, 20, 0),
          child: Text(
            displayTitle.toUpperCase(),
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, letterSpacing:0, color: Colors.black),
          ),
        ),
        SizedBox(
          height: 210,
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
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: ClothingItem(
                itemData: item,
              ),
            ),
          ),
        ),
      ),
    );
  }
}