import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../constants/app_colors.dart';
import '../../models/try_on_model_source.dart';

class TryOnImagePreview extends StatelessWidget {
  final Uint8List? resultBytes;
  final bool isProcessing;
  final TryOnModelSource selectedModel;
  final bool hasSelectedCloth;
  final File? selectedClothFile;
  final String? selectedNetworkClothUrl;
  final VoidCallback onRemoveCloth;
  final VoidCallback onEditModel;

  const TryOnImagePreview({
    super.key,
    this.resultBytes,
    required this.isProcessing,
    required this.selectedModel,
    required this.hasSelectedCloth,
    this.selectedClothFile,
    this.selectedNetworkClothUrl,
    required this.onRemoveCloth,
    required this.onEditModel,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 450, // Bạn có thể tăng lên 500 hoặc 550 nếu muốn hình to hơn
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (resultBytes != null)
                      Image.memory(resultBytes!, fit: BoxFit.cover)
                    else if (selectedModel.isNetwork)
                      Image.network(
                        selectedModel.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return Image.asset("assets/images/human1.jpg", fit: BoxFit.cover);
                        },
                      )
                    else
                      Image.asset(
                        selectedModel.assetPath ?? "assets/images/human1.jpg",
                        fit: BoxFit.cover,
                      ),

                    // Hiệu ứng Loading Shimmer đè lên trên khi đang gọi API
                    if (isProcessing)
                      Shimmer.fromColors(
                        baseColor: Colors.white.withOpacity(0.1),
                        highlightColor: Colors.white.withOpacity(0.5),
                        child: Container(color: Colors.white),
                      ),
                  ],
                ),
              ),
            ),

            if (hasSelectedCloth && resultBytes == null && !isProcessing)
              Positioned(
                bottom: 15,
                left: 15,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.textPink, width: 2),
                          color: Colors.black,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 5,
                              offset: const Offset(2, 2),
                            )
                          ]),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: selectedClothFile != null
                            ? Image.file(selectedClothFile!, fit: BoxFit.cover)
                            : Image.network(
                          selectedNetworkClothUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white54),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -8,
                      right: -8,
                      child: GestureDetector(
                        onTap: onRemoveCloth,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (resultBytes == null && !isProcessing)
              Positioned(
                bottom: 15,
                right: 15,
                child: GestureDetector(
                  onTap: onEditModel,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: AppColors.textPink,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_outlined, color: Colors.white, size: 22),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}