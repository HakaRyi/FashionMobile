import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/recommendation_service.dart';
import '../widgets/animated_fabric_background.dart';
import '../widgets/clothing_item.dart';
import 'clothing_detail_screen.dart';

class HistoryDetailScreen extends StatefulWidget {
  final int historyId;
  final String title;
  final String? refImage;

  const HistoryDetailScreen({
    super.key,
    required this.historyId,
    required this.title,
    this.refImage,
  });

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  late Future<List<dynamic>> _detailsFuture;
  // Lưu trữ các controller để quản lý hiệu ứng riêng cho từng hàng
  final Map<String, PageController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _detailsFuture = RecommendationService().getHistoryDetail(widget.historyId);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text("OUTFIT PREVIEW",
            style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w900, )),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body:AnimatedFabricBackground(
          child: SafeArea(
            child: FutureBuilder<List<dynamic>>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2));
          }

          final rawItems = snapshot.data ?? [];
          if (rawItems.isEmpty) return _buildEmptyState();

          final groupedData = _groupAndSortItems(rawItems);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildHeaderInfo(),
                ...groupedData.entries.map((entry) => _buildSnapCarousel(entry.key, entry.value)).toList(),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
            ),
          ),
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

  Widget _buildHeaderInfo() {
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
          _buildRefImage(),
          const SizedBox(width: 15),
          _buildHeaderText(),
        ],
      ),
    );
  }

  Widget _buildRefImage() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        //border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: widget.refImage != null
            ? Image.network(widget.refImage!, width: 50, height: 65, fit: BoxFit.contain)
            : Container(width: 50, height: 65, color: const Color(0xFFF9F9F9), child: const Icon(Icons.checkroom, color: Colors.black12, size: 20)),
      ),
    );
  }

  Widget _buildHeaderText() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("REFERENCE", style: TextStyle(color: Colors.black26, fontSize: 10, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(6)),
            child: const Text("AI MATCH", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.style_outlined, size: 48, color: Colors.black12),
          SizedBox(height: 12),
          Text("No suggestions available", style: TextStyle(color: Colors.black38, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}