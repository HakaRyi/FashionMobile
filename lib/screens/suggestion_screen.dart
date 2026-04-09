import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../services/recommendation_service.dart'; // Giả sử service của ní tên này
import '../models/recommendation_history_model.dart';
import 'history_detail_screen.dart'; // Model của ní

class SuggestionScreen extends StatefulWidget {
  const SuggestionScreen({super.key});

  @override
  State<SuggestionScreen> createState() => _SuggestionScreenState();
}

class _SuggestionScreenState extends State<SuggestionScreen> {
  // Thay thế bằng hàm gọi API thực tế của Đăng
  late Future<List<RecommendationHistoryModel>> _historyFuture;

  @override
  void initState() {
    super.initState();

    _historyFuture = RecommendationService().getMyHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "LỊCH SỬ GỢI Ý",
          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 2),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.textPink));
          }

          final historyList = snapshot.data ?? [];

          if (historyList.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            physics: const BouncingScrollPhysics(),
            itemCount: historyList.length,
            itemBuilder: (context, index) {
              final history = snapshot.data![index];
              return _buildHistoryCard(history);
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(RecommendationHistoryModel history) { // Ép kiểu rõ ràng ở đây
    // Dùng dấu CHẤM (.) thay vì ngoặc vuông ([])
    final DateTime date = history.createdAt;
    final String prompt = history.prompt.isEmpty ? "Gợi ý tự động" : history.prompt;
    final String? refImage = history.referenceItemImage;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HistoryDetailScreen(
              historyId: history.id,
              title: history.referenceItemName ?? "Gợi ý phối đồ",
              refImage: history.referenceItemImage,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [

            Container(
              width: 70,
              height: 85,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                image: refImage != null
                    ? DecorationImage(image: NetworkImage(refImage), fit: BoxFit.cover)
                    : null,
              ),
              child: refImage == null ? const Icon(Icons.inventory_2_outlined, color: Colors.white24) : null,
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('dd/MM • HH:mm').format(date),
                        style: const TextStyle(color: AppColors.textPink, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    prompt,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.amber, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        history.referenceItemName ?? "Gợi ý phối đồ",
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 64, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          const Text("Chưa có lịch sử phối đồ", style: TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }
}