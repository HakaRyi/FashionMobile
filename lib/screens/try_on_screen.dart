import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/try_on_item.dart';

class TryOnScreen extends StatefulWidget {
  const TryOnScreen({super.key});

  @override
  State<TryOnScreen> createState() => _TryOnScreenState();
}

class _TryOnScreenState extends State<TryOnScreen> {
  int selectedClothIndex = -1;

  // Hàm hiển thị Menu chọn ảnh (Dùng chung logic)
  void _showUploadSourceMenu(BuildContext context) {
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
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: const Text("Chụp ảnh mới", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  print("Mở Camera");
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: const Text("Chọn từ thư viện", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  print("Mở Gallery");
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true, // Đưa title ra giữa
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "THỬ ĐỒ ẢO",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- PHẦN 1: KHU VỰC MODEL ---
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                      image: const DecorationImage(
                        image: NetworkImage("https://i2-prod.liverpoolecho.co.uk/whats-on/shopping/article10155040.ece/ALTERNATES/s1227b/JS72826573.jpg"),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 15,
                    right: 15,
                    child: GestureDetector(
                      onTap: () => _showUploadSourceMenu(context), // Gọi menu chọn ảnh model
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.textPink.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit_outlined, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- PHẦN 2: CHỌN MÓN ĐỒ ---
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Text(
              "Chọn món đồ để thử",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ),

          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return GestureDetector(
                    onTap: () => _showUploadSourceMenu(context), // Nhấn vào nút thêm áo cũng hiện menu
                    child: _buildAddMoreButton(),
                  );
                }
                return TryOnItem(
                  imagePath: "assets/images/vietnamjersey.png",
                  isSelected: selectedClothIndex == index,
                  onTap: () => setState(() => selectedClothIndex = index),
                );
              },
            ),
          ),

          const Spacer(),

          // --- PHẦN 3: BOTTOM PANEL (Giữ nguyên) ---
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("CHI PHÍ", style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.stars, color: AppColors.textPink, size: 20),
                        const SizedBox(width: 6),
                        const Text("10", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                      ],
                    )
                  ],
                ),
                const SizedBox(width: 40),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: selectedClothIndex != -1
                          ? const LinearGradient(colors: [Color(0xFFFC00A6), Color(0xFFB50076)])
                          : null,
                      color: selectedClothIndex == -1 ? Colors.white10 : null,
                    ),
                    child: ElevatedButton(
                      onPressed: selectedClothIndex != -1 ? () {} : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text("THỬ ĐỒ NGAY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddMoreButton() {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.textSecondary, size: 30),
    );
  }
}