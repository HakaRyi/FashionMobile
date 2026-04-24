import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../constants/post_status_values.dart';
import '../models/paged_posts_response.dart';
import '../models/post_feed_model.dart';
import '../models/post_reaction_result.dart';
import '../models/shareable_user_model.dart';
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
  final List<ShareableUserModel> _shareableUsers = [];

  List<ShareableUserModel> get shareableUsers =>
      List.unmodifiable(_shareableUsers);

  List<PostFeedModel> get posts => List.unmodifiable(_posts);

  bool isLoadingShareableUsers = false;

  final Set<int> _sharingPostsToChat = {};

  DateTime? _cursor;
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMore = true;

  int _savedPage = 1;
  bool hasMoreSaved = true;
  bool isLoadingMoreSaved = false;

  final List<PostFeedModel> _savedPosts = [];
  List<PostFeedModel> get savedPosts => List.unmodifiable(_savedPosts);
  bool isLoadingSaved = false;

  final List<PostFeedModel> _myPosts = [];
  List<PostFeedModel> get myPosts => List.unmodifiable(_myPosts);
  bool isLoadingMyPosts = false;

  bool isUploading = false;
  double uploadProgress = 0;
  String statusMessage = '';

  Timer? _progressTimer;

  final Set<int> _likingPosts = {};
  final Set<int> _savingPosts = {};

  int getShareCount(int postId) {
    final post = _findPostAnywhere(postId);
    return post?.shareCount ?? 0;
  }

  PostFeedModel? _findPostAnywhere(int postId) {
    try {
      return _posts.firstWhere((p) => p.postId == postId);
    } catch (_) {}

    try {
      return _savedPosts.firstWhere((p) => p.postId == postId);
    } catch (_) {}

    try {
      return _myPosts.firstWhere((p) => p.postId == postId);
    } catch (_) {}

    return null;
  }

  PostFeedModel? getPostOrNull(int postId) {
    try {
      return _posts.firstWhere((p) => p.postId == postId);
    } catch (_) {
      return null;
    }
  }

  PostFeedModel? getPostAnywhereOrNull(int postId) {
    return _findPostAnywhere(postId);
  }

  PostFeedModel? getMyPostOrNull(int postId) {
    try {
      return _myPosts.firstWhere((p) => p.postId == postId);
    } catch (_) {
      return null;
    }
  }

  bool isPostLiked(int postId) {
    final post = _findPostAnywhere(postId);
    return post?.isLiked ?? false;
  }

  bool isPostSaved(int postId) {
    final post = _findPostAnywhere(postId);
    return post?.isSaved ?? false;
  }

  int getLikeCount(int postId) {
    final post = _findPostAnywhere(postId);
    return post?.likeCount ?? 0;
  }

  int getCommentCount(int postId) {
    final post = _findPostAnywhere(postId);
    return post?.commentCount ?? 0;
  }

  String getMyPostStatusText(String? status) {
    switch (status) {
      case PostStatusValues.draft:
        return 'Draft';
      case PostStatusValues.verifying:
        return 'Reviewing';
      case PostStatusValues.pendingAdmin:
        return 'Pending Admin Review';
      case PostStatusValues.published:
        return 'Published';
      case PostStatusValues.rejected:
        return 'Rejected';
      default:
        return status ?? 'Unknown';
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
    if (isLoadingSaved || isLoadingMoreSaved) {
      return;
    }

    if (refresh) {
      isLoadingSaved = true;
      _savedPage = 1;
      hasMoreSaved = true;
    } else {
      if (!hasMoreSaved) {
        return;
      }

      isLoadingMoreSaved = true;
    }

    notifyListeners();

    try {
      final PagedPostsResponse result = await _postService.fetchSavedPosts(
        page: refresh ? 1 : page,
        pageSize: pageSize,
      );

      if (refresh) {
        _savedPosts
          ..clear()
          ..addAll(result.items);
      } else {
        for (final item in result.items) {
          final exists = _savedPosts.any((p) => p.postId == item.postId);
          if (!exists) {
            _savedPosts.add(item);
          }
        }
      }

      _savedPage = result.page;
      hasMoreSaved = result.hasMore;
    } catch (e) {
      debugPrint('Fetch saved posts error: $e');
      rethrow;
    } finally {
      isLoadingSaved = false;
      isLoadingMoreSaved = false;
      notifyListeners();
    }
  }

  Future<void> sharePostToChat({
    required PostFeedModel post,
    required List<int> receiverAccountIds,
    String? caption,
  }) async {
    if (_sharingPostsToChat.contains(post.postId)) {
      return;
    }

    final validReceiverIds = receiverAccountIds
        .where((id) => id > 0)
        .toSet()
        .toList();

    if (validReceiverIds.isEmpty) {
      throw Exception('Please select at least one receiver.');
    }

    _sharingPostsToChat.add(post.postId);

    try {
      final currentPost = _findPostAnywhere(post.postId) ?? post;

      await _postService.sharePostToChat(
        postId: currentPost.postId,
        receiverAccountIds: validReceiverIds,
        caption: caption,
      );

      final updated = currentPost.copyWith(
        shareCount: currentPost.shareCount + validReceiverIds.length,
      );

      _updatePostEverywhere(updated);
      notifyListeners();
    } catch (e) {
      debugPrint('Share post to chat error: $e');
      rethrow;
    } finally {
      _sharingPostsToChat.remove(post.postId);
    }
  }

  Future<void> loadMoreSavedPosts({int pageSize = 10}) async {
    if (isLoadingSaved || isLoadingMoreSaved || !hasMoreSaved) {
      return;
    }

    await fetchSavedPosts(
      refresh: false,
      page: _savedPage + 1,
      pageSize: pageSize,
    );
  }

  Future<void> refreshPostById(int postId) async {
    try {
      final updatedPost = await _postService.getPostDetail(postId);
      _updatePostEverywhere(updatedPost);
      notifyListeners();
    } catch (e) {
      debugPrint('Refresh post by id error: $e');
      rethrow;
    }
  }

  Future<void> fetchMyPosts({
    int page = 1,
    int pageSize = 10,
  }) async {
    if (isLoadingMyPosts) {
      return;
    }

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
    if (_likingPosts.contains(postId)) {
      return;
    }

    _likingPosts.add(postId);

    final post = _findPostAnywhere(postId);
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
    if (_savingPosts.contains(postId)) {
      return;
    }

    _savingPosts.add(postId);

    final post = _findPostAnywhere(postId);
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
    if (index == -1) {
      return;
    }

    final oldPost = _myPosts[index];
    if (oldPost.status != PostStatusValues.published ||
        oldPost.visibility != 'Visible') {
      return;
    }

    try {
      final response = await _postService.hidePost(postId);

      _myPosts[index] = oldPost.copyWith(
        visibility: response['visibility'] ?? oldPost.visibility,
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Hide post error: $e');
      rethrow;
    }
  }

  Future<void> unhideMyPost(int postId) async {
    final index = _myPosts.indexWhere((p) => p.postId == postId);
    if (index == -1) {
      return;
    }

    final oldPost = _myPosts[index];
    if (oldPost.status != PostStatusValues.published ||
        oldPost.visibility != 'Hidden') {
      return;
    }

    try {
      final response = await _postService.unhidePost(postId);

      _myPosts[index] = oldPost.copyWith(
        visibility: response['visibility'] ?? oldPost.visibility,
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
        int? eventId,
      }) async {
    if (isUploading) {
      return;
    }

    isUploading = true;
    uploadProgress = 0;
    statusMessage = 'Uploading...';
    notifyListeners();

    _startFakeProgress();

    bool success = false;

    try {
      int? postId;

      if (eventId != null) {
        postId = await _postService.joinEventWithPost(
          imageBytesList: imageBytesList,
          content: content,
          eventId: eventId,
          title: title,
        );
      } else {
        postId = await _postService.createPost(
          imageBytesList: imageBytesList,
          content: content,
          title: title,
        );
      }

      success = postId != null;
    } catch (e) {
      debugPrint('Upload error: $e');
      rethrow;
    } finally {
      _progressTimer?.cancel();

      uploadProgress = 1;
      statusMessage =
      success ? 'Submitted! Waiting for review...' : 'Post upload failed.';
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
      final existing = _findPostAnywhere(postId);
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
    final post = _findPostAnywhere(postId);
    if (post == null) {
      return;
    }

    final updated = post.copyWith(
      commentCount: post.commentCount + 1,
    );

    _updatePostEverywhere(updated);
    notifyListeners();
  }

  void decreaseCommentCount(int postId) {
    final post = _findPostAnywhere(postId);
    if (post == null) {
      return;
    }

    final updated = post.copyWith(
      commentCount: post.commentCount > 0 ? post.commentCount - 1 : 0,
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
    final post = _findPostAnywhere(postId);
    if (post == null) {
      return;
    }

    final updated = post.copyWith(
      likeCount: likeCount,
      isLiked: isLiked,
    );

    _updatePostEverywhere(updated);
    notifyListeners();
  }

  void replaceOrInsertTop(PostFeedModel post) {
    _posts.removeWhere((p) => p.postId == post.postId);
    _posts.insert(0, post);
    _postIds.add(post.postId);
    notifyListeners();
  }

  void bringPostToTop(PostFeedModel post) {
    _posts.removeWhere((p) => p.postId == post.postId);
    _posts.insert(0, post);
    _postIds.add(post.postId);

    final savedIndex = _savedPosts.indexWhere((p) => p.postId == post.postId);
    if (savedIndex != -1) {
      _savedPosts[savedIndex] = post;
    }

    final myIndex = _myPosts.indexWhere((p) => p.postId == post.postId);
    if (myIndex != -1) {
      _myPosts[myIndex] = post;
    }

    notifyListeners();
  }

  Future<PostFeedModel?> ensurePostAtTop(int postId) async {
    try {
      final existing = _findPostAnywhere(postId);

      if (existing != null) {
        bringPostToTop(existing);
        return existing;
      }

      final fetched = await _postService.getPostDetail(postId);
      bringPostToTop(fetched);
      return fetched;
    } catch (e) {
      debugPrint('Ensure post at top error: $e');
      return null;
    }
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

    final savedIndex =
    _savedPosts.indexWhere((p) => p.postId == updated.postId);
    if (savedIndex != -1) {
      _savedPosts[savedIndex] = updated;
    }

    final myIndex = _myPosts.indexWhere((p) => p.postId == updated.postId);
    if (myIndex != -1) {
      _myPosts[myIndex] = updated;
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
          statusMessage = 'Sending data...';
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
          success
              ? 'Submitted! Your post is waiting for review.'
              : 'Post upload failed.',
        ),
        backgroundColor: success ? Colors.green : Colors.redAccent,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> fetchFeed({
    bool refresh = false,
    int pageSize = 10,
  }) async {
    if (isLoading || isLoadingMore) {
      return;
    }

    if (refresh) {
      _cursor = null;
      hasMore = true;
      _posts.clear();
      _postIds.clear();
    }

    if (!hasMore) {
      return;
    }

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

  Future<void> fetchShareableUsers({bool refresh = false}) async {
    if (isLoadingShareableUsers) {
      return;
    }

    if (!refresh && _shareableUsers.isNotEmpty) {
      return;
    }

    isLoadingShareableUsers = true;
    notifyListeners();

    try {
      final users = await _postService.getShareableUsers();

      _shareableUsers
        ..clear()
        ..addAll(users);
    } catch (e) {
      debugPrint('Fetch shareable users error: $e');
      rethrow;
    } finally {
      isLoadingShareableUsers = false;
      notifyListeners();
    }
  }

  Future<void> fetchInitialFeed() async {
    await fetchFeed(refresh: true);
  }

  Future<void> loadMore() async {
    if (!hasMore || isLoading || isLoadingMore) {
      return;
    }

    await fetchFeed();
  }

  void clearShareableUsers() {
    _shareableUsers.clear();
    notifyListeners();
  }

  ShareableUserModel? getShareableUserById(int accountId) {
    try {
      return _shareableUsers.firstWhere((u) => u.accountId == accountId);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }
}