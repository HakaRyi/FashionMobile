import 'package:flutter/material.dart';
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
          height: 160,
          child: tryOnManager.isLoadingHistory
              ? const Center(
            child: CircularProgressIndicator(
              color: Colors.black,
              strokeWidth: 2,
            ),
          )
              : tryOnManager.historyList.isEmpty
              ? const Center(
            child: Text(
              "NO HISTORY",
              style: TextStyle(
                color: Colors.black26,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            itemCount: tryOnManager.historyList.length,
            itemBuilder: (context, index) {
              final item = tryOnManager.historyList[index];

              DateTime parsedDate = DateTime.tryParse(item["createdAt"] ?? "") ?? DateTime.now();
              String formattedDate = "${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year} • ${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}";

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black12, width: 1.0),
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
                          width: 50,
                          height: 50,
                          color: Colors.black12,
                          child: const Icon(Icons.broken_image_outlined, color: Colors.black26, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "FITTING RESULT",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
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
                      child: const Text(
                        "VIEW",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
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