import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ClothingItem extends StatelessWidget {
  final String title;
  final String? imageUrl; // Dấu ? nghĩa là có thể null

  const ClothingItem({
    super.key,
    required this.title,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Container(
                width: double.infinity,
                color: Colors.white10,
                child: imageUrl != null
                    ? Image.asset(imageUrl!, fit: BoxFit.cover)
                    : const Icon(Icons.checkroom, color: Colors.grey, size: 50),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis, // Nếu tên dài quá sẽ hiện dấu ...
            ),
          ),
        ],
      ),
    );
  }
}