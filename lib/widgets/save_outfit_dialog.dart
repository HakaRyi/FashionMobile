import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/outfit_service.dart';

class SaveOutfitDialog extends StatefulWidget {
  final Uint8List imageBytes;
  const SaveOutfitDialog({super.key, required this.imageBytes});

  @override
  State<SaveOutfitDialog> createState() => _SaveOutfitDialogState();
}

class _SaveOutfitDialogState extends State<SaveOutfitDialog> with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final OutfitService _outfitService = OutfitService();
  bool _isSaving = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_nameController.text.isEmpty) return;

    setState(() => _isSaving = true);
    bool success = await _outfitService.saveOutfit(widget.imageBytes, _nameController.text);
    setState(() => _isSaving = false);

    if (mounted) {
      Navigator.pop(context, success);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Container(
                  width: 320,
                  height: 420,
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textPink.withOpacity(0.4 + (_controller.value * 0.3)),
                        blurRadius: 30 + (_controller.value * 20),
                        spreadRadius: 5,
                      )
                    ],
                  ),
                );
              },
            ),

            // Container chính
            Container(
              width: 300,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E1C38), Color(0xFF1A1A2E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: AppColors.textPink.withOpacity(0.5), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 40),
                  const SizedBox(height: 10),
                  const Text(
                    "Lưu Bộ Đồ Xinh",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cursive',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Ảnh preview nhỏ
                  Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white38),
                      image: DecorationImage(
                        image: MemoryImage(widget.imageBytes),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Input tên
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: "Đặt tên cho outfit này nhé...",
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.favorite, color: AppColors.textPink, size: 20),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nút Lưu
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textPink,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        elevation: 8,
                        shadowColor: AppColors.textPink.withOpacity(0.5),
                      ),
                      child: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Lưu Ngay", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          SizedBox(width: 8),
                          Icon(Icons.stars, color: Colors.amberAccent),
                        ],
                      ),
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
}