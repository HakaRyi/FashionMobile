// lib/screens/create_post_screens.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/app_colors.dart';
import '../managers/post_manager.dart';
import '../services/account_service.dart';
import '../utils/app_toast.dart';
import 'main_screen.dart';

class CreatePostScreen extends StatefulWidget {
  final Uint8List? imageBytes;
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
  static const int maxImages = 5;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final AccountService _accountService = AccountService();

  bool _isPublic = true;
  bool _isSubmitting = false;
  bool _isLoadingProfile = true;

  final List<Uint8List> _selectedImages = [];
  final List<String> _existingImageUrls = [];

  String _username = 'Loading...';
  String _avatarUrl = '';

  bool get _isEditMode => widget.postToEdit != null;

  bool get _hasNewImages => _selectedImages.isNotEmpty;

  bool get _shouldShowExistingImages => _isEditMode && !_hasNewImages;

  @override
  void initState() {
    super.initState();

    if (widget.imageBytes != null) {
      _selectedImages.add(widget.imageBytes!);
    }

    _initEditData();
    _fetchProfileData();
  }

  void _initEditData() {
    if (!_isEditMode) {
      return;
    }

    final post = widget.postToEdit!;

    _titleController.text = _readStringValue(post, [
      'title',
      'Title',
    ]);

    _contentController.text = _readStringValue(post, [
      'content',
      'Content',
    ]);

    _isPublic = post['isPublic'] == true ||
        post['visibility'] == 'Visible' ||
        post['Visibility'] == 'Visible';

    final imageValues = post['imageUrls'] ??
        post['ImageUrls'] ??
        post['images'] ??
        post['Images'];

    if (imageValues is List) {
      for (final item in imageValues) {
        if (item == null) {
          continue;
        }

        if (item is String && item.trim().isNotEmpty) {
          _existingImageUrls.add(item.trim());
          continue;
        }

        if (item is Map<String, dynamic>) {
          final url = item['imageUrl'] ??
              item['ImageUrl'] ??
              item['url'] ??
              item['Url'];

          if (url is String && url.trim().isNotEmpty) {
            _existingImageUrls.add(url.trim());
          }
        }
      }
    }
  }

  String _readStringValue(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];

