import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../models/try_on_source_item.dart';
import '../screens/ai_suggestion_screen.dart';
import '../screens/try_on_screen.dart';
import '../services/item_service.dart';
class ClothingItem extends StatelessWidget {
  final dynamic itemData; // Chuyển sang nhận toàn bộ object itemData
  final VoidCallback? onTap;

  // Custom Action (Truyền vào Icon, Tên nút, Màu sắc và Hành động thực thi)
  final IconData? customActionIcon;
  final String? customActionLabel;
  final Color? customActionColor;
  final VoidCallback? onCustomAction;

  const ClothingItem({
    super.key,
    required this.itemData,
    this.onTap,
    this.customActionIcon,
    this.customActionLabel,
    this.customActionColor = Colors.redAccent,
    this.onCustomAction,
  });

  String get _title => itemData['itemName'] ?? "Unnamed Item";
  String? get _imageUrl => itemData['primaryImageUrl'] ?? itemData['imageUrl'];
  int get _itemId => itemData['itemId'] ?? 0;

  Future<void> _addItemToExistingCollection(BuildContext context, int collectionId) async {
    try {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.white)));
      await ItemService().addItemsToCollection(collectionId, [_itemId]);

      if (context.mounted) {
        Navigator.pop(context); // Tắt loading
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Added to collection successfully!", style: TextStyle(color: Colors.white)), backgroundColor: Colors.black));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to add: $e"), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _createNewCollectionAndAdd(BuildContext context, String title, String desc) async {
    try {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.white)));
      final finalTitle = title.trim().isEmpty ? "My Collection" : title.trim();

      // Tạo mới và add item vào luôn
      await ItemService().saveCollection(finalTitle, desc.trim(), [_itemId]);

      if (context.mounted) {
        Navigator.pop(context); // Tắt loading
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Collection created & item added!", style: TextStyle(color: Colors.white)), backgroundColor: Colors.black));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to create: $e"), backgroundColor: Colors.red));
      }
    }
  }

  void _showCreateCollectionDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("New Collection", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(hintText: "Enter title", hintStyle: TextStyle(color: Colors.black54), border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              maxLines: 2,
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(hintText: "Enter description (Optional)", hintStyle: TextStyle(color: Colors.black54), border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              Navigator.pop(ctx);
              _createNewCollectionAndAdd(context, titleController.text, descController.text);
            },
            child: const Text("Create & Add", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddToCollectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              const Text("Add to Collection", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 16),

              // Nút tạo mới Collection
              ListTile(
                leading: const Icon(Icons.add_box_outlined, color: Colors.black),
                title: const Text("Create New Collection", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                onTap: () {
                  Navigator.pop(ctx); // Đóng bottom sheet
                  _showCreateCollectionDialog(context); // Mở dialog nhập tên
                },
              ),
              const Divider(),

              // Danh sách Collection cũ
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
                child: FutureBuilder<List<dynamic>>(
                  future: ItemService().getCollections(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(color: Colors.black)));
                    }
                    final collections = snapshot.data ?? [];
                    if (collections.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: Text("You don't have any collections yet.", style: TextStyle(color: Colors.black54))),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: collections.length,
                      itemBuilder: (context, index) {
                        final col = collections[index];
                        final colId = col['collectionId'] ?? 0;
                        final items = col['items'] as List<dynamic>? ?? [];

                        // KIỂM TRA XEM ITEM ĐÃ CÓ TRONG COLLECTION CHƯA
                        bool isAlreadyAdded = items.any((i) => (i['itemId'] ?? 0) == _itemId);

                        return ListTile(
                          leading: Container(
                            width: 45, height: 45,
                            decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(8)),
                            child: items.isNotEmpty && items[0]['primaryImageUrl'] != null
                                ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(items[0]['primaryImageUrl'], fit: BoxFit.cover))
                                : const Icon(Icons.collections, color: Colors.black26),
                          ),
                          title: Text(col['title'] ?? 'Untitled', style: TextStyle(color: isAlreadyAdded ? Colors.black38 : Colors.black, fontWeight: FontWeight.w700)),
                          subtitle: Text("${items.length} Items", style: TextStyle(color: isAlreadyAdded ? Colors.black26 : Colors.black54, fontSize: 12)),
                          trailing: isAlreadyAdded
                              ? const Icon(Icons.check_circle, color: Colors.green) // Có rồi thì hiện tick xanh
                              : const Icon(Icons.add_circle_outline, color: Colors.black26), // Chưa có thì cho nút add

                          // Vô hiệu hóa nút bấm nếu đã có đồ rồi
                          onTap: isAlreadyAdded ? null : () {
                            Navigator.pop(ctx);
                            _addItemToExistingCollection(context, colId);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // HÀM HIỂN THỊ MENU CHUNG
  void _showUniversalActionMenu(BuildContext context) {
    HapticFeedback.mediumImpact(); // Rung nhẹ khi hiện menu
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 10),

            Text(_title, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.black)),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.collections_bookmark_outlined, color: Colors.black),
              title: const Text("Add to Collection", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
              onTap: () {
                Navigator.pop(ctx); // Tắt menu chính
                _showAddToCollectionSheet(context); // Mở menu Collection lên
              },
            ),
            // 1. Tính năng chung: Gợi ý đồ (AI Suggestion)
            ListTile(
              leading: const Icon(Icons.auto_awesome, color: Colors.black),
              title: const Text("AI Outfit Suggestion", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
              onTap: () {
                Navigator.pop(ctx); // Đóng menu
                Navigator.push(context, MaterialPageRoute(builder: (_) => AISuggestionScreen(selectedItem: itemData)));
              },
            ),

            // 2. Tính năng chung: Thử đồ (Try-On)
            ListTile(
              leading: const Icon(Icons.face, color: Colors.black),
              title: const Text("Virtual Try-on", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TryOnScreen(
                      sourceItem: TryOnSourceItem(
                        itemId: _itemId,
                        itemName: _title,
                        imageUrl: _imageUrl ?? '',
                        brand: itemData['brand'],
                        category: itemData['category'],
                      ),
                    ),
                  ),
                );
              },
            ),

            // 3. TÍNH NĂNG TÙY BIẾN (Delete, Unsave...) - Chỉ hiện nếu được truyền vào
            if (customActionLabel != null && onCustomAction != null)
              ListTile(
                leading: Icon(customActionIcon ?? Icons.delete_outline, color: customActionColor),
                title: Text(customActionLabel?? '', style: TextStyle(color: customActionColor, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  onCustomAction?.call();
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showUniversalActionMenu(context), // GỌI MENU MỚI TẠI ĐÂY
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(8),
                child: (_imageUrl != null && _imageUrl!.startsWith('http'))
                    ? Image.network(
                  _imageUrl!,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                )
                    : const Icon(Icons.checkroom, color: Colors.black26, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}