// lib/managers/comment_manager.dart
import 'package:flutter/material.dart';

import '../models/comment_model.dart';
import '../models/comment_reply_model.dart';
import '../models/comment_reaction_result.dart';
import '../models/comment_replies_response.dart';
import '../models/create_reply_result.dart';
import '../models/paged_comments_response.dart';
import '../services/comment_service.dart';
import '../services/reaction_service.dart';

class CommentManager extends ChangeNotifier {
  final CommentService _commentService = CommentService();
  final ReactionService _reactionService = ReactionService();

  /// external post cache
  final List<Map<String, dynamic>> posts = [];

  final List<CommentModel> _comments = [];
  List<CommentModel> get comments => List.unmodifiable(_comments);

  final Set<int> _expandedReplyCommentIds = {};
  final Set<int> _loadingReplyCommentIds = {};
  final Set<int> _submittingReplyCommentIds = {};
  final Set<int> _likingCommentIds = {};

  bool loading = false;
  bool loadingMore = false;
  bool isSubmittingComment = false;

  bool get isInitialLoading => loading;
  bool get isLoadingMore => loadingMore;

  int postId = 0;
  final int pageSize = 20;
  bool hasMore = true;

  /// cache paging replies theo từng comment
  final Map<int, bool> _hasMoreRepliesMap = {};
  final Map<int, int> _loadedReplyCountMap = {};

  /// ========= UI HELPERS =========

  bool isRepliesExpanded(int commentId) {
    return _expandedReplyCommentIds.contains(commentId);
  }

  bool isLoadingReplies(int commentId) {
    return _loadingReplyCommentIds.contains(commentId);
  }

  bool isSubmittingReply(int commentId) {
    return _submittingReplyCommentIds.contains(commentId);
  }

  bool isLikingComment(int commentId) {
    return _likingCommentIds.contains(commentId);
  }

  bool hasRepliesFor(int commentId) {
    final comment = _comments.cast<CommentModel?>().firstWhere(
          (e) => e?.commentId == commentId,
      orElse: () => null,
    );

    return comment?.hasReplies ?? false;
  }

  bool hasMoreRepliesFor(int commentId) {
    return _hasMoreRepliesMap[commentId] ?? false;
  }

  Map<String, dynamic> getPost(int postId) {
    return posts.firstWhere(
          (e) => e['postId'].toString() == postId.toString(),
      orElse: () => <String, dynamic>{},
    );
  }

