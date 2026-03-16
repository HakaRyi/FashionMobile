// lib/screens/create_post_screens.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_colors.dart';
import '../managers/post_manager.dart';
import 'main_screen.dart';

class CreatePostScreen extends StatefulWidget {
  final Uint8List? imageBytes;
  final Map<String, dynamic>? postToEdit;

  const CreatePostScreen({
    super.key,
    this.imageBytes,
    this.postToEdit,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {

  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  Uint8List? _selectedImageBytes;
  String? _existingImageUrl;

  String _username = "Đang tải...";
  String _avatarUrl = "";

  bool _isPosting = false;
  double _uploadProgress = 0;

  @override
  void initState() {
    super.initState();

    _selectedImageBytes = widget.imageBytes;

    _loadUserInfo();

    if (widget.postToEdit != null) {
      _contentController.text = widget.postToEdit!['content'] ?? "";

      List<dynamic>? urls = widget.postToEdit!['imageUrls'];

      if (urls != null && urls.isNotEmpty) {
        _existingImageUrl = urls[0].toString();
      }
    }
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _username = prefs.getString('username') ?? "Người dùng";
      _avatarUrl = prefs.getString('avatar') ?? "";
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {

    try {

      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1080,
        maxHeight: 1080,
      );

      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();

      setState(() {
        _selectedImageBytes = bytes;
        _existingImageUrl = null;
      });

    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _handlePost() async {

    if (_isPosting) return;

    if (_selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn ảnh để đăng bài")),
      );
      return;
    }

    setState(() {
      _isPosting = true;
      _uploadProgress = 0;
    });

    try {

      /// Fake progress animation
      for (int i = 1; i <= 8; i++) {

        await Future.delayed(const Duration(milliseconds: 80));

        if (!mounted) return;

        setState(() {
          _uploadProgress = i / 10;
        });
      }

      await postManager.uploadPost(
        _selectedImageBytes!,
        _contentController.text,
      );

      if (!mounted) return;

      setState(() {
        _uploadProgress = 1;
      });

      await Future.delayed(const Duration(milliseconds: 200));

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const MainScreen(),
        ),
            (route) => false,
      );

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đăng bài thất bại: $e")),
      );

    } finally {

      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    bool hasImage =
        _selectedImageBytes != null || _existingImageUrl != null;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(Icons.close,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),

        title: const Text(
          "Tạo bài viết",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),

        centerTitle: true,

        actions: [
          TextButton(
            onPressed: _isPosting ? null : _handlePost,
            child: _isPosting
                ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
                : const Text(
              "ĐĂNG",
              style: TextStyle(
                color: AppColors.textPink,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [

            /// Upload progress
            if (_isPosting)
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: Colors.white12,
                valueColor:
                const AlwaysStoppedAnimation(AppColors.textPink),
              ),

            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [

                  _buildUserInfo(),

                  _buildInputArea(),

                  if (hasImage)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8),
                      child: Stack(
                        children: [

                          ClipRRect(
                            borderRadius:
                            BorderRadius.circular(12),

                            child: AnimatedSwitcher(
                              duration:
                              const Duration(milliseconds: 300),

                              child: _selectedImageBytes != null
                                  ? Image.memory(
                                _selectedImageBytes!,
                                key: const ValueKey(
                                    "memoryImage"),
                                fit: BoxFit.cover,
                                height: 300,
                                width: double.infinity,
                              )
                                  : Image.network(
                                _existingImageUrl!,
                                key: const ValueKey(
                                    "networkImage"),
                                fit: BoxFit.cover,
                                height: 300,
                                width: double.infinity,
                              ),
                            ),
                          ),

                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedImageBytes = null;
                                  _existingImageUrl = null;
                                });
                              },
                              child: Container(
                                padding:
                                const EdgeInsets.all(4),
                                decoration:
                                const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            _buildAttachmentArea(),

            const Divider(
              height: 1,
              color: Colors.white10,
            ),

            _buildBottomActionArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Padding(
      padding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.surface,
            backgroundImage: _avatarUrl.isNotEmpty
                ? NetworkImage(_avatarUrl)
                : const AssetImage(
                'assets/images/default_avatar.png')
            as ImageProvider,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                _username,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                "Bạn đang nghĩ gì?",
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding:
      const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _contentController,
        autofocus: true,
        maxLines: null,
        keyboardType:
        TextInputType.multiline,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          height: 1.5,
        ),
        decoration: const InputDecoration(
          hintText:
          "Chia sẻ phong cách của bạn...",
          hintStyle: TextStyle(
            color: Colors.white38,
            fontSize: 18,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildAttachmentArea() {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _attachmentButton(
              Icons.photo_library_outlined,
              "Ảnh",
              _pickImage),
        ],
      ),
    );
  }

  Widget _attachmentButton(
      IconData icon,
      String label,
      VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius:
      BorderRadius.circular(8),
      child: Padding(
        padding:
        const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(icon,
                color: AppColors.textPink,
                size: 22),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color:
                AppColors.textPrimary,
                fontWeight:
                FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionArea() {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,
        children: [

          const Text(
            "Công khai",
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),

          ElevatedButton(
            onPressed:
            _isPosting ? null : _handlePost,
            style: ElevatedButton.styleFrom(
              backgroundColor:
              AppColors.textPink,
              foregroundColor:
              Colors.white,
              padding:
              const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12),
              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(
                    24),
              ),
              elevation: 0,
            ),
            child: const Text(
              "Đăng",
              style: TextStyle(
                fontWeight:
                FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}