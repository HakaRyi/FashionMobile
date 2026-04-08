import 'dart:io';
import 'dart:convert';
import 'package:fashion_mobile/screens/try_on_history_detail.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../constants/api_constants.dart';
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
import 'package:path_provider/path_provider.dart';
import '../models/try_on_source_item.dart';
import '../models/try_on_model_source.dart';

class TryOnScreen extends StatefulWidget {
  final TryOnSourceItem? sourceItem;

  const TryOnScreen({
    super.key,
    this.sourceItem,
  });

  @override
  State<TryOnScreen> createState() => _TryOnScreenState();
}

class _TryOnScreenState extends State<TryOnScreen> {
  File? selectedClothFile;
  final int currentBalance = 0;
  final int tryOnCost = 0;
  final ImagePicker _picker = ImagePicker();
  String? _selectedNetworkClothUrl;
  String? _selectedClothName;
  bool _isPreparingNetworkCloth = false;
  bool _isLoadingModels = true;

// ---> BẮT ĐẦU SỬA
  int? _selectedCategoryId;
// <--- KẾT THÚC SỬA

  List<dynamic> _myWardrobeItems = [];
  bool _isLoadingWardrobe = true;

  List<dynamic> _myOutfits = [];
  bool _isLoadingOutfits = true;

  TryOnModelSource _selectedModel = const TryOnModelSource(
    assetPath: "assets/images/human1.jpg",
    displayName: "Model mặc định",
  );

  @override
  void initState() {
    super.initState();
    modelManager.fetchMyModels();
    tryOnManager.fetchHistory();
    _fetchWardrobeItems();
    _fetchMyOutfits();

    if (widget.sourceItem != null) {
      _selectedNetworkClothUrl = widget.sourceItem!.imageUrl;
      _selectedClothName = widget.sourceItem!.itemName;
// ---> BẮT ĐẦU SỬA
      _selectedCategoryId = _mapCategoryToInt(widget.sourceItem!.category ?? '');
// <--- KẾT THÚC SỬA
    }
  }

// ---> BẮT ĐẦU SỬA
  int _mapCategoryToInt(String category) {
    final lowerCat = category.toLowerCase();
    if (lowerCat.contains('lower')
        || lowerCat.contains('pants')
        || lowerCat.contains('shorts')
        || lowerCat.contains('skirt')
        || lowerCat.contains('lower_body')) {
      return 1;
    }
    if (lowerCat.contains('full')
        || lowerCat.contains('dress')
        || lowerCat.contains('full_body')) {
      return 2;
    }
    return 0;
  }
// <--- KẾT THÚC SỬA

