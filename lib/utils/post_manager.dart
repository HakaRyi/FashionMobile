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

  Future<void> uploadPost(
      Uint8List imageBytes,
      String content,
      bool isPublic,
      ) async {

    isUploading = true;

    uploadProgress = 0.0;

    statusMessage = "Đang tải lên...";

    notifyListeners();

    _progressTimer?.cancel();

    _progressTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) {

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

    final isSuccess =
    await _postService.createPost(imageBytes, content, isPublic);

    _progressTimer?.cancel();

    if (isSuccess) {

      uploadProgress = 1.0;

      statusMessage = "Đã gửi! Đang chờ duyệt...";

      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 1500));

      isUploading = false;

      notifyListeners();

      await fetchInitialFeed();
    }

    isUploading = false;

    uploadProgress = 1.0;

    notifyListeners();

    rootScaffoldMessengerKey.currentState?.showSnackBar(

      SnackBar(
        content: Text(
            isSuccess
                ? "Đã gửi, Đang chờ duyệt!"
                : "Đăng bài thất bại, vui lòng thử lại!"
        ),

        backgroundColor:
        isSuccess ? Colors.green : Colors.red,

        duration: const Duration(seconds: 3),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    uploadProgress = 0.0;

    notifyListeners();
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