      if (value is String) {
        return value;
      }
    }

    return '';
  }

  Future<void> _fetchProfileData() async {
    try {
      final profile = await _accountService.getMyProfile();

      if (!mounted) {
        return;
      }

      if (profile != null) {
        setState(() {
          _username = profile['username'] ??
              profile['userName'] ??
              profile['Username'] ??
              'User';

          _avatarUrl = profile['avatar'] ??
              profile['Avatar'] ??
              profile['avatarUrl'] ??
              profile['AvatarUrl'] ??
              '';

          _isLoadingProfile = false;
        });
      } else {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching profile in CreatePost: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final int currentCount = _selectedImages.length;
      final int remainingSlots = maxImages - currentCount;

      if (remainingSlots <= 0) {
        _showError('You can upload up to $maxImages images only.');
        return;
      }

      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 80,
      );

      if (pickedFiles.isEmpty) {
        return;
      }

      final filesToAdd = pickedFiles.take(remainingSlots).toList();
      final List<Uint8List> newBytes = [];

      for (final file in filesToAdd) {
        final bytes = await file.readAsBytes();
        newBytes.add(bytes);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedImages.addAll(newBytes);
      });

      if (pickedFiles.length > remainingSlots) {
        _showError('Only $remainingSlots more image(s) can be added.');
      }
    } catch (e) {
      debugPrint('Pick image error: $e');

      if (!mounted) {
        return;
      }

      _showError('Cannot select image: ${_normalizeError(e)}');
    }
  }

  Future<void> _handlePost() async {
    if (_isSubmitting) {
      return;
    }

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty && _selectedImages.isEmpty) {
      _showError('Post cannot be empty.');
      return;
    }

    if (!_isEditMode && _selectedImages.isEmpty) {
      _showError('Please select at least 1 image to create a post.');
      return;
    }

    if (_selectedImages.length > maxImages) {
      _showError('Maximum $maxImages images allowed.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (_isEditMode) {
        final int postId = _getEditPostId();

        if (postId <= 0) {
          throw Exception('Invalid post id.');
        }

        await postManager.updatePost(
          postId: postId,
          title: title,
          content: content,
          imageBytesList: _selectedImages.isNotEmpty ? _selectedImages : null,
        );

        if (!mounted) {
          return;
        }

        AppToast.showSuccess(
          context,
          'Post updated successfully.',
        );
      } else {
        await postManager.uploadPost(
          _selectedImages,
          content,
          title: title.isEmpty ? null : title,
          eventId: widget.eventId,
        );

        if (!mounted) {
          return;
        }

        AppToast.showSuccess(
          context,
          widget.eventId != null
              ? 'Event post created successfully.'
              : 'Post created successfully.',
        );
      }

      await Future.delayed(const Duration(milliseconds: 700));

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
            (Route<dynamic> route) => false,
      );
    } catch (e) {
      debugPrint('Handle post error: $e');

      if (!mounted) {
        return;
      }

      AppToast.showError(
        context,
        _normalizeError(e),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  int _getEditPostId() {
    if (!_isEditMode) {
      return 0;
    }

    final post = widget.postToEdit!;
    final value = post['postId'] ?? post['PostId'] ?? post['id'] ?? post['Id'];

    if (value is int) {
      return value;
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }

  String _normalizeError(Object error) {
    final text = error.toString();

    if (text.startsWith('Exception: ')) {
      return text.replaceFirst('Exception: ', '').trim();
    }

    return text;
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    AppToast.showError(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.close,
            color: AppColors.textPrimary,
          ),
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
        ),
        title: Text(
          _isEditMode ? 'Edit Post' : 'Create Post',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _handlePost,
            child: Text(
              _isSubmitting ? 'WAIT...' : (_isEditMode ? 'SAVE' : 'POST'),
              style: const TextStyle(
                color: AppColors.textPink,
                fontWeight: FontWeight.bold,
              ),
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
                    child: Divider(
                      color: Colors.white10,
                      height: 1,
                    ),
                  ),
                  _buildInputArea(),
                  if (_isEditMode) _buildEditImageHint(),
                  _buildImageGrid(),
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

  Widget _buildEventTag() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: AppColors.textPink.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.textPink.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.event_available,
              color: AppColors.textPink,
              size: 16,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'JOINING EVENT: ${widget.eventName ?? ''}',
                style: const TextStyle(
                  color: AppColors.textPink,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditImageHint() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _hasNewImages ? Icons.info_outline : Icons.image_outlined,
              color: AppColors.textPink,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _hasNewImages
                    ? 'New selected images will replace the old post images.'
                    : 'Current images are shown below. Select new photos only if you want to replace old images.',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    final bool showExisting =
        _shouldShowExistingImages && _existingImageUrls.isNotEmpty;
    final bool showSelected = _selectedImages.isNotEmpty;

    if (!showExisting && !showSelected) {
      return const SizedBox.shrink();
    }

    final int itemCount =
    showSelected ? _selectedImages.length : _existingImageUrls.length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemBuilder: (context, index) {
          if (showSelected) {
            return _buildImageItem(
              Image.memory(
                _selectedImages[index],
                fit: BoxFit.cover,
              ),
              onDelete: () {
                setState(() {
                  _selectedImages.removeAt(index);
                });
              },
            );
          }

          return _buildExistingImageItem(
            _existingImageUrls[index],
          );
        },
      ),
    );
  }

  Widget _buildExistingImageItem(String imageUrl) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Container(
                  color: AppColors.surface,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.textSecondary,
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          left: 4,
          bottom: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Current',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageItem(
      Widget imageWidget, {
        required VoidCallback onDelete,
      }) {
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
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.surface,
            backgroundImage: _avatarUrl.isNotEmpty
                ? NetworkImage(_avatarUrl)
                : const AssetImage('assets/images/default_avatar.png')
            as ImageProvider,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _isLoadingProfile
                ? const Text(
              'Loading...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _username,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _isEditMode ? 'Update your post' : "What's on your mind?",
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: TextField(
        controller: _titleController,
        enabled: !_isSubmitting,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        decoration: const InputDecoration(
          hintText: 'Post title (optional)',
          hintStyle: TextStyle(
            color: Colors.black26,
            fontSize: 20,
          ),
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
        enabled: !_isSubmitting,
        autofocus: !_isEditMode,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          height: 1.5,
        ),
        decoration: const InputDecoration(
          hintText: 'Share your style...',
          hintStyle: TextStyle(
            color: Colors.black38,
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
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          _attachmentButton(
            Icons.photo_library_outlined,
            _isEditMode ? 'Replace Photos' : 'Photos',
            _isSubmitting ? null : _pickImage,
          ),
        ],
      ),
    );
  }

  Widget _attachmentButton(
      IconData icon,
      String label,
      VoidCallback? onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Opacity(
        opacity: onTap == null ? 0.45 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: AppColors.textPink,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActionArea() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      color: AppColors.background,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: _isSubmitting
                ? null
                : () {
              setState(() {
                _isPublic = !_isPublic;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
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
                    _isPublic ? 'Public' : 'Private',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _handlePost,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textPink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
            ),
            child: Text(
              _isSubmitting ? 'PROCESSING...' : (_isEditMode ? 'SAVE' : 'POST'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}