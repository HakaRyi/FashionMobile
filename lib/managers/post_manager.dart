import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../constants/post_status_values.dart';
import '../models/my_post_model.dart';
import '../models/post_feed_model.dart';
import '../services/post_service.dart';
import '../services/reaction_service.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
GlobalKey<ScaffoldMessengerState>();

final PostManager postManager = PostManager();

class PostManager extends ChangeNotifier {
  final PostService _postService = PostService();
  final ReactionService _reactionService = ReactionService();

  final List<PostFeedModel> _posts = [];
  final Set<int> _postIds = {};

  List<PostFeedModel> get posts => List.unmodifiable(_posts);

  DateTime? _cursor;
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMore = true;

  final List<PostFeedModel> _savedPosts = [];
  List<PostFeedModel> get savedPosts => List.unmodifiable(_savedPosts);
  bool isLoadingSaved = false;

  final List<MyPostModel> _myPosts = [];
  List<MyPostModel> get myPosts => List.unmodifiable(_myPosts);
  bool isLoadingMyPosts = false;

  bool isUploading = false;
  double uploadProgress = 0;
  String statusMessage = '';

  Timer? _progressTimer;

  final Set<int> _likingPosts = {};
  final Set<int> _savingPosts = {};

  PostFeedModel? getPostOrNull(int postId) {
    try {
      return _posts.firstWhere((p) => p.postId == postId);
    } catch (_) {
      return null;
    }
  }

  MyPostModel? getMyPostOrNull(int postId) {
    try {
      return _myPosts.firstWhere((p) => p.postId == postId);
    } catch (_) {
      return null;
    }
  }

  bool isPostLiked(int postId) {
    final post = getPostOrNull(postId);
    return post?.isLiked ?? false;
  }

  bool isPostSaved(int postId) {
    final post = getPostOrNull(postId);
    return post?.isSaved ?? false;
  }

  int getLikeCount(int postId) {
    final post = getPostOrNull(postId);
    return post?.likeCount ?? 0;
  }

  int getCommentCount(int postId) {
    final post = getPostOrNull(postId);
    return post?.commentCount ?? 0;
  }

  String getMyPostStatusText(String? status) {
    switch (status) {
      case PostStatusValues.draft:
        return 'Bản nháp';
      case PostStatusValues.verifying:
        return 'Đang kiểm duyệt AI';
      case PostStatusValues.published:
        return 'Đã đăng';
      case PostStatusValues.aiRejected:
        return 'Bị AI từ chối';
      case PostStatusValues.blockedByAdmin:
        return 'Bị admin chặn';
      default:
        return status ?? 'Không rõ';
    }
  }

  bool isMyPostEditable(MyPostModel post) => post.canEdit;
  bool canHideMyPost(MyPostModel post) => post.canHide;
  bool canUnhideMyPost(MyPostModel post) => post.canUnhide;

  void replaceOrInsertTop(PostFeedModel post) {
    final index = _posts.indexWhere((p) => p.postId == post.postId);

    if (index != -1) {
      _posts[index] = post;
    } else {
      _posts.insert(0, post);
      _postIds.add(post.postId);
    }

    _syncSavedState(post);
    notifyListeners();
  }

  void removePost(int postId) {
    _posts.removeWhere((p) => p.postId == postId);
    _postIds.remove(postId);
    _savedPosts.removeWhere((p) => p.postId == postId);
    _myPosts.removeWhere((p) => p.postId == postId);
    notifyListeners();
  }

  void _syncSavedState(PostFeedModel post) {
    final savedIndex = _savedPosts.indexWhere((p) => p.postId == post.postId);

    if (post.isSaved) {
      if (savedIndex != -1) {
        _savedPosts[savedIndex] = post;
      } else {
        _savedPosts.insert(0, post);
      }
    } else {
      if (savedIndex != -1) {
        _savedPosts.removeAt(savedIndex);
      }
    }
  }

  void _updatePostEverywhere(PostFeedModel updated) {
    final feedIndex = _posts.indexWhere((p) => p.postId == updated.postId);
    if (feedIndex != -1) {
      _posts[feedIndex] = updated;
    }

    final savedIndex = _savedPosts.indexWhere((p) => p.postId == updated.postId);
    if (savedIndex != -1) {
      if (updated.isSaved) {
        _savedPosts[savedIndex] = updated;
      } else {
        _savedPosts.removeAt(savedIndex);
      }
    } else if (updated.isSaved) {
      _savedPosts.insert(0, updated);
    }
  }

