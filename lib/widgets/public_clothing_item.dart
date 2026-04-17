// lib/widgets/public_clothing_item.dart
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
  final bool showSaveButton; // Dùng để ẩn nút tim nếu là đồ của chính mình
  final VoidCallback? onLongPress;
  const PublicClothingItem({
    super.key,
    required this.itemId,
    required this.title,
    required this.imageUrl,
    this.likes = 0,
    this.isSaved = false,
    this.onTap,
    this.onSave,
    this.showSaveButton = true, // Mặc định là hiện
    this.onLongPress,
  });

  bool get _isNetworkImage {
    return imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  // Ảnh sản phẩm
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(15),
                    ),
                    child: _buildImage(),
                  ),

                  // Nút Trái tim (Chỉ hiện nếu showSaveButton = true)
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

            // Thông tin text bên dưới
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.trim().isEmpty ? 'Chưa đặt tên' : title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "$likes lượt thích",
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
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
        height: double.infinity, // Thêm để chiếm hết không gian Stack
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black12,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPink),
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