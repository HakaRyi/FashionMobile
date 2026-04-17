import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/app_colors.dart';
import '../widgets/save_outfit_dialog.dart';
import 'create_post_screens.dart';

class HistoryDetailScreen extends StatefulWidget {
  final String imageUrl;

  const HistoryDetailScreen({super.key, required this.imageUrl});

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> with TickerProviderStateMixin {
  Uint8List? _imageBytes;
  bool _isLoading = true;

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
      final response = await http.get(Uri.parse(widget.imageUrl));
      if (response.statusCode == 200) {
        setState(() {
          _imageBytes = response.bodyBytes;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Kết quả thử đồ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.textPink))
          : Column(
        children: [
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Lớp sao lấp lánh xung quanh
                  ...List.generate(15, (index) => _buildTwinklingStar()),

                  // Lớp ảnh với viền Glow
                  AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.textPink.withOpacity(0.6),
                              blurRadius: _glowAnimation.value,
                              spreadRadius: _glowAnimation.value / 2,
                            ),
                            BoxShadow(
                              color: Colors.purpleAccent.withOpacity(0.4),
                              blurRadius: _glowAnimation.value * 1.5,
                              spreadRadius: _glowAnimation.value / 4,
                            ),
                          ],
                        ),
                        child: child,
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.memory(
                        _imageBytes!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _glowingActionButton(Icons.delete_outline, "Xóa", Colors.redAccent, () {
                  // Logic xóa (tạm thời đóng màn hình)
                  Navigator.pop(context);
                }),
                _glowingActionButton(Icons.file_download_outlined, "Tải về", Colors.blueAccent, () async {
                  await _saveImageToGallery(_imageBytes!);
                }),
                _glowingActionButton(Icons.save_alt_outlined, "Lưu", Colors.amber, () async {
                  final result = await showGeneralDialog<bool>(
                    context: context,
                    barrierDismissible: true,
                    barrierLabel: "Save",
                    pageBuilder: (ctx, a1, a2) => Container(),
                    transitionBuilder: (ctx, a1, a2, child) {
                      return Transform.scale(
                        scale: a1.value,
                        child: SaveOutfitDialog(imageBytes: _imageBytes!),
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 300),
                  );

                  if (result == true && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("✨ Đã lưu vào tủ đồ!"), backgroundColor: Colors.green),
                    );
                  }
                }),
                _glowingActionButton(Icons.share_outlined, "Chia sẻ", Colors.greenAccent, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreatePostScreen(imageBytes: _imageBytes!),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
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

  Widget _glowingActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
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
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                  border: Border.all(color: color.withOpacity(0.6), width: 1.5),
                ),
                child: child,
              );
            },
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: color, blurRadius: 8)], // Chữ cũng phát sáng nhẹ
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveImageToGallery(Uint8List bytes) async {
    try {
      if (!await Permission.storage.request().isGranted &&
          !await Permission.photos.request().isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Vui lòng cấp quyền truy cập ảnh."),
              action: SnackBarAction(label: "Cài đặt", onPressed: openAppSettings),
            ),
          );
        }
        return;
      }

      await Gal.putImageBytes(bytes, name: "outfit_${DateTime.now().millisecondsSinceEpoch}");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã lưu ảnh!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lỗi lưu ảnh"), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// Widget Animation Ngôi sao lấp lánh riêng biệt để tối ưu hiệu năng
class TwinklingStarWidget extends StatefulWidget {
  final int delay;
  final double size;

  const TwinklingStarWidget({super.key, required this.delay, required this.size});

  @override
  State<TwinklingStarWidget> createState() => _TwinklingStarWidgetState();
}

class _TwinklingStarWidgetState extends State<TwinklingStarWidget> with SingleTickerProviderStateMixin {
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