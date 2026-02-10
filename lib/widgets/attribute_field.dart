import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AttributeField extends StatelessWidget {
  final String label;
  final String initialValue;
  final IconData icon;

  const AttributeField({
    super.key,
    required this.label,
    required this.initialValue,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 5),
          TextFormField(
            initialValue: initialValue,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.textPink, size: 20),
              filled: true,
              fillColor: AppColors.surface,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.textPink),
              ),
            ),
          ),
        ],
      ),
    );
  }
}