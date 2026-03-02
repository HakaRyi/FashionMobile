import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_colors.dart';
import 'dart:typed_data';
import '../widgets/add_clothing_card.dart';
import '../screens/model_management_screen.dart';
import '../widgets/price_info_widget.dart';
import '../utils/try_on_manager.dart';
import './create_post_screens.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/save_outfit_dialog.dart';

class TryOnScreen extends StatefulWidget {
  const TryOnScreen({super.key});

  @override
  State<TryOnScreen> createState() => _TryOnScreenState();
}

class _TryOnScreenState extends State<TryOnScreen> {
  File? selectedClothFile;
  final int currentBalance = 0;
  final int tryOnCost = 0;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          selectedClothFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    bool canProceed = selectedClothFile != null && currentBalance >= tryOnCost;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Thử đồ ảo",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: tryOnManager,
        builder: (context, child) {
          final isProcessing = tryOnManager.isProcessing;
          final resultBytes = tryOnManager.resultImageBytes;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
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
                                Image.memory(resultBytes, fit: BoxFit.cover)
                              else
                                Image.asset("assets/images/human1.jpg", fit: BoxFit.cover),
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
                      if (resultBytes == null && !isProcessing)
                        Positioned(
                          bottom: 15,
                          right: 15,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ModelManagementScreen()),
                              );
                            },
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
              ),
              if (resultBytes != null && !isProcessing)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _actionButton(Icons.delete_outline, "Xóa", Colors.redAccent, () {
                        tryOnManager.resetResult();
                        setState(() => selectedClothFile = null);
                      }),

                      _actionButton(Icons.file_download_outlined, "Tải về", Colors.blueAccent, () async {
                        await _saveImageToGallery(resultBytes);
                      }),

                      // NÚT LƯU VÀO DATABASE (Giao diện cute)
                      _actionButton(Icons.save_alt_outlined, "Lưu", Colors.amber, () async {
                        final result = await showGeneralDialog<bool>(
                          context: context,
                          barrierDismissible: true,
                          barrierLabel: "Save",
                          pageBuilder: (ctx, a1, a2) => Container(),
                          transitionBuilder: (ctx, a1, a2, child) {
                            return Transform.scale(
                              scale: a1.value,
                              child: SaveOutfitDialog(imageBytes: resultBytes),
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 300),
                        );

                        if (result == true && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("✨ Đã lưu vào tủ đồ thành công!"), backgroundColor: Colors.green),
                          );
                        }
                      }),

                      // NÚT CHIA SẺ (Logic cũ của bạn)
                      _actionButton(Icons.share_outlined, "Chia sẻ", Colors.green, () {
                        if (resultBytes != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreatePostScreen(imageBytes: resultBytes),
                            ),
                          );
                        }
                      }),
                    ],
                  ),
                ),
              if (resultBytes == null) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
                  child: Text(
                    "Chọn món đồ để thử",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  height: 120,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      SizedBox(
                        width: 100,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white24, width: 1.5),
                            ),
                            child: const Center(
                              child: Icon(Icons.add_photo_alternate_outlined, color: Colors.white, size: 32),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (selectedClothFile != null)
                        Container(
                          width: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.textPink, width: 2),
                            image: DecorationImage(
                              image: FileImage(selectedClothFile!),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                right: 4,
                                top: 4,
                                child: GestureDetector(
                                  onTap: () => setState(() => selectedClothFile = null),
                                  child: const Icon(Icons.cancel, color: Colors.white, size: 20),
                                ),
                              )
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const Spacer(),
              ],
              if (resultBytes == null)
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 35),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PriceInfoWidget(
                                label: "Số dư:",
                                value: currentBalance.toString(),
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 8),
                              PriceInfoWidget(
                                label: "Chi phí:",
                                value: tryOnCost.toString(),
                                color: AppColors.textPink,
                                valueTextColor: Colors.white,
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            height: 55,
                            width: MediaQuery.of(context).size.width * 0.45,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              gradient: canProceed && !isProcessing
                                  ? const LinearGradient(colors: [Color(0xFFFC00A6), Color(0xFFB50076)])
                                  : null,
                              color: (!canProceed || isProcessing)
                                  ? Colors.white.withOpacity(0.05)
                                  : null,
                            ),
                            child: ElevatedButton(
                              onPressed: canProceed && !isProcessing
                                  ? () {
                                tryOnManager.startTryOn(
                                  context,
                                  "assets/images/human1.jpg",
                                  selectedClothFile!.path,
                                );
                              }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: Text(
                                isProcessing ? "ĐANG XỬ LÝ..." : "THỬ ĐỒ NGAY",
                                style: TextStyle(
                                  color: canProceed ? Colors.white : Colors.white24,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _saveImageToGallery(Uint8List bytes) async {
    try {
      if (!await Permission.storage.request().isGranted &&
          !await Permission.photos.request().isGranted &&
          !await Permission.manageExternalStorage.request().isGranted) {

        // Nếu user từ chối quyền, mở cài đặt
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Vui lòng cấp quyền truy cập ảnh trong Cài đặt."),
              action: SnackBarAction(label: "Mở Cài đặt", onPressed: openAppSettings),
            ),
          );
        }
        return;
      }

      await Gal.putImageBytes(
        bytes,
        name: "outfit_${DateTime.now().millisecondsSinceEpoch}",
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đã lưu ảnh vào thư viện thành công!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on GalException catch (e) {
      debugPrint(e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi khi lưu ảnh: ${e.type.message}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi không xác định: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }
}
