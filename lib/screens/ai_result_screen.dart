import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/clothing_item.dart';

class AIResultScreen extends StatefulWidget {
  final Map<String, dynamic> baseItem;
  final String prompt;

  const AIResultScreen({super.key, required this.baseItem, required this.prompt});

  @override
  State<AIResultScreen> createState() => _AIResultScreenState();
}

class _AIResultScreenState extends State<AIResultScreen> {
  // mock up danh sách kết quả AI trả về
  final List<Map<String, dynamic>> _mockResults = [
    {'type': 'Thân dưới (Quần/Váy)', 'items': [
      {'itemName': 'Quần Jean ống rộng', 'primaryImageUrl': 'https://cdn.dafc.com.vn/catalog/product/dafc/1201742_000.jpg'},
      {'itemName': 'Váy chữ A đen', 'primaryImageUrl': 'https://airui.store/wp-content/uploads/2025/03/O1CN01PBIhKi1PDehbU5YhM_-3166801807-0-cib.jpg'},
    ]},
    {'type': 'Áo khoác ngoài', 'items': [
      {'itemName': 'Blazer màu be', 'primaryImageUrl': 'https://cdn.vuahanghieu.com/unsafe/0x900/left/top/smart/filters:quality(90)/https://admin.vuahanghieu.com/upload/product/2023/09/ao-khoac-blazer-nam-lacoste-vh101e-51g-02s-mau-nau-xam-size-48-650028a85b534-12092023160024.jpg'},
    ]},
    {'type': 'Phụ kiện', 'items': [
      {'itemName': 'Thắt lưng da', 'primaryImageUrl': 'https://www.gento.vn/wp-content/uploads/2021/10/day-lung-nam-da-that-D40197.jpg'},
    ]}
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Kết quả gợi ý", style: TextStyle(fontSize: 16)),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header nhắc lại món đồ gốc
          _buildResultHeader(),
          const SizedBox(height: 24),

          // Danh sách các mục gợi ý
          ..._mockResults.map((category) => _buildCategorySection(category)).toList(),
        ],
      ),
    );
  }

  Widget _buildResultHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textPink.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: widget.baseItem['primaryImageUrl'] != null
                  ? Image.network(
                widget.baseItem['primaryImageUrl'],
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.checkroom, color: Colors.grey),
              )
                  : const Icon(Icons.checkroom, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("AI phối đồ cho:", style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                    widget.baseItem['itemName'] ?? "T-shirt",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                ),
                if (widget.prompt.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                        "Yêu cầu: ${widget.prompt}",
                        style: const TextStyle(color: AppColors.textPink, fontSize: 11)
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(Map<String, dynamic> category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(category['type'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          itemCount: category['items'].length,
          itemBuilder: (context, index) {
            final item = category['items'][index];
            return ClothingItem(
              title: item['itemName'],
              imageUrl: item['primaryImageUrl'],
              onTap: () {
                // Logic chọn đồ này để tạo thành outfit hoàn chỉnh
              },
            );
          },
        ),
      ],
    );
  }
}