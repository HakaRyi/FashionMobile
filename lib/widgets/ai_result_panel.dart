import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AIResultPanel extends StatelessWidget {
  final Map<String, dynamic> aiData;
  final Map<String, String> selectedAttributes;
  final Function(String key, String value) onAttributeSelected;

  const AIResultPanel({
    super.key,
    required this.aiData,
    required this.selectedAttributes,
    required this.onAttributeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: aiData.keys.map((key) {
        final List<dynamic> options = aiData[key];
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                key.toUpperCase().replaceAll('_', ' '),
                style: const TextStyle(
                  color: Colors.pinkAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: options.map((opt) {
                  final String label = opt['label'];
                  final double confidence = (opt['confidence'] as num).toDouble();
                  final bool isSelected = selectedAttributes[key] == label;

                  return ChoiceChip(
                    label: Text("$label (${confidence.toInt()}%)"),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) onAttributeSelected(key, label);
                    },
                    selectedColor: Colors.pinkAccent.withOpacity(0.2),
                    backgroundColor: AppColors.surface,
                    checkmarkColor: Colors.pinkAccent,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.pinkAccent : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? Colors.pinkAccent : Colors.white10,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}