  Future<void> fetchInitialFeed() async {
    if (isLoading) return;

    isLoading = true;
    hasMore = true;
    _cursor = null;

    _posts.clear();
    _postIds.clear();

    notifyListeners();

    try {
      final data = await _postService.fetchFeed(pageSize: 10);

      for (final post in data) {
        if (_postIds.add(post.postId)) {
          _posts.add(post);
        }
      }

      if (data.isNotEmpty) {
        _cursor = data.last.createdAt;
      } else {
        hasMore = false;
      }
    } catch (e) {
      debugPrint('Feed load error: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (isLoadingMore || !hasMore || isLoading) return;

    isLoadingMore = true;
    notifyListeners();

    try {
      final data = await _postService.fetchFeed(
        cursor: _cursor,
        pageSize: 10,
      );

      if (data.isEmpty) {
        hasMore = false;
      } else {
        int inserted = 0;

        for (final post in data) {
          if (_postIds.add(post.postId)) {
            _posts.add(post);
            inserted++;
          }
        }

        if (inserted == 0) {
          hasMore = false;
        } else {
          _cursor = data.last.createdAt;
        }
      }
    } catch (e) {
      debugPrint('Load more error: $e');
    }

    isLoadingMore = false;
    notifyListeners();
  }

  Future<void> fetchMyPosts({
    int page = 1,
    int pageSize = 20,
  }) async {
    if (isLoadingMyPosts) return;

    isLoadingMyPosts = true;
    notifyListeners();

    try {
      final data = await _postService.fetchMyPosts(
        page: page,
        pageSize: pageSize,
      );

      _myPosts
        ..clear()
        ..addAll(data);
    } catch (e) {
      debugPrint('Fetch my posts error: $e');
    }

    isLoadingMyPosts = false;
    notifyListeners();
  }

  Future<void> toggleLike(int postId) async {
    if (_likingPosts.contains(postId)) return;

    final index = _posts.indexWhere((p) => p.postId == postId);
    if (index == -1) return;

    final oldPost = _posts[index];
    final optimistic = oldPost.copyWith(
      isLiked: !oldPost.isLiked,
      likeCount: oldPost.isLiked ? oldPost.likeCount - 1 : oldPost.likeCount + 1,
    );

    _updatePostEverywhere(optimistic);

    _likingPosts.add(postId);
    notifyListeners();

    try {
      final result = await _reactionService.togglePostLike(postId);

      final confirmed = optimistic.copyWith(
        isLiked: result.isLiked,
        likeCount: result.likeCount,
      );

      _updatePostEverywhere(confirmed);
    } catch (_) {
      _updatePostEverywhere(oldPost);
    }

    _likingPosts.remove(postId);
    notifyListeners();
  }

  Future<void> toggleSave(int postId) async {
    if (_savingPosts.contains(postId)) return;

    final index = _posts.indexWhere((p) => p.postId == postId);
    if (index == -1) return;

    final oldPost = _posts[index];
    final optimistic = oldPost.copyWith(isSaved: !oldPost.isSaved);

    _savingPosts.add(postId);
    _updatePostEverywhere(optimistic);
    notifyListeners();

    try {
      final isSaved = oldPost.isSaved
          ? await _postService.unsavePost(postId)
          : await _postService.savePost(postId);

      final confirmed = optimistic.copyWith(isSaved: isSaved);
      _updatePostEverywhere(confirmed);
    } catch (e) {
      debugPrint('Toggle save error: $e');
      _updatePostEverywhere(oldPost);
    }

    _savingPosts.remove(postId);
    notifyListeners();
  }

  Future<void> fetchSavedPosts({
    int page = 1,
    int pageSize = 20,
  }) async {
    if (isLoadingSaved) return;

    isLoadingSaved = true;
    notifyListeners();

    try {
      final data = await _postService.fetchSavedPosts(
        page: page,
        pageSize: pageSize,
      );

      _savedPosts
        ..clear()
        ..addAll(data);

      for (final saved in data) {
        final feedIndex = _posts.indexWhere((p) => p.postId == saved.postId);
        if (feedIndex != -1) {
          _posts[feedIndex] = _posts[feedIndex].copyWith(isSaved: true);
        }
      }
    } catch (e) {
      debugPrint('Fetch saved posts error: $e');
    }

    isLoadingSaved = false;
    notifyListeners();
  }

  Future<void> hideMyPost(int postId) async {
    final index = _myPosts.indexWhere((p) => p.postId == postId);
    if (index == -1) return;

    final oldPost = _myPosts[index];
    if (!oldPost.canHide) return;

    try {
      final response = await _postService.hidePost(postId);

      _myPosts[index] = oldPost.copyWith(
        visibility: response['visibility'] ?? oldPost.visibility,
        isPubliclyVisible: response['isPubliclyVisible'] ?? false,
        canHide: false,
        canUnhide: true,
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Hide post error: $e');
      rethrow;
    }
  }

  Future<void> unhideMyPost(int postId) async {
    final index = _myPosts.indexWhere((p) => p.postId == postId);
    if (index == -1) return;

    final oldPost = _myPosts[index];
    if (!oldPost.canUnhide) return;

    try {
      final response = await _postService.unhidePost(postId);

      _myPosts[index] = oldPost.copyWith(
        visibility: response['visibility'] ?? oldPost.visibility,
        isPubliclyVisible: response['isPubliclyVisible'] ?? true,
        canHide: true,
        canUnhide: false,
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Unhide post error: $e');
      rethrow;
    }
  }

  Future<void> deleteMyPost(int postId) async {
    try {
      await _postService.deletePost(postId);
      removePost(postId);
    } catch (e) {
      debugPrint('Delete post error: $e');
      rethrow;
    }
  }

  void increaseCommentCount(int postId) {
    final index = _posts.indexWhere((p) => p.postId == postId);
    if (index == -1) return;

    final updated = _posts[index].copyWith(
      commentCount: _posts[index].commentCount + 1,
    );

    _updatePostEverywhere(updated);
    notifyListeners();
  }

  void decreaseCommentCount(int postId) {
    final index = _posts.indexWhere((p) => p.postId == postId);
    if (index == -1) return;

    final current = _posts[index];
    final updated = current.copyWith(
      commentCount: current.commentCount > 0 ? current.commentCount - 1 : 0,
    );

    _updatePostEverywhere(updated);
    notifyListeners();
  }

  void onRealtimePostCreated(PostFeedModel post) {
    replaceOrInsertTop(post);
  }

  void onRealtimePostUpdated(PostFeedModel post) {
    replaceOrInsertTop(post);
  }

  void onRealtimePostDeleted(int postId) {
    removePost(postId);
  }

  void onRealtimeLikeUpdated({
    required int postId,
    required int likeCount,
    required bool isLiked,
  }) {
    final post = getPostOrNull(postId);
    if (post == null) return;

    final updated = post.copyWith(
      likeCount: likeCount,
      isLiked: isLiked,
    );

    _updatePostEverywhere(updated);
    notifyListeners();
  }

  Future<void> uploadPost(
      List<Uint8List> imageBytesList,
      String content, {
        String? title,
      }) async {
    if (isUploading) return;

    isUploading = true;
    uploadProgress = 0;
    statusMessage = 'Đang tải lên...';
    notifyListeners();

    _startFakeProgress();

    bool success = false;

    try {
      final postId = await _postService.createPost(
        imageBytesList: imageBytesList,
        content: content,
        title: title,
      );

      success = postId != null;
    } catch (e) {
      debugPrint('Upload error: $e');
    }

    _progressTimer?.cancel();

    uploadProgress = 1;
    statusMessage = success ? 'Đã gửi! Bài đang chờ duyệt...' : 'Đăng bài thất bại';
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    isUploading = false;
    notifyListeners();

    _showUploadResult(success);

    if (success) {
      await fetchMyPosts();
    }

    uploadProgress = 0;
    statusMessage = '';
    notifyListeners();
  }

  void _startFakeProgress() {
    _progressTimer?.cancel();

    _progressTimer = Timer.periodic(
      const Duration(milliseconds: 120),
          (timer) {
        if (uploadProgress < 0.8) {
          uploadProgress += 0.05;
        } else if (uploadProgress < 0.95) {
          uploadProgress += 0.01;
          statusMessage = 'Đang gửi dữ liệu...';
        } else {
          timer.cancel();
        }

        if (uploadProgress > 1) {
          uploadProgress = 1;
        }

        notifyListeners();
      },
    );
  }

  void _showUploadResult(bool success) {
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Đã gửi, bài đang chờ duyệt!' : 'Đăng bài thất bại',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }
}