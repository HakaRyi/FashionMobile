import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/event_model.dart';
import '../../models/event_result_model.dart';
import '../../services/event_service.dart';

class MyResultDetailScreen extends StatelessWidget {
  final EventModel event;
  const MyResultDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.surface2, title: Text(event.title, style: const TextStyle(fontSize: 16, color: Colors.black54)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black54), onPressed: () => Navigator.pop(context)),),
      body: FutureBuilder<MyEventResultModel?>(
        future: EventService().getMyResult(event.eventId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("BÀI DỰ THI CỦA BẠN", style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(data.myPostImageUrl ?? '', height: 300, width: double.infinity, fit: BoxFit.cover),
                ),
                const SizedBox(height: 24),
                _buildScoreRow("Thứ hạng hiện tại", "#${data.rank}", AppColors.text),
                _buildScoreRow("Tổng điểm", "${data.myScore} pt", Colors.pinkAccent),
                const SizedBox(height: 32),
                const Text("NHẬN XÉT TỪ CHUYÊN GIA", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ...data.expertReviews.map((rev) => _buildExpertCard(rev)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildScoreRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.text, fontSize: 16)),
          Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildExpertCard(ExpertReviewModel rev) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.backgroundTertiary, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(backgroundImage: rev.expertAvatar != null ? NetworkImage(rev.expertAvatar!) : null),
              const SizedBox(width: 12),
              Expanded(child: Text(rev.expertName, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold))),
              Text("${rev.score} pt", style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(color: AppColors.text, height: 24),
          Text(rev.reason ?? "Không có nhận xét", style: const TextStyle(color: AppColors.text, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}