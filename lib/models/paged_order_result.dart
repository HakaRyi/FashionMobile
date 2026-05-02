import 'order_model.dart';

class PagedOrderResult {
  final List<OrderModel> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final bool hasMore;

  PagedOrderResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.hasMore,
  });

  factory PagedOrderResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];

    return PagedOrderResult(
      items: rawItems is List
          ? rawItems
          .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
          .toList()
          : [],
      page: json['page'] is int ? json['page'] : 1,
      pageSize: json['pageSize'] is int ? json['pageSize'] : 10,
      totalCount: json['totalCount'] is int ? json['totalCount'] : 0,
      hasMore: json['hasMore'] == true,
    );
  }
}