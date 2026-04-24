import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../models/try_on_source_item.dart';
import '../screens/ai_suggestion_screen.dart';
import '../screens/try_on_screen.dart';

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

  // HÀM HIỂN THỊ MENU CHUNG
  void _showUniversalActionMenu(BuildContext context) {
    HapticFeedback.mediumImpact(); // Rung nhẹ khi hiện menu
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 10),

            // Hiện tên đồ để user biết đang thao tác với cái nào
            Text(_title, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.black)),
            const SizedBox(height: 10),

            // 1. Tính năng chung: Gợi ý đồ (AI Suggestion)
            ListTile(
              leading: const Icon(Icons.auto_awesome, color: Colors.black),
              title: const Text("AI Outfit Suggestion", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
              onTap: () {
                Navigator.pop(context); // Đóng menu
                Navigator.push(context, MaterialPageRoute(builder: (_) => AISuggestionScreen(selectedItem: itemData)));
              },
            ),

            // 2. Tính năng chung: Thử đồ (Try-On)
            ListTile(
              leading: const Icon(Icons.face, color: Colors.black),
              title: const Text("Virtual Try-on", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
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
                title: Text(customActionLabel!, style: TextStyle(color: customActionColor, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  onCustomAction!(); // Thực thi lệnh truyền từ bên ngoài
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