  /// ========= CURRENT USER HELPERS =========
  /// Tạm lấy mềm để tránh hardcode "You"
  String _currentUserName() {
    for (final post in posts) {
      final value = post['userName'];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return 'User';
  }

  String? _currentAvatarUrl() {
    for (final post in posts) {
      final value = post['avatarUrl'];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  /// ========= LOAD COMMENTS =========

  Future<void> loadComments(int postId) async {
    this.postId = postId;
    hasMore = true;

    _comments.clear();
    _expandedReplyCommentIds.clear();
    _loadingReplyCommentIds.clear();
    _submittingReplyCommentIds.clear();
    _likingCommentIds.clear();
    _hasMoreRepliesMap.clear();
    _loadedReplyCountMap.clear();

    loading = true;
    notifyListeners();

    try {
      final PagedCommentsResponse result = await _commentService.getComments(
        postId,
        skip: 0,
        take: pageSize,
      );

      _comments
        ..clear()
        ..addAll(_rankComments(result.items));

      hasMore = result.hasMore;

      for (final c in _comments) {
        _loadedReplyCountMap[c.commentId] = c.replies.length;
        _hasMoreRepliesMap[c.commentId] = c.replies.length < c.replyCount;
      }
    } catch (e) {
      debugPrint("loadComments error $e");
    }

    loading = false;
    notifyListeners();
  }

  Future<void> refresh(int postId) async {
    await loadComments(postId);
  }

  /// ========= LOAD MORE ROOT COMMENTS =========

  Future<void> loadMore() async {
    if (!hasMore || loadingMore || postId == 0) return;

    loadingMore = true;
    notifyListeners();

    try {
      final result = await _commentService.getComments(
        postId,
        skip: _comments.length,
        take: pageSize,
      );

      final ranked = _rankComments(result.items);

      for (final c in ranked) {
        if (!_comments.any((e) => e.commentId == c.commentId)) {
          _comments.add(c);
          _loadedReplyCountMap[c.commentId] = c.replies.length;
          _hasMoreRepliesMap[c.commentId] = c.replies.length < c.replyCount;
        }
      }

      hasMore = result.hasMore;
    } catch (e) {
      debugPrint("loadMore error $e");
    }

    loadingMore = false;
    notifyListeners();
  }

  /// ========= COMMENT RANKING =========
  /// Dùng replyCount từ BE, không dùng replies.length

  List<CommentModel> _rankComments(List<CommentModel> list) {
    final ranked = List<CommentModel>.from(list);

    ranked.sort((a, b) {
      final scoreA = a.likeCount * 2 + a.replyCount + _recencyScore(a.createdAt);
      final scoreB = b.likeCount * 2 + b.replyCount + _recencyScore(b.createdAt);

      return scoreB.compareTo(scoreA);
    });

    return ranked;
  }

  int _recencyScore(DateTime time) {
    final diff = DateTime.now().difference(time).inMinutes;

    if (diff < 60) return 5;
    if (diff < 360) return 3;
    if (diff < 1440) return 1;

    return 0;
  }

  /// ========= CREATE COMMENT =========

  Future<void> createComment(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || isSubmittingComment || postId == 0) return;

    isSubmittingComment = true;

    final fake = CommentModel(
      commentId: -DateTime.now().millisecondsSinceEpoch,
      postId: postId,
      accountId: 0,
      userName: _currentUserName(),
      avatarUrl: _currentAvatarUrl(),
      content: trimmed,
      likeCount: 0,
      isLiked: false,
      createdAt: DateTime.now(),
      parentCommentId: null,
      replyCount: 0,
      hasReplies: false,
      replies: const [],
    );

    _comments.insert(0, fake);
    _increasePostCommentCountOptimistic();
    notifyListeners();

    try {
      final result = await _commentService.createComment(
        postId: postId,
        content: trimmed,
      );

      final index = _comments.indexWhere((e) => e.commentId == fake.commentId);
      if (index != -1) {
        _comments[index] = result;
        _loadedReplyCountMap[result.commentId] = result.replies.length;
        _hasMoreRepliesMap[result.commentId] = result.replies.length < result.replyCount;
      }
    } catch (_) {
      _comments.removeWhere((e) => e.commentId == fake.commentId);
      _decreasePostCommentCountOptimistic();
    }

    isSubmittingComment = false;
    notifyListeners();
  }

  void _increasePostCommentCountOptimistic() {
    final index = posts.indexWhere(
          (e) => e['postId'].toString() == postId.toString(),
    );

    if (index == -1) return;

    final current = posts[index]['commentCount'] ?? 0;
    posts[index]['commentCount'] = current + 1;
  }

  void _decreasePostCommentCountOptimistic() {
    final index = posts.indexWhere(
          (e) => e['postId'].toString() == postId.toString(),
    );

    if (index == -1) return;

    final current = posts[index]['commentCount'] ?? 0;
    posts[index]['commentCount'] = current > 0 ? current - 1 : 0;
  }

  /// ========= LIKE ROOT COMMENT =========

  Future<void> toggleLike(CommentModel comment) async {
    final commentId = comment.commentId;
    if (_likingCommentIds.contains(commentId)) return;

    final index = _comments.indexWhere((e) => e.commentId == commentId);
    if (index == -1) return;

    _likingCommentIds.add(commentId);

    final current = _comments[index];
    final optimistic = current.copyWith(
      isLiked: !current.isLiked,
      likeCount: current.isLiked
          ? (current.likeCount > 0 ? current.likeCount - 1 : 0)
          : current.likeCount + 1,
    );

    _comments[index] = optimistic;
    notifyListeners();

    try {
      final CommentReactionResult result =
      await _reactionService.toggleCommentLike(commentId);

      final latestIndex = _comments.indexWhere((e) => e.commentId == commentId);
      if (latestIndex != -1) {
        final latest = _comments[latestIndex];
        _comments[latestIndex] = latest.copyWith(
          isLiked: result.isLiked,
          likeCount: result.likeCount,
        );
      }
    } catch (_) {
      final latestIndex = _comments.indexWhere((e) => e.commentId == commentId);
      if (latestIndex != -1) {
        _comments[latestIndex] = current;
      }
    }

    _likingCommentIds.remove(commentId);
    notifyListeners();
  }

  /// ========= LOAD REPLIES =========

  Future<void> loadReplies(
      CommentModel comment, {
        bool forceRefresh = false,
      }) async {
    final commentId = comment.commentId;

    if (_loadingReplyCommentIds.contains(commentId)) return;

    final currentIndex = _comments.indexWhere((e) => e.commentId == commentId);
    if (currentIndex == -1) return;

    final current = _comments[currentIndex];
    final alreadyLoaded = current.replies.length;
    final shouldSkip =
        !forceRefresh && alreadyLoaded > 0 && !(_hasMoreRepliesMap[commentId] ?? false);

    if (shouldSkip) return;

    _loadingReplyCommentIds.add(commentId);
    notifyListeners();

    try {
      final CommentRepliesResponse response = await _commentService.getReplies(
        commentId,
        skip: forceRefresh ? 0 : alreadyLoaded,
        take: pageSize,
      );

      final latestIndex = _comments.indexWhere((e) => e.commentId == commentId);
      if (latestIndex != -1) {
        final latest = _comments[latestIndex];

        final mergedReplies = forceRefresh
            ? response.items
            : [...latest.replies, ...response.items.where(
              (r) => !latest.replies.any((x) => x.commentId == r.commentId),
        )];

        _comments[latestIndex] = latest.copyWith(
          replies: mergedReplies,
          replyCount: response.replyCount,
          hasReplies: response.hasReplies,
        );

        _loadedReplyCountMap[commentId] = mergedReplies.length;
        _hasMoreRepliesMap[commentId] = response.hasMore;
      }
    } catch (e) {
      debugPrint("loadReplies error $e");
    }

    _loadingReplyCommentIds.remove(commentId);
    notifyListeners();
  }

  Future<void> loadMoreReplies(CommentModel comment) async {
    await loadReplies(comment);
  }

  /// ========= TOGGLE REPLIES =========

  Future<void> toggleReplies(CommentModel comment) async {
    final commentId = comment.commentId;

    if (_expandedReplyCommentIds.contains(commentId)) {
      _expandedReplyCommentIds.remove(commentId);
      notifyListeners();
      return;
    }

    _expandedReplyCommentIds.add(commentId);
    notifyListeners();

    final latestIndex = _comments.indexWhere((e) => e.commentId == commentId);
    if (latestIndex == -1) return;

    final latest = _comments[latestIndex];
    if (latest.replies.isEmpty && latest.hasReplies) {
      await loadReplies(latest);
    }
  }

  /// ========= CREATE REPLY =========

  Future<void> createReply(CommentModel comment, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final commentId = comment.commentId;
    if (_submittingReplyCommentIds.contains(commentId)) return;

    final index = _comments.indexWhere((e) => e.commentId == commentId);
    if (index == -1) return;

    _submittingReplyCommentIds.add(commentId);

    final current = _comments[index];
    final fake = CommentReplyModel(
      commentId: -DateTime.now().millisecondsSinceEpoch,
      accountId: 0,
      userName: _currentUserName(),
      avatarUrl: _currentAvatarUrl(),
      content: trimmed,
      likeCount: 0,
      isLiked: false,
      createdAt: DateTime.now(),
      parentCommentId: current.commentId,
    );

    final optimisticReplies = [...current.replies, fake];

    _comments[index] = current.copyWith(
      replies: optimisticReplies,
      replyCount: current.replyCount + 1,
      hasReplies: true,
    );

    _expandedReplyCommentIds.add(current.commentId);
    _loadedReplyCountMap[current.commentId] = optimisticReplies.length;
    _hasMoreRepliesMap[current.commentId] = false;
    _increasePostCommentCountOptimistic();
    notifyListeners();

    try {
      final CreateReplyResult result = await _commentService.replyComment(
        current.commentId,
        trimmed,
      );

      final currentIndex = _comments.indexWhere((e) => e.commentId == current.commentId);

      if (currentIndex != -1) {
        final latest = _comments[currentIndex];
        final replies = [...latest.replies];
        final fakeIndex = replies.indexWhere((e) => e.commentId == fake.commentId);

        if (fakeIndex != -1) {
          replies[fakeIndex] = result.reply;
        } else {
          replies.add(result.reply);
        }

        _comments[currentIndex] = latest.copyWith(
          replies: replies,
          replyCount: result.replyCount,
          hasReplies: result.hasReplies,
        );

        _loadedReplyCountMap[current.commentId] = replies.length;
        _hasMoreRepliesMap[current.commentId] = replies.length < result.replyCount;
      }
    } catch (_) {
      final currentIndex = _comments.indexWhere((e) => e.commentId == current.commentId);

      if (currentIndex != -1) {
        final latest = _comments[currentIndex];
        final replies = [...latest.replies]
          ..removeWhere((e) => e.commentId == fake.commentId);

        final newReplyCount = latest.replyCount > 0 ? latest.replyCount - 1 : 0;

        _comments[currentIndex] = latest.copyWith(
          replies: replies,
          replyCount: newReplyCount,
          hasReplies: newReplyCount > 0,
        );

        _loadedReplyCountMap[current.commentId] = replies.length;
        _hasMoreRepliesMap[current.commentId] = replies.length < newReplyCount;
      }

      _decreasePostCommentCountOptimistic();
    }

    _submittingReplyCommentIds.remove(commentId);
    notifyListeners();
  }

  /// ========= REALTIME COMMENT UPDATE =========

  void onRealtimeComment(CommentModel comment) {
    if (_comments.any((e) => e.commentId == comment.commentId)) return;

    _comments.insert(0, comment);
    _loadedReplyCountMap[comment.commentId] = comment.replies.length;
    _hasMoreRepliesMap[comment.commentId] = comment.replies.length < comment.replyCount;

    notifyListeners();
  }

  /// ========= REALTIME ROOT LIKE UPDATE =========

  void onRealtimeLike(int commentId, int likeCount) {
    final index = _comments.indexWhere((e) => e.commentId == commentId);
    if (index == -1) return;

    final c = _comments[index];
    _comments[index] = c.copyWith(likeCount: likeCount);
    notifyListeners();
  }

  /// ========= OPTIONAL: update parent from replies response =========

  void syncParentReplyMeta({
    required int parentCommentId,
    required int replyCount,
    required bool hasReplies,
  }) {
    final index = _comments.indexWhere((e) => e.commentId == parentCommentId);
    if (index == -1) return;

    final current = _comments[index];
    _comments[index] = current.copyWith(
      replyCount: replyCount,
      hasReplies: hasReplies,
    );

    _hasMoreRepliesMap[parentCommentId] = current.replies.length < replyCount;
    notifyListeners();
  }
}