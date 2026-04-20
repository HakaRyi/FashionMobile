import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/recommendation_service.dart';
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

  @override
  void initState() {
    super.initState();
    // Gọi API chi tiết mà anh em mình vừa thống nhất ở Back-end
    _detailsFuture = RecommendationService().getHistoryDetail(widget.historyId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("KẾT QUẢ GỢI Ý",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.black)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.textPink));
          }

          final items = snapshot.data ?? [];

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header: Hiển thị lại món đồ gốc và prompt
              SliverToBoxAdapter(
                child: _buildHeaderInfo(),
              ),

              // Grid danh sách các món đồ gợi ý
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final item = items[index];
                      return ClothingItem(
                        title: item['itemName'] ?? "Không tên",
                        imageUrl: item['primaryImageUrl'],
                        onTap: () {
                          // Tái sử dụng ClothingDetailScreen nhưng tắt nút Edit
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ClothingDetailScreen(
                                itemData: item,
                                showEditButton: false, // Không cho sửa đồ trong lịch sử
                              ),
                            ),
                          );
                        },
                      );
                    },
                    childCount: items.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 50)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
       // border: Border.all(color: AppColors.textPink.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: widget.refImage != null
                ? Image.network(widget.refImage!, width: 60, height: 70, fit: BoxFit.cover)
                : Container(width: 60, height: 70, color: Colors.white10, child: const Icon(Icons.checkroom)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("PHỐI ĐỒ CÙNG", style: TextStyle(color: AppColors.textPink, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(widget.title, style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}