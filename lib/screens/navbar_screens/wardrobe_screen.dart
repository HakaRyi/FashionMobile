import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../widgets/clothing_item.dart'; // 1. Import file vừa tạo
import '../../screens/upload_screens.dart';
import '../../screens/suggestion_screen.dart';
import '../../screens/try_on_screen.dart';
import '../../screens/fashion_news_screen.dart';






class WardrobeScreen extends StatelessWidget {
  const WardrobeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- PHẦN 1: TIÊU ĐỀ & CÁC NÚT (Giữ nguyên code của bạn) ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center( // Thêm Center ở đây
                    child: Text(
                      "Tủ Đồ",
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildActionButton(
                        icon: Icons.add_a_photo,
                        label: "Thêm đồ",
                        color: AppColors.accent,
                        onTap: () => _showUploadMenu(context),
                      ),
                      const SizedBox(width: 10),
                      _buildActionButton(
                        icon: Icons.lightbulb_outline,
                        label: "Gợi ý",
                        color: Colors.orangeAccent,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SuggestionScreen()),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      _buildActionButton(
                        icon: Icons.face,
                        label: "Thử đồ",
                        color: AppColors.textPink,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const TryOnScreen()),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      _buildActionButton(
                        icon: Icons.stroller_outlined,
                        label: "Thời trang",
                        color: Colors.yellowAccent,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const FashionNewsScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(color: AppColors.divider, thickness: 1),

            // --- PHẦN 2: DANH SÁCH (Đã được tối ưu) ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GridView.builder(
                  itemCount: 1,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemBuilder: (context, index) {
                    // 2. Gọi widget đã tách ở đây
                    return ClothingItem(
                      title: "Áo đồ số ${index + 1}",
                      imageUrl: "assets/images/vietnamjersey.png", // Khi nào có ảnh thì mở ra
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Giữ lại hàm _buildActionButton ở đây hoặc tách tiếp tùy bạn
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  void _showUploadMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Để menu ôm sát nội dung
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: const Text("Chụp ảnh mới", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context); // Đóng menu
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CameraUploadScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: const Text("Chọn từ thư viện", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const GalleryUploadScreen()));
                },
              ),
            ],
          ),
        );
      },
    );
  }
}