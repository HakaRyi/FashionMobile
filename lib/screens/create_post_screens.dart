import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart'; //
import '../constants/app_colors.dart';
import '../utils/post_manager.dart';
import 'main_screen.dart';

class CreatePostScreen extends StatefulWidget {
  final Uint8List? imageBytes;
  final Map<String, dynamic>? postToEdit;

  const CreatePostScreen({super.key, this.imageBytes, this.postToEdit});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _isPublic = true;
  Uint8List? _selectedImageBytes;
  String? _existingImageUrl;

  // Biến lưu thông tin người dùng
  String _username = "Đang tải...";
  String _avatarUrl = "";

  @override
  void initState() {
    super.initState();
    _selectedImageBytes = widget.imageBytes;
    _loadUserInfo();

    if (widget.postToEdit != null) {
      _contentController.text = widget.postToEdit!['content'] ?? "";
      _isPublic = widget.postToEdit!['isPublic'] ?? true;

      List<dynamic>? urls = widget.postToEdit!['imageUrls'];
      if (urls != null && urls.isNotEmpty) {
        _existingImageUrl = urls[0].toString();
      }
    }
  }

  // Hàm lấy dữ liệu từ SharedPreferences tương tự các màn hình khác
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
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _handlePost() {
    if (widget.postToEdit != null) {
      int postId = widget.postToEdit!['postId'] ?? 0;

      postManager.updatePost(
        postId,
        _selectedImageBytes,
        _contentController.text,
        _isPublic,
      );
    } else {
        if (_selectedImageBytes == null) {
          const SnackBar(content: Text("Vui lòng chọn ảnh để đăng bài!"));
          return;
        }
        postManager.uploadPost(_selectedImageBytes!, _contentController.text, _isPublic);
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const MainScreen(),
        ),
            (Route<dynamic> route) => false,
      );
    }

  @override
  Widget build(BuildContext context) {
    bool hasImage = _selectedImageBytes != null || _existingImageUrl != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
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
            onPressed: _handlePost,
            child: const Text("ĐĂNG", style: TextStyle(color: AppColors.textPink, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildUserInfo(),
                  _buildInputArea(),
                  if (hasImage)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _selectedImageBytes != null
                                ? Image.memory(_selectedImageBytes!,
                                              fit: BoxFit.cover,
                                              height: 300,
                                              width: double.infinity)
                                : Image.network(_existingImageUrl!,
                                              fit: BoxFit.cover,
                                              height: 300,
                                              width: double.infinity),
                          ),
                          Positioned(
                            top: 8, right: 8,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedImageBytes = null;
                                  _existingImageUrl = null; // Xóa cả ảnh cũ và mới
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                child: const Icon(Icons.close, color: Colors.white, size: 20),
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
            const Divider(height: 1, color: Colors.white10),
            _buildBottomActionArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Cập nhật CircleAvatar sử dụng _avatarUrl
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.surface,
            backgroundImage: _avatarUrl.isNotEmpty
                ? NetworkImage(_avatarUrl)
                : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hiển thị _username thực tế
              Text(
                _username,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _contentController,
        autofocus: true,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          height: 1.5,
        ),
        decoration: const InputDecoration(
          hintText: "Chia sẻ phong cách của bạn...",
          hintStyle: TextStyle(
            color: Colors.white38,
            fontSize: 18,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildAttachmentArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _attachmentButton(Icons.photo_library_outlined, "Ảnh", _pickImage),
          const SizedBox(width: 16),
          _attachmentButton(Icons.videocam_outlined, "Video", () {}),
          const SizedBox(width: 16),
          _attachmentButton(Icons.location_on_outlined, "Vị trí", () {}),
        ],
      ),
    );
  }

  Widget _attachmentButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textPink, size: 22),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.background,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isPublic = !_isPublic;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    _isPublic ? Icons.public : Icons.lock_outline,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isPublic ? "Công khai" : "Riêng tư",
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary, size: 16),
                ],
              ),
            ),
          ),
          Row(
            children: [
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
                child: const Text("Lưu nháp"),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _handlePost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textPink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Đăng",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}