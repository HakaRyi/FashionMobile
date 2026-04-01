// lib/models/paged_posts_response.dart
import 'post_feed_model.dart';

class PagedPostsResponse {
  final List<PostFeedModel> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final bool hasMore;

  PagedPostsResponse({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.hasMore,
  });

  factory PagedPostsResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List?) ?? const [];

    return PagedPostsResponse(
      items: rawItems.map((e) => PostFeedModel.fromJson(e)).toList(),
      page: json['page'] ?? 1,
      pageSize: json['pageSize'] ?? 10,
      totalCount: json['totalCount'] ?? 0,
      hasMore: json['hasMore'] ?? false,
    );
  }
}