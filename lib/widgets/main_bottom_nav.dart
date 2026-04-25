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
      // Giảm khoảng cách xung quanh để thanh gọn hơn và không bị nổi quá cao
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Container(
        height: 68, // Giảm chiều cao từ 80 xuống 68
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(34), // Bo tròn tối đa (bằng phân nửa chiều cao)
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4), // Giảm độ đậm của bóng đổ cho thanh thoát hơn
              blurRadius: 20,
              offset: const Offset(0, 8),
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
      child: SizedBox(
        width: 56, // Giới hạn chiều rộng để các nút không bị dính vào nhau
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 24, // Giảm từ 26 xuống chuẩn 24
              color: isSelected ? Colors.black : Colors.black38,
            ),
            const SizedBox(height: 2), // Giảm khoảng cách chữ và icon
            Text(
              label,
              style: TextStyle(
                fontSize: 10, // Giảm cỡ chữ từ 12 xuống 10
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.black : Colors.black38,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterButton() {
    bool isSelected = currentIndex == 2;
    return GestureDetector(
      onTap: () => onTap(2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52, // Giảm kích thước nút giữa từ 65 xuống 52
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.style,
          color: Colors.white,
          size: 24, // Giảm icon nút giữa từ 32 xuống 24 cho cân xứng
        ),
      ),
    );
  }
}