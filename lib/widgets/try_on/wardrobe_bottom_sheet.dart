import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

class WardrobeBottomSheet extends StatelessWidget {
  final List<dynamic> wardrobeItems;
  final Function(String url, String name, String category) onSelect;

  const WardrobeBottomSheet({
    super.key,
    required this.wardrobeItems,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              "Tủ đồ của bạn",
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: wardrobeItems.length,
              itemBuilder: (context, index) {
                final item = wardrobeItems[index];
                return GestureDetector(
                  onTap: () {
                    onSelect(
                      item['primaryImageUrl'] ?? '',
                      item['itemName'] ?? '',
                      item['category']?.toString() ?? '',
                    );
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderPrimary),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.textPrimary.withOpacity(0.1),
                          blurRadius: 10,spreadRadius: 2,
                          offset: Offset.zero,
                        ),
                      ],
                      image: DecorationImage(
                        image: NetworkImage(item['primaryImageUrl'] ?? ''),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}