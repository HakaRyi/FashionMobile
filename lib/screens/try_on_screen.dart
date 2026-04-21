import 'dart:io';
import 'dart:convert';
import 'package:fashion_mobile/screens/deposit_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../constants/api_constants.dart';
import 'dart:typed_data';
import '../constants/notification_type.dart';
import '../utils/app_notification.dart';
import '../utils/global_event_bus.dart';
import '../utils/model_manager.dart';
import '../widgets/price_info_widget.dart';
import '../utils/try_on_manager.dart';
import './create_post_screens.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/save_outfit_dialog.dart';
import 'package:path_provider/path_provider.dart';
import '../models/try_on_source_item.dart';
import '../models/try_on_model_source.dart';
import '../widgets/try_on/wardrobe_bottom_sheet.dart';
import '../widgets/try_on/model_outfit_bottom_sheet.dart';
import '../widgets/try_on/cloth_selection_row.dart';
import '../widgets/try_on/try_on_history_list.dart';
import '../widgets/try_on/try_on_image_preview.dart';
import '../services/wallet_service.dart';

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

  int? _selectedCategoryId;

  List<dynamic> _myWardrobeItems = [];
  bool _isLoadingWardrobe = true;

  List<dynamic> _myOutfits = [];
  bool _isLoadingOutfits = true;

  final WalletService _walletService = WalletService();
  double _currentBalance = 0;
  final double _tryOnCost = 5000;
  bool _isLoadingBalance = true;

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
    _fetchWalletBalance();

    if (widget.sourceItem != null) {
      _selectedNetworkClothUrl = widget.sourceItem!.imageUrl;
      _selectedClothName = widget.sourceItem!.itemName;
      _selectedCategoryId = _mapCategoryToInt(widget.sourceItem!.category ?? '');
    }
  }

  int _mapCategoryToInt(String category) {
    final lowerCat = category.toLowerCase();
    if (lowerCat.contains('lower') || lowerCat.contains('pants') || lowerCat.contains('shorts') || lowerCat.contains('skirt') || lowerCat.contains('lower_body')) {
      return 1;
    }
    if (lowerCat.contains('full') || lowerCat.contains('dress') || lowerCat.contains('full_body')) {
      return 2;
    }
    return 0;
  }

  Future<void> _fetchWalletBalance() async {
    try {
      final balance = await _walletService.getMyWalletBalance();
      if (mounted) {
        setState(() {
          _currentBalance = balance;
          _isLoadingBalance = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching wallet balance: $e');
      if (mounted) setState(() => _isLoadingBalance = false);
    }
  }

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
          _selectedCategoryId = null;
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
      setState(() => _isPreparingNetworkCloth = true);

      final downloadedFile =
      await _downloadNetworkImageToTempFile(_selectedNetworkClothUrl!);

      setState(() => _isPreparingNetworkCloth = false);

      if (downloadedFile == null) {
        if (!mounted) return;
        NotificationService.show(
          context,
          title: "Lỗi",
          message: "Không thể tải món đồ để thử",
          type: NotificationType.error,
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

    if (mounted) {
      NotificationService.show(
        context,
        title: "Thành công",
        message: "Hệ thống đang xử lý ngầm. Bạn có thể lướt xem các mục khác!",
        type: NotificationType.success,
      );
    }

    await tryOnManager.startTryOn(
      context,
      modelAssetPath: _selectedModel.isAsset ? _selectedModel.assetPath : null,
      modelImageUrl: _selectedModel.isNetwork ? _selectedModel.imageUrl : null,
      clothFilePath: clothPath,
      category: _selectedCategoryId,
    );
    await _fetchWalletBalance();

    // if (tryOnManager.resultImageBytes != null) {
    //   GlobalEventBus().eventBus.fire(
    //     TryOnCompletedEvent(
    //       imageBytes: tryOnManager.resultImageBytes,
    //     ),
    //   );
    // }
  }

  void _showFullWardrobeBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return WardrobeBottomSheet(
          wardrobeItems: _myWardrobeItems,
          onSelect: (url, name, category) {
            setState(() {
              selectedClothFile = null;
              _selectedNetworkClothUrl = url;
              _selectedClothName = name;
              _selectedCategoryId = _mapCategoryToInt(category);
            });
          },
        );
      },
    );
  }

  void _showModelSelectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return ModelOutfitBottomSheet(
          outfits: _myOutfits,
          isLoadingOutfits: _isLoadingOutfits,
          onSelectModel: (model) {
            setState(() => _selectedModel = model);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Đã chọn ${_selectedModel.displayName}"),
                backgroundColor: Colors.green,
              ),
            );
          },
        );
      },
    );
  }

  void _clearTryOnResult() {
    tryOnManager.resetResult();
    setState(() {
      selectedClothFile = null;
      _selectedNetworkClothUrl = null;
      _selectedClothName = null;
      _selectedCategoryId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSelectedCloth =
        selectedClothFile != null ||
            (_selectedNetworkClothUrl != null && _selectedNetworkClothUrl!.trim().isNotEmpty);

    bool isNotEnoughBalance = !_isLoadingBalance && _currentBalance < _tryOnCost;
    bool canProceed = hasSelectedCloth && !isNotEnoughBalance && !_isPreparingNetworkCloth;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundSecondary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Thử đồ ảo",
          style: TextStyle(
            color: AppColors.textPrimary,
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
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(), // Hiệu ứng cuộn mượt mà
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TryOnImagePreview(
                        resultBytes: resultBytes,
                        isProcessing: isProcessing,
                        selectedModel: _selectedModel,
                        hasSelectedCloth: hasSelectedCloth,
                        selectedClothFile: selectedClothFile,
                        selectedNetworkClothUrl: _selectedNetworkClothUrl,
                        onRemoveCloth: () {
                          setState(() {
                            selectedClothFile = null;
                            _selectedNetworkClothUrl = null;
                            _selectedClothName = null;
                            _selectedCategoryId = null;
                          });
                        },
                        onEditModel: _showModelSelectionBottomSheet,
                      ),

                      if (resultBytes != null && !isProcessing)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _actionButton(Icons.delete_outline, "Xóa", Colors.redAccent, _clearTryOnResult),
                              _actionButton(Icons.file_download_outlined, "Tải về", Colors.blueAccent, () async {
                                await _saveImageToGallery(resultBytes);
                                _clearTryOnResult();
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
                                  NotificationService.show(
                                    context,
                                    title: "Thành Công",
                                    message: "Lưu đồ vào tủ đồ thành công",
                                    type: NotificationType.success,
                                  );
                                  _clearTryOnResult();
                                }
                              }),
                              _actionButton(Icons.share_outlined, "Chia sẻ", Colors.green, () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CreatePostScreen(imageBytes: resultBytes),
                                  ),
                                ).then((_) => _clearTryOnResult());
                              }),
                            ],
                          ),
                        ),

                      if (resultBytes == null && !isProcessing)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: Row(
                            children: [
                              const Icon(Icons.person, color: AppColors.textPrimary, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Model hiện tại: ${_selectedModel.displayName ?? 'Model mặc định'}",
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
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
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),

                        ClothSelectionRow(
                          wardrobeItems: _myWardrobeItems,
                          isLoading: _isLoadingWardrobe,
                          onPickImage: _pickImage,
                          onShowFullWardrobe: _showFullWardrobeBottomSheet,
                          onSelectCloth: (url, name, category) {
                            setState(() {
                              selectedClothFile = null;
                              _selectedNetworkClothUrl = url;
                              _selectedClothName = name;
                              _selectedCategoryId = _mapCategoryToInt(category);
                            });
                          },
                        ),

                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            "Lịch sử thử đồ",
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),

                        const TryOnHistoryList(),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ),

              if (resultBytes == null && !isProcessing)
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 15, 20, 25),
                  decoration: BoxDecoration(
                    color: AppColors.mainBackground,
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
                                value: _isLoadingBalance ? "..." : "${_currentBalance.toInt()} đ",
                                color: Colors.grey,
                                valueTextColor: AppColors.textSecondary,
                              ),
                              const SizedBox(height: 8),
                              PriceInfoWidget(
                                label: "Chi phí:",
                                value: "${_tryOnCost.toInt()} đ",
                                color: AppColors.textPink,
                                valueTextColor: AppColors.textPrimary,
                              ),

                            ],
                          ),
                          const Spacer(),
                          Container(
                            height: 50,
                            width: MediaQuery.of(context).size.width * 0.45,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              gradient: isNotEnoughBalance
                                  ? const LinearGradient(colors: [Colors.orange, Colors.deepOrange])
                                  : (canProceed && !isProcessing
                                  ? const LinearGradient(colors: [Color(0xFFFC00A6), Color(0xFFB50076)])
                                  : null),
                              color: (!canProceed && !isNotEnoughBalance || isProcessing)
                                  ? AppColors.textPrimary.withOpacity(0.1)
                                  : null,
                            ),
                            child: ElevatedButton(
                              onPressed: isNotEnoughBalance
                                  ? () {

                                Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => DepositScreen()))
                                    .then((_) => _fetchWalletBalance());

                              }
                                  : (canProceed && !isProcessing ? _handleStartTryOn : null),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  side: BorderSide(color: AppColors.borderPrimary, width: 2)
                                ),
                              ),
                              child: Text(
                                isNotEnoughBalance
                                    ? "NẠP THÊM"
                                    : (_isPreparingNetworkCloth
                                    ? "ĐANG CHUẨN BỊ..."
                                    : "THỬ ĐỒ NGAY"),
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