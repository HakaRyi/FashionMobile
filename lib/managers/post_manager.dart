// lib/managers/post_manager.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../constants/post_status_values.dart';
import '../models/my_post_model.dart';
import '../models/post_feed_model.dart';
import '../models/post_reaction_result.dart';
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
        return 'Nháp';
      case PostStatusValues.verifying:
        return 'Đang duyệt';
      case PostStatusValues.pendingAdmin:
        return 'Chờ admin duyệt';
      case PostStatusValues.published:
        return 'Đã đăng';
      case PostStatusValues.rejected:
        return 'Bị từ chối';
      default:
        return status ?? 'Không rõ';
    }
  }

  Color getMyPostStatusColor(String? status) {
    switch (status) {
      case PostStatusValues.published:
        return Colors.green;
      case PostStatusValues.verifying:
      case PostStatusValues.pendingAdmin:
        return Colors.orange;
      case PostStatusValues.rejected:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> fetchSavedPosts({
    bool refresh = true,
    int page = 1,
    int pageSize = 10,
  }) async {
    if (isLoadingSaved) return;

    isLoadingSaved = true;
    notifyListeners();

    try {
      final items = await _postService.fetchSavedPosts(
        page: page,
        pageSize: pageSize,
      );

      if (refresh) {
        _savedPosts
          ..clear()
          ..addAll(items);
      } else {
        _savedPosts.addAll(items);
      }
    } catch (e) {
      debugPrint('Fetch saved posts error: $e');
      rethrow;
    } finally {
      isLoadingSaved = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyPosts({
    int page = 1,
    int pageSize = 10,
  }) async {
    if (isLoadingMyPosts) return;

    isLoadingMyPosts = true;
    notifyListeners();

    try {
      final items = await _postService.fetchMyPosts(
        page: page,
        pageSize: pageSize,
      );

      _myPosts
        ..clear()
        ..addAll(items);
    } catch (e) {
      debugPrint('Fetch my posts error: $e');
      rethrow;
    } finally {
      isLoadingMyPosts = false;
      notifyListeners();
    }
  }

  Future<void> toggleLikePost(int postId) async {
    if (_likingPosts.contains(postId)) return;
    _likingPosts.add(postId);

    final post = getPostOrNull(postId);
    if (post == null) {
      _likingPosts.remove(postId);
      return;
    }

    final bool oldIsLiked = post.isLiked;
    final int oldLikeCount = post.likeCount;

    final updated = post.copyWith(
      isLiked: !oldIsLiked,
      likeCount: oldIsLiked ? oldLikeCount - 1 : oldLikeCount + 1,
    );

    _updatePostEverywhere(updated);
    notifyListeners();

    try {
      final PostReactionResult result =
      await _reactionService.togglePostLike(postId);

      final synced = updated.copyWith(
        isLiked: result.isLiked,
        likeCount: result.likeCount,
      );

      _updatePostEverywhere(synced);
    } catch (e) {
      debugPrint('Toggle like error: $e');
      _updatePostEverywhere(post);
      rethrow;
    } finally {
      _likingPosts.remove(postId);
      notifyListeners();
    }
  }

  Future<void> toggleSavePost(int postId) async {
    if (_savingPosts.contains(postId)) return;
    _savingPosts.add(postId);

    final post = getPostOrNull(postId);
    if (post == null) {
      _savingPosts.remove(postId);
      return;
    }

    final oldValue = post.isSaved;
    final optimistic = post.copyWith(isSaved: !oldValue);

    _updatePostEverywhere(optimistic);
    notifyListeners();

    try {
      final bool newValue = oldValue
          ? await _postService.unsavePost(postId)
          : await _postService.savePost(postId);

      final synced = optimistic.copyWith(isSaved: newValue);
      _updatePostEverywhere(synced);

      if (newValue) {
        final exists = _savedPosts.any((p) => p.postId == postId);
        if (!exists) {
          _savedPosts.insert(0, synced);
        }
      } else {
        _savedPosts.removeWhere((p) => p.postId == postId);
      }
    } catch (e) {
      debugPrint('Toggle save error: $e');
      _updatePostEverywhere(post);
      rethrow;
    } finally {
      _savingPosts.remove(postId);
      notifyListeners();
    }
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
      rethrow;
    } finally {
      _progressTimer?.cancel();

      uploadProgress = 1;
      statusMessage =
      success ? 'Đã gửi! Bài đang chờ duyệt...' : 'Đăng bài thất bại';
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 600));

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
  }

  Future<void> updatePost({
    required int postId,
    String? title,
    String? content,
  }) async {
    await _postService.updatePost(
      postId: postId,
      title: title,
      content: content,
    );

    await fetchMyPosts();

    final myPost = getMyPostOrNull(postId);
    if (myPost != null) {
      final existing = getPostOrNull(postId);
      if (existing != null) {
        final updated = existing.copyWith(
          title: title ?? existing.title,
          content: content ?? existing.content,
        );
        _updatePostEverywhere(updated);
      }
    }

    notifyListeners();
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

  void replaceOrInsertTop(PostFeedModel post) {
    final index = _posts.indexWhere((p) => p.postId == post.postId);
    if (index >= 0) {
      _posts[index] = post;
    } else {
      _posts.insert(0, post);
      _postIds.add(post.postId);
    }
    notifyListeners();
  }

  void removePost(int postId) {
    _posts.removeWhere((p) => p.postId == postId);
    _savedPosts.removeWhere((p) => p.postId == postId);
    _myPosts.removeWhere((p) => p.postId == postId);
    _postIds.remove(postId);
    notifyListeners();
  }

  void _updatePostEverywhere(PostFeedModel updated) {
    final feedIndex = _posts.indexWhere((p) => p.postId == updated.postId);
    if (feedIndex != -1) {
      _posts[feedIndex] = updated;
    }

    final savedIndex = _savedPosts.indexWhere((p) => p.postId == updated.postId);
    if (savedIndex != -1) {
      _savedPosts[savedIndex] = updated;
    }
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

  Future<void> fetchFeed({bool refresh = false, int pageSize = 10}) async {
    if (isLoading || isLoadingMore) return;

    if (refresh) {
      _cursor = null;
      hasMore = true;
      _posts.clear();
      _postIds.clear();
    }

    if (!hasMore) return;

    if (_posts.isEmpty) {
      isLoading = true;
    } else {
      isLoadingMore = true;
    }
    notifyListeners();

    try {
      final items = await _postService.fetchFeed(
        cursor: _cursor,
        pageSize: pageSize,
      );

      if (refresh) {
        _posts.clear();
        _postIds.clear();
      }

      for (final post in items) {
        if (_postIds.add(post.postId)) {
          _posts.add(post);
        }
      }

      if (items.isNotEmpty) {
        _cursor = items.last.createdAt;
      }

      hasMore = items.length >= pageSize;
    } catch (e) {
      debugPrint('Fetch feed error: $e');
      rethrow;
    } finally {
      isLoading = false;
      isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> fetchInitialFeed() async {
    await fetchFeed(refresh: true);
  }

  Future<void> loadMore() async {
    if (!hasMore || isLoading || isLoadingMore) return;
    await fetchFeed();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }
}