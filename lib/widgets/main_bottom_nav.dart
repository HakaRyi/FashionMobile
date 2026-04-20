import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'dart:math' as math;

class MainBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const MainBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 65,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_filled),
          _buildNavItem(1, Icons.search_rounded),
          _buildSummerEventItem(), // Tab đặc biệt
          _buildNavItem(3, Icons.checkroom_rounded),
          _buildNavItem(4, Icons.person_rounded),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    bool isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Icon(
          icon,
          size: 26,
          color: isSelected ? AppColors.textPink : Colors.black26,
        ),
      ),
    );
  }

  Widget _buildSummerEventItem() {
    bool isSelected = currentIndex == 2;
    return GestureDetector(
      onTap: () => onTap(2),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 70,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Hiệu ứng bệ đỡ phía dưới khi được chọn
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              bottom: isSelected ? 10 : -20,
              child: Container(
                width: 35,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.pinkAccent.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(color: Colors.pinkAccent.withOpacity(0.3), blurRadius: 10, spreadRadius: 2)
                    ]
                ),
              ),
            ),
            // Icon chính bay lên
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              margin: EdgeInsets.only(bottom: isSelected ? 35 : 0),
              child: SummerPulseIcon(isSelected: isSelected),
            ),
          ],
        ),
      ),
    );
  }
}

class SummerPulseIcon extends StatefulWidget {
  final bool isSelected;
  const SummerPulseIcon({super.key, required this.isSelected});

  @override
  State<SummerPulseIcon> createState() => _SummerPulseIconState();
}

class _SummerPulseIconState extends State<SummerPulseIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isSelected) {
      return const Icon(Icons.wb_sunny_outlined, size: 28, color: Colors.black26);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Vòng tròn ripple lan tỏa đơn giản nhưng cực sang
            Container(
              width: 45 + (15 * _controller.value),
              height: 45 + (15 * _controller.value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.orangeAccent.withOpacity(1 - _controller.value),
                  width: 2,
                ),
              ),
            ),
            // Nút Gradient tròn
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Colors.pink, Colors.pinkAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pinkAccent.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_fire_department_rounded, // Icon ngọn lửa mùa hè rực cháy
                size: 26,
                color: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }
}