import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class ClothSelectionRow extends StatelessWidget {
  final List<dynamic> wardrobeItems;
  final bool isLoading;
  final VoidCallback onPickImage;
  final VoidCallback onShowFullWardrobe;
  final Function(String url, String name, String category) onSelectCloth;

  const ClothSelectionRow({
    super.key,
    required this.wardrobeItems,
    required this.isLoading,
    required this.onPickImage,
    required this.onShowFullWardrobe,
    required this.onSelectCloth,
  });

  Widget _buildItem(dynamic item, {bool isOverlay = false, int remainingCount = 0}) {
    return GestureDetector(
      onTap: () {
        if (isOverlay) {
          onShowFullWardrobe();
        } else {
          onSelectCloth(
            item['primaryImageUrl'] ?? '',
            item['itemName'] ?? '',
            item['category']?.toString() ?? '',
          );
        }
      },
      child: Container(
        width: 75,
        height: 75,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSecondary, width: 1.5),
          image: DecorationImage(
            image: NetworkImage(item['primaryImageUrl'] ?? ''),
            fit: BoxFit.cover,
          ),
        ),
        child: isOverlay
            ? Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.black.withOpacity(0.6),
          ),
          child: Center(
            child: Text(
              "+$remainingCount",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 75,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.textPink))
          : Row(
        children: [
          if (wardrobeItems.isNotEmpty)
            _buildItem(wardrobeItems[0]),

          if (wardrobeItems.length > 1)
            _buildItem(wardrobeItems[1]),

          if (wardrobeItems.length > 2)
            _buildItem(
              wardrobeItems[2],
              isOverlay: wardrobeItems.length > 3,
              remainingCount: wardrobeItems.length - 2,
            ),

          GestureDetector(
            onTap: onPickImage,
            child: Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black26, width: 1.5),
              ),
              child: const Center(
                child: Icon(Icons.add_photo_alternate_outlined, color: Colors.black26, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }
}