import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_colors.dart';
import 'dart:typed_data';
import '../utils/model_manager.dart';
import '../widgets/add_clothing_card.dart';
import '../screens/model_management_screen.dart';
import '../widgets/price_info_widget.dart';
import '../utils/try_on_manager.dart';
import './create_post_screens.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/save_outfit_dialog.dart';
import 'create_model_screen.dart';

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

  bool _isLoadingModels = true;

  final List<Map<String, dynamic>> _mockHistory = [
    {"date": "10/03/2026 14:30", "imageUrl": "https://i.pravatar.cc/150?img=1", "bytes": Uint8List(0)},
    {"date": "09/03/2026 09:15", "imageUrl": "https://i.pravatar.cc/150?img=2", "bytes": Uint8List(0)},
    {"date": "08/03/2026 20:45", "imageUrl": "https://i.pravatar.cc/150?img=3", "bytes": Uint8List(0)},
    {"date": "07/03/2026 11:20", "imageUrl": "https://i.pravatar.cc/150?img=4", "bytes": Uint8List(0)},
  ];

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

  void _showModelSelectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        // ListenableBuilder phải nằm TRONG builder của showModalBottomSheet
        return ListenableBuilder(
          listenable: modelManager,
          builder: (context, child) {
            final models = modelManager.userModels;
            final isLoading = modelManager.isLoading;

            return Container(
              padding: const EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 0.5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                        "Chọn Model",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator(color: AppColors.textPink))
                        : models.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.person_off_outlined, color: Colors.white54, size: 60),
                          const SizedBox(height: 16),
                          const Text("Chưa có model, thêm ngay đi!", style: TextStyle(color: Colors.white, fontSize: 16)),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateModelScreen()));
                            },
                            icon: const Icon(Icons.add_photo_alternate_outlined),
                            label: const Text("Thêm model mới", style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.textPink,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          )
                        ],
                      ),
                    )
                        : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1,
                      ),
                      itemCount: models.length + 1, // +1 cho nút Thêm mới
                      itemBuilder: (context, index) {
                        // Ô đầu tiên: Nút Thêm Mới
                        if (index == 0) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateModelScreen()));
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.textPink.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.textPink, width: 2),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add, color: AppColors.textPink, size: 40),
                                  SizedBox(height: 8),
                                  Text("Thêm mới", style: TextStyle(color: AppColors.textPink, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          );
                        }

                        // Các ô còn lại: Hiển thị Model
                        final modelData = models[index - 1]; // Trừ 1 vì ô đầu là nút thêm

                        // DEBUG: In ra để xem imageUrl có đúng định dạng không
                        // print("Model Image URL: ${modelData['imageUrl']}");

                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            // TODO: Xử lý logic khi người dùng nhấp chọn model này (Ví dụ lưu URL vào biến trạng thái của TryOnScreen)
                            // setState(() { currentModelUrl = modelData['imageUrl']; });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white24, width: 1),
                              image: DecorationImage(
                                // Kiểm tra null và fallback bằng ảnh mặc định nếu lỗi URL
                                image: NetworkImage(modelData['imageUrl'] ?? 'https://via.placeholder.com/150'),
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
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    modelManager.fetchMyModels();
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
              // BỎ flex ở đây để nó tự động chiếm hết không gian trống
              Expanded(
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
                            onTap: _showModelSelectionBottomSheet,
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
                      _actionButton(Icons.share_outlined, "Chia sẻ", Colors.green, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreatePostScreen(imageBytes: resultBytes),
                          ),
                        );
                      }),
                    ],
                  ),
                ),

              if (resultBytes == null && !isProcessing) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    "Chọn món đồ để thử",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  height: 90,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      SizedBox(
                        width: 80,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white24, width: 1.5),
                            ),
                            child: const Center(
                              child: Icon(Icons.add_photo_alternate_outlined, color: Colors.white, size: 28),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (selectedClothFile != null)
                        Container(
                          width: 80,
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

                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    "Lịch sử thử đồ",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),

                // Thay Expanded bằng SizedBox cố định chiều cao (khoảng 140) để không lấn át Model
                SizedBox(
                  height: 140,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _mockHistory.length,
                    itemBuilder: (context, index) {
                      final item = _mockHistory[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item["imageUrl"],
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item["date"],
                                style: const TextStyle(color: Colors.white70, fontSize: 14),
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
                                tryOnManager.setMockResultBytes(item["bytes"]);
                              },
                              child: const Text("Xem"),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],

              if (resultBytes == null && !isProcessing)
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 15, 20, 25),
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
                            height: 50,
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
                              child: const Text(
                                "THỬ ĐỒ NGAY",
                                style: TextStyle(
                                  color: Colors.white,
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