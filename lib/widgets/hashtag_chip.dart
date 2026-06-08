import 'package:flutter/material.dart';

class HashtagChip extends StatelessWidget {
  final String tag;
  final VoidCallback onTap;
  final bool isActive;

  const HashtagChip({
    super.key,
    required this.tag,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = isActive ? const Color(0xFF1A1A1A) : const Color(0xFF4A90E2);
    final backgroundColor = isActive
        ? const Color(0xFF1A1A1A)
        : const Color(0xFFF4F6F9);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(right: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isActive ? Colors.transparent : const Color(0xE0E0E0FF).withOpacity(0.3),
          width: 0.8,
        ),
        boxShadow: isActive ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          splashColor: primaryColor.withOpacity(0.1),
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '#',
                  style: TextStyle(
                    color: isActive ? Colors.white70 : primaryColor.withOpacity(0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  tag,
                  style: TextStyle(
                    color: isActive ? Colors.white : const Color(0xFF2C3E50),
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}