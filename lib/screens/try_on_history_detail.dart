// lib/screens/try_on_history_detail.dart
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

import '../constants/app_colors.dart';
import '../utils/try_on_manager.dart';
import '../widgets/save_outfit_dialog.dart';
import 'create_post_screens.dart';

class HistoryDetailScreen extends StatefulWidget {
  final int? historyId;
  final String imageUrl;

  const HistoryDetailScreen({
    super.key,
    this.historyId,
    required this.imageUrl,
  });

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen>
    with TickerProviderStateMixin {
  Uint8List? _imageBytes;
  bool _isLoading = true;
  bool _isDeleting = false;

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _fetchImageBytes();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 5.0, end: 20.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  Future<void> _fetchImageBytes() async {
    try {
      final response = await http
          .get(Uri.parse(widget.imageUrl))
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _imageBytes = response.bodyBytes;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _openFullScreenImage() {
    if (_imageBytes == null) return;

    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (_, __, ___) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Center(
                    child: Image.memory(
                      _imageBytes!,
                      fit: BoxFit.cover, // giữ nguyên như bạn muốn
                      width: double.infinity,
                    ),
                  ),
                ),

                // nút đóng
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleDeleteHistory() async {
    if (_isDeleting || widget.historyId == null) return;

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
      _isDeleting = true;
    });

    try {
      await tryOnManager.deleteHistory(widget.historyId!);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đã xóa lịch sử thử đồ."),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Xóa lịch sử thất bại."),
          backgroundColor: Colors.red,
        ),
      );
    }
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Vui lòng cấp quyền truy cập ảnh."),
              action: SnackBarAction(
                label: "Cài đặt",
                onPressed: openAppSettings,
              ),
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
            content: Text("Đã lưu ảnh!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lỗi lưu ảnh"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleSaveToWardrobe() async {
    if (_imageBytes == null) return;

    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Save",
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (_, animation, __, ___) {
        return Transform.scale(
          scale: animation.value,
          child: SaveOutfitDialog(imageBytes: _imageBytes!),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✨ Đã lưu vào tủ đồ!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _handleShare() async {
    if (_imageBytes == null || !mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePostScreen(imageBytes: _imageBytes!),
      ),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Widget _buildTwinklingStar() {
    final random = Random();
    final top = random.nextDouble() * 500;
    final left = random.nextDouble() * 350;
    final delay = random.nextInt(1000);
    final size = random.nextDouble() * 15 + 10;

    return Positioned(
      top: top,
      left: left,
      child: TwinklingStarWidget(delay: delay, size: size),
    );
  }

  Widget _glowingActionButton(
      IconData icon,
      String label,
      Color color,
      VoidCallback? onTap,
      ) {
    final isDisabled = onTap == null;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(isDisabled ? 0.06 : 0.15),
                  shape: BoxShape.circle,
                  boxShadow: isDisabled
                      ? []
                      : [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                  border: Border.all(
                    color: color.withOpacity(isDisabled ? 0.2 : 0.6),
                    width: 1.5,
                  ),
                ),
                child: child,
              );
            },
            child: Icon(
              icon,
              color: isDisabled ? Colors.white30 : color,
              size: 28,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: isDisabled ? Colors.white30 : color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              shadows: isDisabled
                  ? []
                  : [Shadow(color: color, blurRadius: 8)],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _imageBytes != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Kết quả thử đồ",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: AppColors.textPink),
      )
          : !hasImage
          ? const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            "Không thể tải ảnh lịch sử thử đồ.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ),
      )
          : Column(
        children: [
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ...List.generate(15, (_) => _buildTwinklingStar()),
                  AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) {
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 24,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.textPink
                                  .withOpacity(0.6),
                              blurRadius: _glowAnimation.value,
                              spreadRadius:
                              _glowAnimation.value / 2,
                            ),
                            BoxShadow(
                              color: Colors.purpleAccent
                                  .withOpacity(0.4),
                              blurRadius:
                              _glowAnimation.value * 1.5,
                              spreadRadius:
                              _glowAnimation.value / 4,
                            ),
                          ],
                        ),
                        child: child,
                      );
                    },
                    child: GestureDetector(
                      onTap: _openFullScreenImage,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              color: Colors.black,
                              child: Center(
                                child: Image.memory(
                                  _imageBytes!,
                                  fit: BoxFit.cover, // 🔥 QUAN TRỌNG: đổi lại cover
                                  width: double.infinity,
                                ),
                              ),
                            ),

                            // label nhỏ góc trái
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.zoom_in, color: Colors.white, size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      "Chạm để phóng to",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 24,
                horizontal: 12,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _glowingActionButton(
                    Icons.delete_outline,
                    "Xóa",
                    Colors.redAccent,
                    _isDeleting ? null : _handleDeleteHistory,
                  ),
                  _glowingActionButton(
                    Icons.file_download_outlined,
                    "Tải về",
                    Colors.blueAccent,
                        () => _saveImageToGallery(_imageBytes!),
                  ),
                  _glowingActionButton(
                    Icons.checkroom_outlined,
                    "Tủ đồ",
                    Colors.amber,
                    _handleSaveToWardrobe,
                  ),
                  _glowingActionButton(
                    Icons.share_outlined,
                    "Chia sẻ",
                    Colors.greenAccent,
                    _handleShare,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TwinklingStarWidget extends StatefulWidget {
  final int delay;
  final double size;

  const TwinklingStarWidget({
    super.key,
    required this.delay,
    required this.size,
  });

  @override
  State<TwinklingStarWidget> createState() => _TwinklingStarWidgetState();
}

class _TwinklingStarWidgetState extends State<TwinklingStarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: ScaleTransition(
        scale: _controller,
        child: Icon(
          Icons.star_rounded,
          color: Colors.yellowAccent.withOpacity(0.8),
          size: widget.size,
          shadows: const [Shadow(color: Colors.white, blurRadius: 10)],
        ),
      ),
    );
  }
}