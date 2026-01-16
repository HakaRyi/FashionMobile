import 'package:flutter/material.dart';

class PriceInfoWidget extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color? valueTextColor;

  const PriceInfoWidget({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.valueTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Icon(Icons.stars, color: color, size: 20),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: valueTextColor ?? (color == Colors.grey ? Colors.grey : Colors.white),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ],
    );
  }
}