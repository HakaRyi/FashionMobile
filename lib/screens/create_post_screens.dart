// lib/screens/create_post_screens.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_colors.dart';
import '../constants/notification_type.dart';
import '../managers/post_manager.dart';
import '../services/account_service.dart';
import '../utils/app_notification.dart';
import 'main_screen.dart';

class CreatePostScreen extends StatefulWidget {
  final Uint8List? imageBytes; // Ảnh đơn truyền từ màn hình Thử đồ (nếu có)
  final int? eventId;
  final String? eventName;
  final Map<String, dynamic>? postToEdit;


  const CreatePostScreen({
    super.key,
    this.imageBytes,
    this.eventId,
    this.eventName,
    this.postToEdit,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final AccountService _accountService = AccountService();

  bool _isPublic = true;
  bool _isSubmitting = false;
  bool _isLoadingProfile = true;
  // SỬA: Dùng List để chứa nhiều ảnh
  List<Uint8List> _selectedImages = [];
  String? _existingImageUrl; // Chỉ dùng khi Edit bài viết cũ

  String _username = "Đang tải...";
  String _avatarUrl = "";

  bool get _isEditMode => widget.postToEdit != null;

  @override
  void initState() {
    super.initState();

    // Nếu có ảnh đơn truyền từ màn hình khác sang (ví dụ sau khi Try-on)
    if (widget.imageBytes != null) {
      _selectedImages.add(widget.imageBytes!);
    }
    _fetchProfileData();

    if (_isEditMode) {
      _contentController.text = widget.postToEdit!['content'] ?? '';
      _isPublic = widget.postToEdit!['isPublic'] ?? true;

      final List<dynamic>? urls = widget.postToEdit!['imageUrls'];
      if (urls != null && urls.isNotEmpty) {
        _existingImageUrl = urls.first.toString();
      }
    }
  }
  Future<void> _fetchProfileData() async {
    try {
      final profile = await _accountService.getMyProfile();
      if (mounted && profile != null) {
        setState(() {
          _username = profile['username'] ?? profile['userName'] ?? profile['Username'] ?? "User";
          _avatarUrl = profile['avatar'] ?? profile['Avatar'] ?? "";
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching profile in CreatePost: $e");
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // HÀM CHỌN NHIỀU ẢNH
  Future<void> _pickImage() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 80,
      );

      if (pickedFiles.isEmpty) return;

      List<Uint8List> newBytes = [];
      for (var file in pickedFiles) {
        final bytes = await file.readAsBytes();
        newBytes.add(bytes);
      }

      if (!mounted) return;

      setState(() {
        _selectedImages.addAll(newBytes);
      });
    } catch (e) {
      debugPrint('Pick image error: $e');
      if (!mounted) return;
      NotificationService.show(
        context,
        title: "Info",
        message: "Cannot Choose Image",
        type: NotificationType.info,
      );
    }
  }

  Future<void> _handlePost() async {
    if (_isSubmitting) return;
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (_selectedImages.isEmpty && title.isEmpty && content.isEmpty) {
      NotificationService.show(
        context,
        title: "Warning",
        message: "Please fill the content",
        type: NotificationType.warning,
      );
      return;
    }
    // Check điều kiện ảnh
    if (!_isEditMode && _selectedImages.isEmpty) {
      NotificationService.show(
        context,
        title: "Info",
        message: "Please Choose At least 1 image",
        type: NotificationType.info,
      );
      return;
    }

    // if (content.isEmpty) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text("Vui lòng nhập nội dung bài viết!")),
    //   );
    //   return;
    // }


    setState(() {
      _isSubmitting = true;
    });

    try {
      if (_isEditMode) {
        final int postId = widget.postToEdit!['postId'] ?? 0;
        await postManager.updatePost(
          postId: postId,
          content: content,
        );
        if (mounted) {
          NotificationService.show(
            context,
            title: "Success",
            message: "Update Successful",
            type: NotificationType.warning,
          );
        }
      } else {
        // Gửi danh sách ảnh qua postManager
        await postManager.uploadPost(
          _selectedImages,
          content,
          title: title.isEmpty ? null : title,
          eventId: widget.eventId,
        );
      }

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
            (Route<dynamic> route) => false,
      );
    } catch (e) {
      debugPrint('Handle post error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Thao tác thất bại")),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
        ),
        title: Text(
          _isEditMode ? "Edit Post" : "Create Post",
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _handlePost,
            child: Text(
              _isSubmitting ? "WAIT..." : (_isEditMode ? "SAVE" : "POST"),
              style: const TextStyle(color: AppColors.textPink, fontWeight: FontWeight.bold),
            ),
          ),
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
                  if (widget.eventId != null) _buildEventTag(),
                  _buildTitleArea(),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(color: Colors.white10, height: 1),
                  ),
                  _buildInputArea(),
                  _buildImageGrid(),
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

  Widget _buildEventTag() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.textPink.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.textPink.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_available, color: AppColors.textPink, size: 16),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                "JOINING EVENT: ${widget.eventName}",
                style: const TextStyle(color: AppColors.textPink, fontWeight: FontWeight.bold, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    if (_selectedImages.isEmpty && _existingImageUrl == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _selectedImages.length + (_existingImageUrl != null ? 1 : 0),
        itemBuilder: (context, index) {
          if (_existingImageUrl != null && index == 0) {
            return _buildImageItem(
              Image.network(_existingImageUrl!, fit: BoxFit.cover),
              onDelete: () => setState(() => _existingImageUrl = null),
            );
          }
          final imgIndex = _existingImageUrl != null ? index - 1 : index;
          return _buildImageItem(
            Image.memory(_selectedImages[imgIndex], fit: BoxFit.cover),
            onDelete: () => setState(() => _selectedImages.removeAt(imgIndex)),
          );
        },
      ),
    );
  }

  Widget _buildImageItem(Widget imageWidget, {required VoidCallback onDelete}) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageWidget,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: _isSubmitting ? null : onDelete,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
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
              Text(_username, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 2),
              const Text("What's on your mind?", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildTitleArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _titleController,
        style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold // Cho đậm lên làm tiêu đề
        ),
        decoration: const InputDecoration(
          hintText: "Post title (optional)",
          hintStyle: TextStyle(color: Colors.black26, fontSize: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
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
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, height: 1.5),
        decoration: const InputDecoration(
          hintText: "Share your style...",
          hintStyle: TextStyle(color: Colors.black38, fontSize: 18),
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
          _attachmentButton(Icons.photo_library_outlined, "Photos", _isSubmitting ? null : _pickImage),
          const SizedBox(width: 16),
          _attachmentButton(Icons.videocam_outlined, "Videos", null),
          const SizedBox(width: 16),
          _attachmentButton(Icons.location_on_outlined, "Location", null),
        ],
      ),
    );
  }

  Widget _attachmentButton(IconData icon, String label, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Icon(icon, color: AppColors.textPink, size: 22),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 14)),
            ],
          ),
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
            onTap: _isSubmitting ? null : () => setState(() => _isPublic = !_isPublic),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  Icon(_isPublic ? Icons.public : Icons.lock_outline, color: AppColors.textSecondary, size: 16),
                  const SizedBox(width: 6),
                  Text(_isPublic ? "Public" : "Private", style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary, size: 16),
                ],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _handlePost,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textPink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 0,
            ),
            child: Text(_isSubmitting ? "PROCESSING..." : (_isEditMode ? "SAVE" : "POST"), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}