import 'package:fashion_mobile/screens/photoViewerScreen.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/chat_service.dart';
import 'package:intl/intl.dart';

class GroupPhotosScreen extends StatefulWidget {
  final int groupId;
  const GroupPhotosScreen({super.key, required this.groupId});

  @override
  State<GroupPhotosScreen> createState() => _GroupPhotosScreenState();
}

class _GroupPhotosScreenState extends State<GroupPhotosScreen> {
  final ChatService _chatService = ChatService();
  List<dynamic> _photos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPhotos();
  }

  Future<void> _fetchPhotos() async {
    final data = await _chatService.getPhotosInGroup(widget.groupId);
    if (mounted) {
      setState(() {
        _photos = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("File phương tiện", style: TextStyle(fontSize: 18)),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.textPink))
          : _photos.isEmpty
          ? const Center(child: Text("Chưa có hình ảnh nào", style: TextStyle(color: Colors.white38)))
          : GridView.builder(
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // 3 ảnh 1 hàng
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: _photos.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _openPhotoViewer(context, index),
            child: Hero(
              tag: "photo_${_photos[index]['photoId']}",
              child: Image.network(_photos[index]['url'], fit: BoxFit.cover),
            ),
          );
        },
      ),
    );
  }

  void _openPhotoViewer(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoViewerScreen(photos: _photos, initialIndex: initialIndex),
      ),
    );
  }
}