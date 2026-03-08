import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  Future<bool> updatePost(int postId, Uint8List? newImageBytes, String content, bool isPublic) async {
    // 1. Reset trạng thái và bật Loading
    isUploading = true;
    uploadProgress = 0.0;
    statusMessage = "Đang chuẩn bị cập nhật...";
    notifyListeners();

    // 2. Hủy timer cũ nếu còn chạy
    _progressTimer?.cancel();

    // 3. Bắt đầu Timer chạy thanh tiến trình giả lập
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      // Giai đoạn 1: Chạy nhanh lên 80%
      if (uploadProgress < 0.8) {
        uploadProgress += 0.05;
      }
      // Giai đoạn 2: Nhích chậm từ 80% -> 95% (để đợi Server phản hồi)
      else if (uploadProgress < 0.95) {
        uploadProgress += 0.005;

        // Cập nhật thông báo tùy theo việc có sửa ảnh hay không
        if (newImageBytes != null) {
          statusMessage = "Đang tải ảnh & chờ AI duyệt...";
        } else {
          statusMessage = "Đang lưu thay đổi...";
        }
      } else {
        // Dừng ở 95% đợi kết quả API
        timer.cancel();
      }
      notifyListeners();
    });

    try {
      final success = await _postService.updatePost(postId, newImageBytes, content, isPublic);

      _progressTimer?.cancel();

      if (success) {
        uploadProgress = 1.0;
        statusMessage = "Cập nhật thành công!";
        notifyListeners();

        await Future.delayed(const Duration(milliseconds: 1500));

        // Tắt loading mode
        isUploading = false;
        uploadProgress = 0.0;
        statusMessage = "";
        notifyListeners();

        await fetchPosts();

        rootScaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text("Cập nhật bài viết thành công!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        return true;
      } else {
        // Thất bại
        isUploading = false;
        uploadProgress = 0.0;
        statusMessage = "Cập nhật thất bại.";
        notifyListeners();

        rootScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text("Lỗi: $statusMessage"),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } catch (e) {
      _progressTimer?.cancel();
      isUploading = false;
      uploadProgress = 0.0;
      statusMessage = "Lỗi kết nối";
      notifyListeners();
      debugPrint("Error updating post: $e");
      return false;
    }
  }

  // Future<void> deletePost(int postId) async {
  //   // Xóa UI tạm thời trước (Optimistic UI) để cảm giác nhanh hơn
  //   final existingPosts = List.from(posts);
  //   posts.removeWhere((p) => p['id'] == postId || p['postId'] == postId);
  //   notifyListeners();
  //
  //   // Gọi API xóa thật
  //   bool success = await _postService.deletePost(postId);
  //
  //   if (!success) {
  //     // Nếu lỗi thì hoàn tác lại UI
  //     posts = existingPosts;
  //     notifyListeners();
  //     rootScaffoldMessengerKey.currentState?.showSnackBar(
  //       const SnackBar(content: Text("Xóa thất bại, vui lòng thử lại"), backgroundColor: Colors.red),
  //     );
  //   } else {
  //     rootScaffoldMessengerKey.currentState?.showSnackBar(
  //       const SnackBar(content: Text("Đã xóa bài viết"), backgroundColor: Colors.green),
  //     );
  //   }
  // }

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