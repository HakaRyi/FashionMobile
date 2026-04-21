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
    ];

    return Row(
      children: ranges.map((r) {
        bool isSelected = selectedRanges.contains(r['id']);

        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(r['id']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 5),
              padding: const EdgeInsets.symmetric(vertical: 16), // Tăng padding dọc cho thoáng
              decoration: BoxDecoration(
                color: isSelected ? AppColors.textPink : AppColors.surface,
                borderRadius: BorderRadius.circular(16), // Bo tròn hơn xíu nhìn hiện đại

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
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}