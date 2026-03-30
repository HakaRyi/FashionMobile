import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/clothing_item.dart';
import '../services/item_service.dart';
import 'clothing_detail_screen.dart'; // Đảm bảo đã import trang chi tiết

class AIResultScreen extends StatefulWidget {
  final Map<String, dynamic> baseItem;
  final String prompt;
  final bool useMyWardrobe;
  final bool useCommunityItems;

  const AIResultScreen({
    super.key,
    required this.baseItem,
    required this.prompt,
    required this.useMyWardrobe,
    required this.useCommunityItems,
  });

  @override
  State<AIResultScreen> createState() => _AIResultScreenState();
}

class _AIResultScreenState extends State<AIResultScreen> {
  late Future<List<dynamic>> _recommendationsFuture;

  @override
  void initState() {
    super.initState();
    _recommendationsFuture = ItemService().getSmartRecommendations(
      referenceItemId: widget.baseItem['itemId'],
      prompt: widget.prompt,
      useMyWardrobe: widget.useMyWardrobe,
      useCommunityItems: widget.useCommunityItems,
    );
  }

  Map<String, List<dynamic>> _groupItems(List<dynamic> items) {
    Map<String, List<dynamic>> grouped = {};
    for (var item in items) {
      String cat = item['category']?.toString().toUpperCase() ?? "KHÁC";
      if (cat == "UPPER_BODY") cat = "ÁO & ÁO KHOÁC";
      if (cat == "LOWER_BODY") cat = "QUẦN & VÁY";
      if (cat == "FOOTWEAR") cat = "GIÀY DÉP";
      if (cat == "ACCESSORY") cat = "PHỤ KIỆN";

      if (!grouped.containsKey(cat)) grouped[cat] = [];
      grouped[cat]!.add(item);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("AI Stylist Gợi Ý",
            style: TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),

        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text("Xong",
                style: TextStyle(
                    color: AppColors.textPink,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _recommendationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.textPink),
                  SizedBox(height: 16),
                  Text("AI đang tìm đồ phù hợp...",
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
                child: Text("Lỗi: ${snapshot.error}",
                    style: const TextStyle(color: Colors.redAccent)));
          }

          final results = snapshot.data ?? [];
          if (results.isEmpty) {
            return const Center(
                child: Text("Không tìm thấy món đồ phù hợp.",
                    style: TextStyle(color: Colors.white54)));
          }

          final groupedData = _groupItems(results);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildResultHeader(),
              const SizedBox(height: 24),
              ...groupedData.entries
                  .map((entry) => _buildCategorySection(entry.key, entry.value))
                  .toList(),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResultHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textPink.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Hero(
            tag: 'item_${widget.baseItem['itemId']}',
            child: Container(
              width: 60,
              height: 70,
              decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: widget.baseItem['primaryImageUrl'] != null
                    ? Image.network(widget.baseItem['primaryImageUrl'],
                    fit: BoxFit.cover)
                    : const Icon(Icons.checkroom, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Phối đồ cùng:",
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                Text(widget.baseItem['itemName'] ?? "Item",
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                if (widget.prompt.isNotEmpty)
                  Text("Yêu cầu: ${widget.prompt}",
                      style: const TextStyle(
                          color: AppColors.textPink,
                          fontSize: 11,
                          fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(String title, List<dynamic> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 12),
          child: Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return ClothingItem(
              title: item['itemName'] ?? "Unnamed",
              imageUrl: item['primaryImageUrl'],
              // --- XỬ LÝ XEM CHI TIẾT KHI CHẠM ---
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClothingDetailScreen(itemData: item,showEditButton: false,),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}