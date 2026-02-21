import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/post_service.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final PostManager postManager = PostManager();

class PostManager extends ChangeNotifier {
  bool isUploading = false;
  double uploadProgress = 0.0;
  final PostService _postService = PostService();

  Future<void> uploadPost(Uint8List imageBytes, String content, bool isPublic) async {
    isUploading = true;
    uploadProgress = 0.0;
    notifyListeners();

    Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (!isUploading) {
        timer.cancel();
      } else if (uploadProgress < 0.9) {
        uploadProgress += 0.1;
        notifyListeners();
      }
    });

    final isSuccess = await _postService.createPost(imageBytes, content, isPublic);

    isUploading = false;
    uploadProgress = 1.0;
    notifyListeners();

    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(isSuccess ? "Đã đăng bài thành công!" : "Đăng bài thất bại, vui lòng thử lại!"),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));
    uploadProgress = 0.0;
    notifyListeners();
  }
}