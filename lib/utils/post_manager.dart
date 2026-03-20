import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/post_service.dart';
import '../services/social_service.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
GlobalKey<ScaffoldMessengerState>();

final PostManager postManager = PostManager();

class PostManager extends ChangeNotifier {

  bool isUploading = false;
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMore = true;

  double uploadProgress = 0.0;

  final PostService _postService = PostService();

  List<dynamic> posts = [];

  DateTime? _lastCursor;

  Timer? _progressTimer;

  String statusMessage = "Đang xử lý...";



  /// ==========================
  /// LIKE / UNLIKE
  /// ==========================

  Future<void> toggleLike(int postId) async {

    final index = posts.indexWhere((p) => p['postId'] == postId);

    if (index == -1) return;

    final post = posts[index];

    final bool currentLike = post['isLiked'] ?? false;

    /// optimistic update
    post['isLiked'] = !currentLike;

    post['likeCount'] =
        (post['likeCount'] ?? 0) + (currentLike ? -1 : 1);

    notifyListeners();

    try {

      final result = await SocialService.toggleLike(postId);

      if (result != null) {

        post['isLiked'] = result['isLiked'];
        post['likeCount'] = result['likeCount'];

        notifyListeners();
      }

    } catch (e) {

      /// rollback nếu lỗi
      post['isLiked'] = currentLike;

      post['likeCount'] =
          (post['likeCount'] ?? 0) + (currentLike ? 1 : -1);

      notifyListeners();
    }
  }



  /// ==========================
  /// UPLOAD POST
  /// ==========================

  Future<bool> uploadPost(Uint8List imageBytes, String content, bool isPublic) async {
    isUploading = true;
    uploadProgress = 0.0;
    statusMessage = "Đang tải lên...";
    notifyListeners();

    _startFakeProgress(); // Hàm chạy progress ảo cho đẹp

    final isSuccess = await _postService.createPost(imageBytes, content, isPublic);

    _progressTimer?.cancel();

    if (isSuccess) {
      uploadProgress = 1.0;
      statusMessage = "Đã gửi! Đang chờ duyệt...";
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 1500));
      await fetchInitialFeed(); // Load lại bảng tin
    }

    _finishUpload(isSuccess, "Đã gửi, Đang chờ duyệt!", "Đăng bài thất bại!");
    return isSuccess;
  }

  /// ==========================
  /// UPDATE POST (Bên A - Cập nhật)
  /// ==========================
  Future<bool> updatePost(int postId, Uint8List? imageBytes, String content, bool isPublic) async {
    isUploading = true;
    uploadProgress = 0.0;
    statusMessage = "Đang cập nhật...";
    notifyListeners();

    _startFakeProgress();

    try {
      final success = await _postService.updatePost(postId, imageBytes, content, isPublic);
      _progressTimer?.cancel();

      if (success) {
        uploadProgress = 1.0;
        statusMessage = "Cập nhật thành công!";
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 1500));
        await fetchInitialFeed();
      }

      _finishUpload(success, "Cập nhật bài viết thành công!", "Cập nhật thất bại.");
      return success;
    } catch (e) {
      _progressTimer?.cancel();
      _finishUpload(false, "", "Lỗi kết nối: $e");
      return false;
    }
  }

  void _startFakeProgress() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (uploadProgress < 0.8) {
        uploadProgress += 0.05;
      } else if (uploadProgress < 0.95) {
        uploadProgress += 0.005;
        statusMessage = "Đang gửi dữ liệu...";
      } else {
        timer.cancel();
      }
      notifyListeners();
    });
  }

  void _finishUpload(bool success, String successMsg, String errorMsg) {
    isUploading = false;
    uploadProgress = success ? 1.0 : 0.0;
    notifyListeners();

    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(success ? successMsg : errorMsg),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// ==========================
  /// LOAD FEED
  /// ==========================

  Future<void> fetchInitialFeed() async {

    isLoading = true;

    posts.clear();

    _lastCursor = null;

    hasMore = true;

    notifyListeners();

    try {

      final data =
      await _postService.fetchFeed(pageSize: 10);

      if (data.isNotEmpty) {

        posts.addAll(data);

        _lastCursor =
            DateTime.parse(data.last['createdAt']);

      } else {

        hasMore = false;
      }

      isLoading = false;

      notifyListeners();

    } catch (e) {

      debugPrint("Feed error: $e");

      isLoading = false;

      notifyListeners();
    }
  }



  /// ==========================
  /// LOAD MORE
  /// ==========================

  Future<void> loadMore() async {

    if (isLoadingMore || !hasMore) return;

    isLoadingMore = true;

    notifyListeners();

    try {

      final data = await _postService.fetchFeed(
        cursor: _lastCursor,
        pageSize: 10,
      );

      if (data.isNotEmpty) {

        posts.addAll(data);

        _lastCursor =
            DateTime.parse(data.last['createdAt']);

      } else {

        hasMore = false;
      }

      isLoadingMore = false;

      notifyListeners();

    } catch (e) {

      debugPrint("Load more error: $e");

      isLoadingMore = false;

      notifyListeners();
    }
  }

  /// ==========================
  /// UPDATE COMMENT COUNT
  /// ==========================
  void increaseCommentCount(int postId) {

    final index = posts.indexWhere((p) => p['postId'] == postId);

    if (index == -1) return;

    posts[index]['commentCount'] =
        (posts[index]['commentCount'] ?? 0) + 1;

    notifyListeners();
  }
}