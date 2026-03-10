import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AIAttributeSelector extends StatelessWidget {
  final String title;
  final List<dynamic> options;
  final String selectedValue;
  final Function(String) onSelected;

  const AIAttributeSelector({
    super.key,
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(),
            style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: options.map((opt) {
            bool isSelected = selectedValue == opt.label;
            return ChoiceChip(
              label: Text("${opt.label} (${opt.confidence.toInt()}%)"),
              selected: isSelected,
              onSelected: (_) => onSelected(opt.label),
              selectedColor: Colors.pinkAccent,
              backgroundColor: AppColors.surface,
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}