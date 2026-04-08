// lib/screens/try_on_screen.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:fashion_mobile/screens/try_on_history_detail.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shimmer/shimmer.dart';

import '../constants/app_colors.dart';
import '../models/try_on_history_model.dart';
import '../models/try_on_model_source.dart';
import '../models/try_on_source_item.dart';
import '../utils/model_manager.dart';
import '../utils/try_on_manager.dart';
import '../widgets/save_outfit_dialog.dart';
import 'create_model_screen.dart';
import 'create_post_screens.dart';

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
  final ImagePicker _picker = ImagePicker();

  File? _selectedClothFile;
  String? _selectedNetworkClothUrl;
  String? _selectedClothName;

  bool _isPreparingNetworkCloth = false;
  bool _isDeletingHistory = false;

  TryOnModelSource _selectedModel = const TryOnModelSource(
    assetPath: "assets/images/human1.jpg",
    displayName: "Model mặc định",
  );

  @override
  void initState() {
    super.initState();

    tryOnManager.reset();
    modelManager.fetchMyModels();
    tryOnManager.loadHistory();
    tryOnManager.loadInfo();

    final sourceItem = widget.sourceItem;
    if (sourceItem != null) {
      _selectedNetworkClothUrl = sourceItem.imageUrl;
      _selectedClothName = sourceItem.itemName;
    }
  }

  bool get _hasSelectedCloth {
    return _selectedClothFile != null ||
        (_selectedNetworkClothUrl != null &&
            _selectedNetworkClothUrl!.trim().isNotEmpty);
  }

  bool _canProceed({
    required bool isProcessing,
    required double availableBalance,
    required double tryOnCost,
  }) {
    return _hasSelectedCloth &&
        availableBalance >= tryOnCost &&
        !_isPreparingNetworkCloth &&
        !isProcessing;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      setState(() {
        _selectedClothFile = File(pickedFile.path);
        _selectedNetworkClothUrl = null;
        _selectedClothName = null;
      });
    } catch (e) {
      debugPrint('Pick image error: $e');
      _showSnackBar(
        message: "Không thể chọn ảnh từ thư viện.",
        backgroundColor: Colors.red,
      );
    }
  }

  Future<File?> _downloadNetworkImageToTempFile(String imageUrl) async {
    try {
      final response = await http
          .get(Uri.parse(imageUrl))
          .timeout(const Duration(seconds: 15));

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

    if (_selectedClothFile != null) {
      clothPath = _selectedClothFile!.path;
    } else if (_selectedNetworkClothUrl != null &&
        _selectedNetworkClothUrl!.trim().isNotEmpty) {
      setState(() {
        _isPreparingNetworkCloth = true;
      });

      final downloadedFile =
      await _downloadNetworkImageToTempFile(_selectedNetworkClothUrl!);

      if (!mounted) return;

      setState(() {
        _isPreparingNetworkCloth = false;
      });

      if (downloadedFile == null) {
        _showSnackBar(
          message: 'Không thể tải ảnh món đồ để thử.',
          backgroundColor: Colors.red,
        );
        return;
      }

      clothPath = downloadedFile.path;
    }

    if (clothPath == null || clothPath.trim().isEmpty) {
      _showSnackBar(
        message: 'Vui lòng chọn món đồ trước khi thử.',
        backgroundColor: Colors.orange,
      );
      return;
    }

    await tryOnManager.tryOn(
      context: context,
      modelAssetPath: _selectedModel.isAsset ? _selectedModel.assetPath : null,
      modelImageUrl: _selectedModel.isNetwork ? _selectedModel.imageUrl : null,
      clothPath: clothPath,
    );
  }

  void _resetTryOnState({bool clearSelectedCloth = true}) {
    tryOnManager.reset();

    setState(() {
      if (clearSelectedCloth) {
        _selectedClothFile = null;
        _selectedNetworkClothUrl = null;
        _selectedClothName = null;
      }
    });
  }

  void _removeSelectedCloth() {
    setState(() {
      _selectedClothFile = null;
      _selectedNetworkClothUrl = null;
      _selectedClothName = null;
    });
  }

  void _showSnackBar({
    required String message,
    Color backgroundColor = Colors.black87,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  Future<void> _handleSaveToWardrobe(Uint8List resultBytes) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "SaveOutfit",
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (_, animation, __, ___) {
        return Transform.scale(
          scale: animation.value,
          child: SaveOutfitDialog(imageBytes: resultBytes),
        );
      },
      transitionDuration: const Duration(milliseconds: 250),
    );

    if (result == true) {
      _showSnackBar(
        message: "✨ Đã lưu vào tủ đồ thành công!",
        backgroundColor: Colors.green,
      );
    }
  }

  Future<void> _handleShare(Uint8List resultBytes) async {
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePostScreen(imageBytes: resultBytes),
      ),
    );
  }

  Future<void> _saveImageToGallery(Uint8List bytes) async {
    try {
      final storageStatus = await Permission.storage.request();
      final photosStatus = await Permission.photos.request();
      final manageExternalStorageStatus =
      await Permission.manageExternalStorage.request();

      final granted = storageStatus.isGranted ||
          photosStatus.isGranted ||
          manageExternalStorageStatus.isGranted;

      if (!granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Vui lòng cấp quyền truy cập ảnh trong Cài đặt."),
            action: SnackBarAction(
              label: "Mở Cài đặt",
              onPressed: openAppSettings,
            ),
          ),
        );
        return;
      }

      await Gal.putImageBytes(
        bytes,
        name: "outfit_${DateTime.now().millisecondsSinceEpoch}",
      );

      _showSnackBar(
        message: "Đã lưu ảnh vào thư viện thành công!",
        backgroundColor: Colors.green,
      );
    } on GalException catch (e) {
      _showSnackBar(
        message: "Lỗi khi lưu ảnh: ${e.type.message}",
        backgroundColor: Colors.red,
      );
    } catch (e) {
      _showSnackBar(
        message: "Lỗi không xác định: $e",
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _handleDeleteHistory(TryOnHistoryModel item) async {
    if (_isDeletingHistory) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          "Xóa lịch sử",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Bạn có chắc muốn xóa lịch sử thử đồ này không?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Xóa",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    ) ??
        false;

    if (!confirmed) return;

    setState(() {
      _isDeletingHistory = true;
    });

    try {
      await tryOnManager.deleteHistory(item.id);
      _showSnackBar(
        message: "Đã xóa lịch sử thử đồ.",
        backgroundColor: Colors.green,
      );
    } catch (e) {
      _showSnackBar(
        message: "Xóa lịch sử thất bại.",
        backgroundColor: Colors.red,
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isDeletingHistory = false;
      });
    }
  }

  void _showModelSelectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
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
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: isLoading
                        ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.textPink,
                      ),
                    )
                        : models.isEmpty
                        ? _buildEmptyModelState()
                        : _buildModelGrid(models),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyModelState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.person_off_outlined,
            color: Colors.white54,
            size: 60,
          ),
          const SizedBox(height: 16),
          const Text(
            "Chưa có model, thêm ngay đi!",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreateModelScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text(
              "Thêm model mới",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textPink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelGrid(List<dynamic> models) {
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreateModelScreen(),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.textPink.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.textPink,
                  width: 2,
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add,
                    color: AppColors.textPink,
                    size: 40,
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Thêm mới",
                    style: TextStyle(
                      color: AppColors.textPink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final modelData = models[index - 1];
        final String status = modelData['status']?.toString() ?? "Active";
        final bool isReady = status == "Active";

        return GestureDetector(
          onTap: isReady
              ? () {
            setState(() {
              _selectedModel = TryOnModelSource(
                imageUrl: modelData['imageUrl'],
                displayName:
                modelData['name']?.toString() ?? "Model của tôi",
              );
            });

            Navigator.pop(context);

            _showSnackBar(
              message:
              "Đã chọn ${_selectedModel.displayName ?? 'model'}",
              backgroundColor: Colors.green,
            );
          }
              : null,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white24,
                    width: 1,
                  ),
                  image: DecorationImage(
                    image: NetworkImage(
                      modelData['imageUrl'] ??
                          'https://via.placeholder.com/150',
                    ),
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
                          status == "Rejected"
                              ? Icons.error_outline
                              : Icons.hourglass_empty,
                          color: status == "Rejected"
                              ? Colors.redAccent
                              : Colors.orangeAccent,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          status == "Rejected" ? "Từ chối" : "Đang xử lý",
                          style: TextStyle(
                            color: status == "Rejected"
                                ? Colors.redAccent
                                : Colors.orangeAccent,
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
  }

  Widget _buildActionButton(
      IconData icon,
      String label,
      Color color,
      VoidCallback onTap,
      ) {
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

  void _openPreviewZoom({
    required Uint8List? resultBytes,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.95),
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Center(
                  child: resultBytes != null
                      ? Image.memory(
                    resultBytes,
                    fit: BoxFit.contain,
                  )
                      : _selectedModel.isNetwork
                      ? Image.network(
                    _selectedModel.imageUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) {
                      return Image.asset(
                        "assets/images/human1.jpg",
                        fit: BoxFit.contain,
                      );
                    },
                  )
                      : Image.asset(
                    _selectedModel.assetPath ??
                        "assets/images/human1.jpg",
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPreviewImage({
    required Uint8List? resultBytes,
    required bool isProcessing,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final previewHeight = screenHeight * 0.42;

    Widget previewImage;

    if (resultBytes != null) {
      previewImage = Image.memory(
        resultBytes,
        fit: BoxFit.cover,
      );
    } else if (_selectedModel.isNetwork) {
      previewImage = Image.network(
        _selectedModel.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Image.asset(
            "assets/images/human1.jpg",
            fit: BoxFit.cover,
          );
        },
      );
    } else {
      previewImage = Image.asset(
        _selectedModel.assetPath ?? "assets/images/human1.jpg",
        fit: BoxFit.cover,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: previewHeight.clamp(280.0, 420.0),
        width: double.infinity,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () {
                if (isProcessing) return;
                _openPreviewZoom(resultBytes: resultBytes);
              },
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      previewImage,
                      if (!isProcessing)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.45),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.zoom_in,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  "Chạm để phóng to",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                    child: const Icon(
                      Icons.edit_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultActions(Uint8List resultBytes) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildActionButton(
              Icons.refresh,
              "Thử lại",
              Colors.purpleAccent,
                  () => _resetTryOnState(clearSelectedCloth: false),
            ),
            const SizedBox(width: 20),
            _buildActionButton(
              Icons.delete_outline,
              "Xóa",
              Colors.redAccent,
                  () => _resetTryOnState(clearSelectedCloth: true),
            ),
            const SizedBox(width: 20),
            _buildActionButton(
              Icons.file_download_outlined,
              "Tải về",
              Colors.blueAccent,
                  () => _saveImageToGallery(resultBytes),
            ),
            const SizedBox(width: 20),
            _buildActionButton(
              Icons.checkroom_outlined,
              "Tủ đồ",
              Colors.amber,
                  () => _handleSaveToWardrobe(resultBytes),
            ),
            const SizedBox(width: 20),
            _buildActionButton(
              Icons.share_outlined,
              "Chia sẻ",
              Colors.green,
                  () => _handleShare(resultBytes),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentModelInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
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
    );
  }

  Widget _buildClothSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            "Chọn món đồ để thử",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
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
                      border: Border.all(
                        color: Colors.white24,
                        width: 1.5,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.add_photo_alternate_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (_selectedClothFile != null) _buildLocalClothPreview(),
              if (_selectedClothFile == null &&
                  _selectedNetworkClothUrl != null &&
                  _selectedNetworkClothUrl!.trim().isNotEmpty)
                _buildNetworkClothPreview(),
            ],
          ),
        ),
        if (_selectedClothName != null && _selectedClothName!.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'Đang chọn: $_selectedClothName',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _buildLocalClothPreview() {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textPink,
          width: 2,
        ),
        image: DecorationImage(
          image: FileImage(_selectedClothFile!),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 4,
            top: 4,
            child: GestureDetector(
              onTap: _removeSelectedCloth,
              child: const Icon(
                Icons.cancel,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkClothPreview() {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textPink,
          width: 2,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              _selectedNetworkClothUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.white10,
                child: const Icon(
                  Icons.broken_image,
                  color: Colors.white54,
                ),
              ),
            ),
          ),
          Positioned(
            right: 4,
            top: 4,
            child: GestureDetector(
              onTap: _removeSelectedCloth,
              child: const Icon(
                Icons.cancel,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    final List<TryOnHistoryModel> history = tryOnManager.history;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            "Lịch sử thử đồ",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 100,
            maxHeight: 190,
          ),
          child: tryOnManager.isLoadingHistory
              ? const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(
                color: AppColors.textPink,
              ),
            ),
          )
              : history.isEmpty
              ? const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                "Chưa có lịch sử thử đồ",
                style: TextStyle(color: Colors.white54),
              ),
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];

              final DateTime parsedDate = item.createdAt;
              final String formattedDate =
                  "${parsedDate.day}/${parsedDate.month}/${parsedDate.year} "
                  "${parsedDate.hour}:${parsedDate.minute.toString().padLeft(2, '0')}";

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
                        item.imageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey,
                          child: const Icon(
                            Icons.error,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        formattedDate,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _isDeletingHistory
                          ? null
                          : () => _handleDeleteHistory(item),
                      icon: Icon(
                        Icons.delete_outline,
                        color: _isDeletingHistory
                            ? Colors.white24
                            : Colors.redAccent,
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        AppColors.textPink.withOpacity(0.2),
                        foregroundColor: AppColors.textPink,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        if (item.imageUrl.trim().isEmpty) {
                          _showSnackBar(
                            message:
                            "Lịch sử này chưa có ảnh hợp lệ.",
                            backgroundColor: Colors.orange,
                          );
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HistoryDetailScreen(
                              historyId: item.id,
                              imageUrl: item.imageUrl,
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
    );
  }

  Widget _buildInfoTile({
    required String label,
    required String value,
    required Color accentColor,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: accentColor, size: 16),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                value,
                maxLines: 1,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar({
    required bool isProcessing,
    required double totalBalance,
    required double availableBalance,
    required double tryOnCost,
  }) {
    final canProceed = _canProceed(
      isProcessing: isProcessing,
      availableBalance: availableBalance,
      tryOnCost: tryOnCost,
    );

    final buttonText = _isPreparingNetworkCloth
        ? "ĐANG CHUẨN BỊ..."
        : availableBalance < tryOnCost
        ? "KHÔNG ĐỦ TIỀN"
        : "THỬ ĐỒ NGAY";

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isTight = constraints.maxWidth < 360;

                if (isTight) {
                  return Column(
                    children: [
                      _buildInfoTile(
                        label: "Số dư",
                        value: totalBalance.toStringAsFixed(0),
                        accentColor: Colors.white,
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                      const SizedBox(height: 10),
                      _buildInfoTile(
                        label: "Chi phí",
                        value: tryOnCost.toStringAsFixed(0),
                        accentColor: AppColors.textPink,
                        icon: Icons.local_offer_outlined,
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: _buildInfoTile(
                        label: "Số dư",
                        value: totalBalance.toStringAsFixed(0),
                        accentColor: Colors.white,
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildInfoTile(
                        label: "Chi phí",
                        value: tryOnCost.toStringAsFixed(0),
                        accentColor: AppColors.textPink,
                        icon: Icons.local_offer_outlined,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: canProceed
                      ? const LinearGradient(
                    colors: [
                      Color(0xFFFC00A6),
                      Color(0xFFB50076),
                    ],
                  )
                      : null,
                  color: canProceed ? null : Colors.white.withOpacity(0.06),
                ),
                child: ElevatedButton(
                  onPressed: canProceed ? _handleStartTryOn : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isPreparingNetworkCloth
                              ? Icons.hourglass_top_rounded
                              : Icons.auto_awesome,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          buttonText,
                          maxLines: 1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _handleBackPressed() async {
    final hasResult = tryOnManager.resultImageBytes != null;

    if (hasResult) {
      _resetTryOnState(clearSelectedCloth: false);
      return false;
    }

    return true;
  }

  Widget _buildMainContent({
    required bool isProcessing,
    required Uint8List? resultBytes,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPreviewImage(
            resultBytes: resultBytes,
            isProcessing: isProcessing,
          ),
          if (resultBytes != null && !isProcessing)
            _buildResultActions(resultBytes),
          if (resultBytes == null && !isProcessing) ...[
            _buildCurrentModelInfo(),
            _buildClothSelector(),
            _buildHistorySection(),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final canPop = await _handleBackPressed();
        if (canPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () async {
              final canPop = await _handleBackPressed();
              if (canPop && context.mounted) {
                Navigator.pop(context);
              }
            },
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
            final bool isProcessing = tryOnManager.isProcessing;
            final Uint8List? resultBytes = tryOnManager.resultImageBytes;
            final double totalBalance = tryOnManager.balance;
            final double availableBalance = tryOnManager.available;
            final double tryOnCost = tryOnManager.price;

            return Stack(
              children: [
                _buildMainContent(
                  isProcessing: isProcessing,
                  resultBytes: resultBytes,
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: ListenableBuilder(
          listenable: tryOnManager,
          builder: (context, child) {
            final bool isProcessing = tryOnManager.isProcessing;
            final Uint8List? resultBytes = tryOnManager.resultImageBytes;
            final double totalBalance = tryOnManager.balance;
            final double availableBalance = tryOnManager.available;
            final double tryOnCost = tryOnManager.price;

            if (resultBytes != null || isProcessing) {
              return const SizedBox.shrink();
            }

            return _buildBottomActionBar(
              isProcessing: isProcessing,
              totalBalance: totalBalance,
              availableBalance: availableBalance,
              tryOnCost: tryOnCost,
            );
          },
        ),
      ),
    );
  }
}