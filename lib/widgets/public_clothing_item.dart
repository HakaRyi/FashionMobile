import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class PublicClothingItem extends StatelessWidget {
  final int itemId;
  final String title;
  final String imageUrl;
  final int likes;
  final bool isSaved;
  final VoidCallback? onTap;
  final VoidCallback? onSave;
  final bool showSaveButton;
  final VoidCallback? onLongPress;

  // NEW
  final bool isForSale;
  final double? listedPrice;

  const PublicClothingItem({
    super.key,
    required this.itemId,
    required this.title,
    required this.imageUrl,
    this.likes = 0,
    this.isSaved = false,
    this.onTap,
    this.onSave,
    this.showSaveButton = true,
    this.onLongPress,
    this.isForSale = false,
    this.listedPrice,
  });

  bool get _isNetworkImage {
    return imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
  }

  String _formatPrice(double? value) {
    if (value == null) return '';
    return "${value.toStringAsFixed(0)} VND";
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(15),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: _buildImage(),
                    ),
                  ),

                  // Badge đang bán
                  if (isForSale)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.textPink,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "For Sale",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Nút save
                  if (showSaveButton)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: onSave,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSaved ? Icons.favorite : Icons.favorite_border,
                            color: isSaved ? Colors.redAccent : Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.trim().isEmpty ? 'Chưa đặt tên' : title,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  if (isForSale && listedPrice != null) ...[
                    Text(
                      _formatPrice(listedPrice),
                      style: const TextStyle(
                        color: AppColors.textPink,
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                  ],

                  Text(
                    "$likes lượt thích",
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (imageUrl.trim().isEmpty) {
      return _buildPlaceholder();
    }

    if (_isNetworkImage) {
      return Image.network(
        imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black12,
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.textPink,
              ),
            ),
          );
        },
      );
    }

    return Image.asset(
      imageUrl,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey.shade900,
      child: const Center(
        child: Icon(
          Icons.checkroom_outlined,
          color: Colors.white54,
          size: 36,
        ),
      ),
    );
  }
}