  Future<void> _fetchMyOutfits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/Outfit/my-outfits'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
          "ngrok-skip-browser-warning": "69420",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _myOutfits = data['data'] ?? [];
            _isLoadingOutfits = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingOutfits = false);
      }
    } catch (e) {
      debugPrint('Error fetching outfits: $e');
      if (mounted) setState(() => _isLoadingOutfits = false);
    }
  }

  Future<void> _fetchWardrobeItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getAllMyItemEndpoint}'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
          "ngrok-skip-browser-warning": "69420",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _myWardrobeItems = data['data'] ?? [];
            _isLoadingWardrobe = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingWardrobe = false);
      }
    } catch (e) {
      debugPrint('Error fetching wardrobe: $e');
      if (mounted) setState(() => _isLoadingWardrobe = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          selectedClothFile = File(pickedFile.path);
          _selectedNetworkClothUrl = null;
          _selectedClothName = null;
// ---> BẮT ĐẦU SỬA
          _selectedCategoryId = null;
// <--- KẾT THÚC SỬA
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<File?> _downloadNetworkImageToTempFile(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) return null;

      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/public_item_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      await file.writeAsBytes(response.bodyBytes);
      return file;
    } catch (e) {
      debugPrint('Download network cloth error: $e');
      return null;
    }
  }

  Future<void> _handleStartTryOn() async {
    if (tryOnManager.isProcessing) return;

    String? clothPath;

    if (selectedClothFile != null) {
      clothPath = selectedClothFile!.path;
    } else if (_selectedNetworkClothUrl != null &&
        _selectedNetworkClothUrl!.trim().isNotEmpty) {
      setState(() {
        _isPreparingNetworkCloth = true;
      });

      final downloadedFile =
      await _downloadNetworkImageToTempFile(_selectedNetworkClothUrl!);

      setState(() {
        _isPreparingNetworkCloth = false;
      });

      if (downloadedFile == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể tải ảnh món đồ để thử.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      clothPath = downloadedFile.path;
    }

    if (clothPath == null || clothPath.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn món đồ trước khi thử.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await tryOnManager.startTryOn(
      context,
      modelAssetPath: _selectedModel.isAsset ? _selectedModel.assetPath : null,
      modelImageUrl: _selectedModel.isNetwork ? _selectedModel.imageUrl : null,
      clothFilePath: clothPath,
      category: _selectedCategoryId,
    );
  }

  void _showFullWardrobeBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  "Tủ đồ của bạn",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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
                  itemCount: _myWardrobeItems.length,
                  itemBuilder: (context, index) {
                    final item = _myWardrobeItems[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedClothFile = null;
                          _selectedNetworkClothUrl = item['primaryImageUrl'];
                          _selectedClothName = item['itemName'];
// ---> BẮT ĐẦU SỬA
                          _selectedCategoryId = _mapCategoryToInt(item['category']?.toString() ?? '');
// <--- KẾT THÚC SỬA
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
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
      },
    );
  }

  void _showModelSelectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return DefaultTabController(
          length: 2,
          child: Container(
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
            height: MediaQuery.of(context).size.height * 0.65,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                      "Đổi Model / Outfit",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                ),
                const SizedBox(height: 12),
                const TabBar(
                  indicatorColor: AppColors.textPink,
                  labelColor: AppColors.textPink,
                  unselectedLabelColor: Colors.white54,
                  dividerColor: Colors.white10,
                  tabs: [
                    Tab(text: "Model của tôi"),
                    Tab(text: "Outfit của tôi"),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TabBarView(
                    children: [
                      ListenableBuilder(
                        listenable: modelManager,
                        builder: (context, child) {
                          final models = modelManager.userModels;
                          final isLoading = modelManager.isLoading;

                          if (isLoading) {
                            return const Center(child: CircularProgressIndicator(color: AppColors.textPink));
                          }

                          if (models.isEmpty) {
                            return Center(
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
                            );
                          }

                          return GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1,
                            ),
                            itemCount: models.length + 1,
                            itemBuilder: (context, index) {
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

                              final modelData = models[index - 1];
                              final String status = modelData['status']?.toString() ?? "Active";
                              final bool isReady = status == "Active";

                              return GestureDetector(
                                onTap: isReady ? () {
                                  setState(() {
                                    _selectedModel = TryOnModelSource(
                                      imageUrl: modelData['imageUrl'],
                                      displayName: modelData['name']?.toString() ?? "Model của tôi",
                                    );
                                  });

                                  Navigator.pop(context);

                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Đã chọn ${_selectedModel.displayName ?? 'model'}",
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } : null,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.white24, width: 1),
                                        image: DecorationImage(
                                          image: NetworkImage(modelData['imageUrl'] ?? 'https://via.placeholder.com/150'),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    if (!isReady)
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                status == "Rejected" ? Icons.error_outline : Icons.hourglass_empty,
                                                color: status == "Rejected" ? Colors.redAccent : Colors.orangeAccent,
                                                size: 32,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                status == "Rejected" ? "Từ chối" : "Đang xử lý",
                                                style: TextStyle(
                                                  color: status == "Rejected" ? Colors.redAccent : Colors.orangeAccent,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),

                      _isLoadingOutfits
                          ? const Center(child: CircularProgressIndicator(color: AppColors.textPink))
                          : _myOutfits.isEmpty
                          ? const Center(child: Text("Chưa có outfit nào", style: TextStyle(color: Colors.white54, fontSize: 16)))
                          : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1,
                        ),
                        itemCount: _myOutfits.length,
                        itemBuilder: (context, index) {
                          final outfit = _myOutfits[index];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedModel = TryOnModelSource(
                                  imageUrl: outfit['imageUrl'],
                                  displayName: outfit['outfitName'] ?? "Outfit",
                                );
                              });

                              Navigator.pop(context);

                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Đã chọn outfit: ${_selectedModel.displayName}",
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white24, width: 1),
                                image: DecorationImage(
                                  image: NetworkImage(outfit['imageUrl'] ?? 'https://via.placeholder.com/150'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                                  ),
                                  child: Text(
                                    outfit['outfitName'] ?? "Outfit",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWardrobeItem(dynamic item, {bool isOverlay = false, int remainingCount = 0}) {
    return GestureDetector(
      onTap: () {
        if (isOverlay) {
          _showFullWardrobeBottomSheet();
        } else {
          setState(() {
            selectedClothFile = null;
            _selectedNetworkClothUrl = item['primaryImageUrl'];
            _selectedClothName = item['itemName'];
// ---> BẮT ĐẦU SỬA
            _selectedCategoryId = _mapCategoryToInt(item['category']?.toString() ?? '');
// <--- KẾT THÚC SỬA
          });
        }
      },
      child: Container(
        width: 75,
        height: 75,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24, width: 1.5),
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
    final bool hasSelectedCloth =
        selectedClothFile != null ||
            (_selectedNetworkClothUrl != null && _selectedNetworkClothUrl!.trim().isNotEmpty);

    bool canProceed = hasSelectedCloth && currentBalance >= tryOnCost && !_isPreparingNetworkCloth;

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
                              else if (_selectedModel.isNetwork)
                                Image.network(
                                  _selectedModel.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) {
                                    return Image.asset("assets/images/human1.jpg", fit: BoxFit.cover);
                                  },
                                )
                              else
                                Image.asset(
                                  _selectedModel.assetPath ?? "assets/images/human1.jpg",
                                  fit: BoxFit.cover,
                                ),
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
                                    ]
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: selectedClothFile != null
                                      ? Image.file(selectedClothFile!, fit: BoxFit.cover)
                                      : Image.network(
                                    _selectedNetworkClothUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_,__,___) => const Icon(Icons.broken_image, color: Colors.white54),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: -8,
                                right: -8,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedClothFile = null;
                                      _selectedNetworkClothUrl = null;
                                      _selectedClothName = null;
// ---> BẮT ĐẦU SỬA
                                      _selectedCategoryId = null;
// <--- KẾT THÚC SỬA
                                    });
                                  },
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
                        setState(() {
                          selectedClothFile = null;
                          _selectedNetworkClothUrl = null;
// ---> BẮT ĐẦU SỬA
                          _selectedClothName = null;
                          _selectedCategoryId = null;
// <--- KẾT THÚC SỬA
                        });
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

              if (resultBytes == null && !isProcessing)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: Colors.white70, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Model hiện tại: ${_selectedModel.displayName ?? 'Model mặc định'}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
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

                Container(
                  height: 75,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _isLoadingWardrobe
                      ? const Center(child: CircularProgressIndicator(color: AppColors.textPink))
                      : Row(
                    children: [
                      if (_myWardrobeItems.isNotEmpty)
                        _buildWardrobeItem(_myWardrobeItems[0]),

                      if (_myWardrobeItems.length > 1)
                        _buildWardrobeItem(_myWardrobeItems[1]),

                      if (_myWardrobeItems.length > 2)
                        _buildWardrobeItem(
                          _myWardrobeItems[2],
                          isOverlay: _myWardrobeItems.length > 3,
                          remainingCount: _myWardrobeItems.length - 2,
                        ),

                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 75,
                          height: 75,
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

                SizedBox(
                  height: 140,
                  child: tryOnManager.isLoadingHistory
                      ? const Center(child: CircularProgressIndicator(color: AppColors.textPink))
                      : tryOnManager.historyList.isEmpty
                      ? const Center(child: Text("Chưa có lịch sử thử đồ", style: TextStyle(color: Colors.white54)))
                      : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: tryOnManager.historyList.length,
                    itemBuilder: (context, index) {
                      final item = tryOnManager.historyList[index];

                      DateTime parsedDate = DateTime.tryParse(item["createdAt"] ?? "") ?? DateTime.now();
                      String formattedDate = "${parsedDate.day}/${parsedDate.month}/${parsedDate.year} ${parsedDate.hour}:${parsedDate.minute.toString().padLeft(2, '0')}";

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
                                item["imageUrl"] ?? "",
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => Container(
                                  width: 50, height: 50, color: Colors.grey,
                                  child: const Icon(Icons.error, color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                formattedDate,
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
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HistoryDetailScreen(
                                      imageUrl: item["imageUrl"] ?? "",
                                    ),
                                  ),
                                );
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
                                  ? _handleStartTryOn
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: Text(
                                _isPreparingNetworkCloth
                                    ? "ĐANG CHUẨN BỊ..."
                                    : "THỬ ĐỒ NGAY",
                                style: const TextStyle(
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