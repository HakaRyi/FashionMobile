import 'package:flutter/material.dart';

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
    return Padding(
      // Tạo khoảng cách để thanh Nav nổi lên như viên thuốc
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40), // Bo tròn tối đa 2 đầu
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(0, Icons.home_outlined, Icons.home, "Home"),
            _buildNavItem(1, Icons.search_rounded, Icons.search_rounded, "Search"),

            // Nút Center (Nút Sự kiện / Add)
            _buildCenterButton(),

            _buildNavItem(3, Icons.checkroom_outlined, Icons.checkroom, "Wardrobe"),
            _buildNavItem(4, Icons.person_outline_rounded, Icons.person_rounded, "Profile"),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    bool isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            size: 26,
            color: isSelected ? Colors.black : Colors.black38,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.black : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterButton() {
    bool isSelected = currentIndex == 2;
    return GestureDetector(
      onTap: () => onTap(2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black, // Màu đen tuyền giống ảnh
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Icon(
          Icons.style,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}