import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    if (value == null) {
      return '';
    }

    final formatter = NumberFormat('#,##0', 'en_US');
    return '${formatter.format(value)} VND';
  }

  String _formatLikes(int value) {
    if (value == 1) {
      return '1 like';
    }

    return '$value likes';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.black.withOpacity(0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(22),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: _buildImage(),
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(22),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.16),
                                Colors.transparent,
                                Colors.black.withOpacity(0.05),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (isForSale)
                      Positioned(
                        top: 9,
                        left: 9,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'FOR SALE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                    if (showSaveButton)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: onSave,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.92),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              isSaved
                                  ? Icons.favorite
                                  : Icons.favorite_border_rounded,
                              color: isSaved ? Colors.redAccent : Colors.black,
                              size: 19,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(11, 10, 11, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.trim().isEmpty ? 'Unnamed item' : title.trim(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    if (isForSale && listedPrice != null) ...[
                      Text(
                        _formatPrice(listedPrice),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                    ],
                    // Row(
                    //   children: [
                    //     const Icon(
                    //       Icons.favorite_border_rounded,
                    //       color: Colors.black26,
                    //       size: 13,
                    //     ),
                    //     const SizedBox(width: 4),
                    //     Expanded(
                    //       child: Text(
                    //         _formatLikes(likes),
                    //         style: const TextStyle(
                    //           color: Colors.black45,
                    //           fontSize: 11,
                    //           fontWeight: FontWeight.w600,
                    //         ),
                    //         maxLines: 1,
                    //         overflow: TextOverflow.ellipsis,
                    //       ),
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
              ),
            ],
          ),
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
          if (progress == null) {
            return child;
          }

          return Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFFF1F1F1),
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
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
      color: const Color(0xFFF1F1F1),
      child: const Center(
        child: Icon(
          Icons.checkroom_outlined,
          color: Colors.black26,
          size: 36,
        ),
      ),
    );
  }
}