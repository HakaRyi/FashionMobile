import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Thêm để dùng Clipboard mặc định
import 'package:image_picker/image_picker.dart';
import 'package:super_clipboard/super_clipboard.dart'; // Thư viện mới xịn hơn
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../constants/app_colors.dart';

class ChatInputField extends StatefulWidget {
  final TextEditingController controller;
  final Function(String text, List<String> imagePaths) onSend;

  const ChatInputField({super.key, required this.controller, required this.onSend});

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  final FocusNode _focusNode = FocusNode();

  // Hàm dán ảnh "vạn năng"
  Future<void> _handlePaste() async {
    final clipboard = SystemClipboard.instance;
    if (clipboard == null) return;

    final reader = await clipboard.read();

    if (reader.canProvide(Formats.png) || reader.canProvide(Formats.jpeg)) {
      final isPng = reader.canProvide(Formats.png);
      final format = isPng ? Formats.png : Formats.jpeg;
      final extension = isPng ? 'png' : 'jpg';

      reader.getFile(format, (file) async {
        final bytes = await file.readAll();
        final tempDir = await getTemporaryDirectory();
        final fileName = 'pasted_${DateTime.now().millisecondsSinceEpoch}.$extension';
        final savedFile = File('${tempDir.path}/$fileName');
        await savedFile.writeAsBytes(bytes);

        setState(() {
          _selectedImages.add(savedFile);
        });
      });
      return;
    }

    // 2. GIẢI PHÁP DỰ PHÒNG: Kiểm tra xem có phải link ảnh không (dành cho copy image address)
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      String text = data!.text!.trim();
      if (text.startsWith('http') &&
          (text.toLowerCase().contains('.jpg') ||
              text.toLowerCase().contains('.png') ||
              text.toLowerCase().contains('.jpeg'))) {

        _showProcessingSnackBar("Đang tải ảnh từ liên kết...");
        try {
          final response = await http.get(Uri.parse(text));
          if (response.statusCode == 200) {
            final tempDir = await getTemporaryDirectory();
            final file = File('${tempDir.path}/downloaded_${DateTime.now().millisecondsSinceEpoch}.png');
            await file.writeAsBytes(response.bodyBytes);
            setState(() => _selectedImages.add(file));
          }
        } catch (e) {
          print("Lỗi tải ảnh: $e");
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bộ nhớ tạm không chứa hình ảnh")),
        );
      }
    }
  }

  void _showProcessingSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 1),
        content: Row(
          children: [
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((e) => File(e.path)));
      });
    }
  }

  void _handleSend() {
    if (widget.controller.text.trim().isEmpty && _selectedImages.isEmpty) return;
    List<String> paths = _selectedImages.map((e) => e.path).toList();
    widget.onSend(widget.controller.text.trim(), paths);
    widget.controller.clear();
    setState(() => _selectedImages.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_selectedImages.isNotEmpty)
          Container(
            height: 90,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background.withOpacity(0.8),
              border: const Border(top: BorderSide(color: Colors.white10)),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 70, height: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(image: FileImage(_selectedImages[index]), fit: BoxFit.cover),
                          border: Border.all(color: Colors.white24),
                        ),
                      ),
                      Positioned(
                        top: -8, right: -8,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedImages.removeAt(index)),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(color: AppColors.background),
          child: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.white70),
                  onPressed: _pickImage,
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: widget.controller,
                            focusNode: _focusNode,
                            maxLines: 5, minLines: 1,
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                            decoration: const InputDecoration(
                              hintText: "Nhắn tin...",
                              hintStyle: TextStyle(color: Colors.white24),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.content_paste_rounded, color: Colors.white38, size: 20),
                          onPressed: _handlePaste,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 4),
                  child: GestureDetector(
                    onTap: _handleSend,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.textPink,
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}