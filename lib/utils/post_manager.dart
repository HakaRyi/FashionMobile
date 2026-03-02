import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/post_service.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final PostManager postManager = PostManager();

class PostManager extends ChangeNotifier {
  bool isUploading = false;
  bool isLoading = true;
  double uploadProgress = 0.0;
  final PostService _postService = PostService();
  List<dynamic> posts = [];
  Timer? _progressTimer;
  String statusMessage = "Đang xử lý...";

  Future<void> uploadPost(Uint8List imageBytes, String content, bool isPublic) async {
    isUploading = true;
    uploadProgress = 0.0;
    bool hasImages = true;
    statusMessage = "Đang tải lên...";
    notifyListeners();

    _progressTimer?.cancel();

    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (uploadProgress < 0.8) {
        uploadProgress += 0.05;
      } else if (uploadProgress < 0.95) {
        uploadProgress += 0.005;
        statusMessage = "Đang gửi dữ liệu...";
        notifyListeners();
      } else {
        timer.cancel();
      }
      notifyListeners();
    });

    final isSuccess = await _postService.createPost(imageBytes, content, isPublic);
    _progressTimer?.cancel();
    if (isSuccess) {
      uploadProgress = 1.0;
      statusMessage = "Đã gửi! Đang chờ duyệt...";
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 1500));
      isUploading = false;
      notifyListeners();
      await fetchPosts();
    }

    isUploading = false;
    uploadProgress = 1.0;
    notifyListeners();

    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(isSuccess ? "Đã gửi, Đang chờ duyệt!" : "Đăng bài thất bại, vui lòng thử lại!"),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));
    uploadProgress = 0.0;
    notifyListeners();
  }

  Future<void> fetchPosts() async {
    try {
      final data = await _postService.getAllPosts();

      posts = data;
      isLoading = false;

      notifyListeners();
    } catch (e) {
      debugPrint("Lỗi: $e");
      isLoading = false;
      notifyListeners();
    }
  }
}