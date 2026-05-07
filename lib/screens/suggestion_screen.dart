import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../services/recommendation_service.dart';
import '../models/recommendation_history_model.dart';
import 'history_detail_screen.dart';

class SuggestionScreen extends StatefulWidget {
  const SuggestionScreen({super.key});

  @override
  State<SuggestionScreen> createState() => _SuggestionScreenState();
}

class _SuggestionScreenState extends State<SuggestionScreen> {
  late Future<List<RecommendationHistoryModel>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = RecommendationService().getMyHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Nền xám nhạt đồng bộ app
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "HISTORY",
          style: TextStyle(
              color: Colors.black,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: 0
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<RecommendationHistoryModel>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)
            );
          }

          final historyList = snapshot.data ?? [];

          if (historyList.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            physics: const BouncingScrollPhysics(),
            itemCount: historyList.length,
            itemBuilder: (context, index) {
              final history = historyList[index];
              return _buildHistoryCard(history);
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(RecommendationHistoryModel history) {
    final DateTime date = history.createdAt.isUtc
        ? history.createdAt.toLocal()
        : DateTime.parse('${history.createdAt.toIso8601String()}Z').toLocal();

    final String prompt = history.prompt.isEmpty ? "Automatic Suggestion" : history.prompt;
    final String? refImage = history.referenceItemImage;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HistoryDetailScreen(
              historyId: history.id,
              title: history.referenceItemName ?? "Outfit Suggestion",
              refImage: history.referenceItemImage,
              referenceItemId: history.referenceItemId
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white, // Card trắng tinh khôi
          borderRadius: BorderRadius.circular(24), // Bo góc sâu cho sang
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Row(
          children: [
            // Ảnh tham chiếu
            Container(
              width: 75,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                image: refImage != null
                    ? DecorationImage(image: NetworkImage(refImage), fit: BoxFit.contain)
                    : null,
              ),
              child: refImage == null
                  ? const Icon(Icons.style_outlined, color: Colors.black12, size: 30)
                  : null,
            ),
            const SizedBox(width: 16),
            // Thông tin text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          DateFormat('dd MMM, yyyy').format(date).toUpperCase(),
                          style: const TextStyle(
                              color: Colors.black45,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.black12, size: 12),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    prompt,
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.2
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                    //  const Icon(Icons.auto_awesome_outlined, color: Colors.amber, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          history.referenceItemName ?? "Style Match",
                          style: TextStyle(
                              color: Colors.black.withOpacity(0.3),
                              fontSize: 14,
                              fontWeight: FontWeight.w500
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.02),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_outlined, size: 48, color: Colors.black12),
          ),
          const SizedBox(height: 20),
          const Text(
            "NO HISTORY YET",
            style: TextStyle(
                color: Colors.black38,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 2
            ),
          ),
        ],
      ),
    );
  }
}