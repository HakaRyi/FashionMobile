import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../widgets/clothing_item.dart';
import '../../widgets/add_clothing_card.dart'; // Import widget mới
import '../../screens/upload_screens.dart';
import '../../screens/suggestion_screen.dart';
import '../../screens/try_on_screen.dart';
import '../../screens/fashion_news_screen.dart';
import '../../widgets/action_button.dart';
import '../../screens/clothing_detail_screen.dart';

class WardrobeScreen extends StatelessWidget {
  const WardrobeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    int itemsCount = 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- PHẦN 1: TIÊU ĐỀ & CÁC NÚT ACTION ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Center(
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
                      ActionButton(
                        icon: Icons.add_a_photo,
                        label: "Thêm đồ",
                        color: AppColors.accent,
                        onTap: () => _showUploadMenu(context),
                      ),
                      const SizedBox(width: 10),
                      ActionButton(
                        icon: Icons.lightbulb_outline,
                        label: "Gợi ý",
                        color: Colors.orangeAccent,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SuggestionScreen())),
                      ),
                      const SizedBox(width: 10),
                      ActionButton(
                        icon: Icons.face,
                        label: "Thử đồ",
                        color: AppColors.textPink,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TryOnScreen())),
                      ),
                      const SizedBox(width: 10),
                      ActionButton(
                        icon: Icons.stroller_outlined,
                        label: "Thời trang",
                        color: Colors.yellowAccent,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FashionNewsScreen())),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(color: AppColors.divider, thickness: 1),

            // --- PHẦN 2: DANH SÁCH ĐỒ ---
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: GridView.builder(
            // Giữ nguyên itemCount là tổng số đồ + 1 (cho nút thêm)
            itemCount: itemsCount + 1,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemBuilder: (context, index) {
              // KIỂM TRA NẾU LÀ VỊ TRÍ CUỐI CÙNG
              if (index == itemsCount) {
                return AddClothingCard(
                  onTap: () => _showUploadMenu(context),
                );
              }

              return ClothingItem(
                title: "Áo đồ số ${index}",
                imageUrl: "assets/images/vietnamjersey.png",
                onTap: () { // Bạn nên thêm thuộc tính onTap vào ClothingItem widget
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ClothingDetailScreen(
                        title: "Chi tiết món đồ",
                        imagePath: "assets/images/vietnamjersey.png",
                      ),
                    ),
                  );
                },
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



  void _showUploadMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: const Text("Chụp ảnh mới", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => const UploadScreen(isCamera: true)));
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: const Text("Chọn từ thư viện", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => const UploadScreen(isCamera: false)));
                },
              ),
            ],
          ),
        );
      },
    );
  }
}