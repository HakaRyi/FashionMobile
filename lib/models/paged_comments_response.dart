// lib/models/paged_comments_response.dart
import 'comment_model.dart';

class PagedCommentsResponse {
  final List<CommentModel> items;
  final int totalCount;
  final int skip;
  final int take;
  final bool hasMore;

  const PagedCommentsResponse({
    required this.items,
    required this.totalCount,
    required this.skip,
    required this.take,
    required this.hasMore,
  });

  factory PagedCommentsResponse.fromJson(Map<String, dynamic> json) {
    return PagedCommentsResponse(
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((e) => CommentModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      totalCount: json['totalCount'] ?? 0,
      skip: json['skip'] ?? 0,
      take: json['take'] ?? 20,
      hasMore: json['hasMore'] ?? false,
    );
  }
}