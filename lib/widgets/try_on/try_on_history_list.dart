// MỞ FILE: lib/widgets/try_on/try_on_history_list.dart
// ---> BẮT ĐẦU SỬA
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../screens/try_on_history_detail.dart';
import '../../utils/try_on_manager.dart';

class TryOnHistoryList extends StatelessWidget {
  const TryOnHistoryList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: tryOnManager,
      builder: (context, child) {
        return SizedBox(
          height: 140,
          child: tryOnManager.isLoadingHistory
              ? const Center(child: CircularProgressIndicator(color: AppColors.textPink))
              : tryOnManager.historyList.isEmpty
              ? const Center(child: Text("Chưa có lịch sử thử đồ", style: TextStyle(color: Colors.white54)))
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: tryOnManager.historyList.length,
            itemBuilder: (context, index) {
              final item = tryOnManager.historyList[index];

              DateTime parsedDate = DateTime.tryParse(item["createdAt"] ?? "") ?? DateTime.now();
              String formattedDate = "${parsedDate.day}/${parsedDate.month}/${parsedDate.year} ${parsedDate.hour}:${parsedDate.minute.toString().padLeft(2, '0')}";

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item["imageUrl"] ?? "",
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Container(
                          width: 50, height: 50, color: Colors.grey,
                          child: const Icon(Icons.error, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        formattedDate,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textPink.withOpacity(0.2),
                        foregroundColor: AppColors.textPink,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HistoryDetailScreen(
                              imageUrl: item["imageUrl"] ?? "",
                            ),
                          ),
                        );
                      },
                      child: const Text("Xem"),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}