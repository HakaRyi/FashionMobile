import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AIRangeSelector extends StatelessWidget {
  final List<String> selectedRanges;
  final Function(String) onSelect;

  const AIRangeSelector({
    super.key,
    required this.selectedRanges,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> ranges = [
      {'id': 'My Wardrobe', 'label': 'My Wardrobe', 'icon': Icons.inventory_2_outlined},
      {'id': 'Others', 'label': 'Others', 'icon': Icons.people_outline},
      {'id': 'Saved', 'label': 'My Saved', 'icon': Icons.bookmark_border},
      {'id': 'StylePrefs', 'label': 'My Style', 'icon': Icons.auto_awesome_mosaic_outlined},
      {'id': 'PhysicalProfile', 'label': 'My Body', 'icon': Icons.accessibility_new_outlined},
    ];

    // THAY THẾ TOÀN BỘ TỪ return Row(...) THÀNH return Wrap(...)
    return Wrap(
      spacing: 10, // Khoảng cách ngang giữa các nút
      runSpacing: 12, // Khoảng cách dọc giữa các hàng
      children: ranges.map((r) {
        bool isSelected = selectedRanges.contains(r['id']);
        // Tính toán độ rộng để xếp vừa 3 nút 1 hàng
        double itemWidth = (MediaQuery.of(context).size.width - 48 - 20) / 3;

        // ĐÃ XÓA THẺ Expanded Ở ĐÂY
        return GestureDetector(
          onTap: () => onSelect(r['id']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: itemWidth, // ÁP DỤNG ĐỘ RỘNG ĐÃ TÍNH VÀO ĐÂY
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.textPink : AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withOpacity(0.1)),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: AppColors.textPink.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                )
              ] : [],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  r['icon'],
                  color: isSelected ? Colors.white : Colors.black,
                  size: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  r['label'],
                  textAlign: TextAlign.center,
                  maxLines: 1, // Ép chữ trên 1 dòng
                  overflow: TextOverflow.ellipsis, // Nếu dài quá thì hiện dấu 3 chấm
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}