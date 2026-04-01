// lib/models/try_on_source_item.dart
class TryOnSourceItem {
  final int itemId;
  final String? itemName;
  final String? imageUrl;
  final String? category;
  final String? brand;

  const TryOnSourceItem({
    required this.itemId,
    this.itemName,
    this.imageUrl,
    this.category,
    this.brand,
  });
}