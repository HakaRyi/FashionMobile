import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/clothing_item.dart';

class SuggestionScreen extends StatelessWidget {
  const SuggestionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "GỢI Ý PHỐI ĐỒ",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- PHẦN 1: OUTFIT CỦA NGÀY (AI SUGGESTION) ---
            const Text(
              "Outfit dành cho hôm nay",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.textPink.withOpacity(0.5)),
                gradient: LinearGradient(
                  colors: [AppColors.surface, AppColors.textPink.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniItem("Áo Polo", Icons.checkroom),
                      const Icon(Icons.add, color: Colors.white24),
                      _buildMiniItem("Quần Jean", Icons.checkroom),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Phù hợp với thời tiết 25°C - Năng động",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- PHẦN 2: DANH SÁCH GỢI Ý KHÁC ---
            const Text(
              "Phong cách khác",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 15),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemBuilder: (context, index) {
                return _buildStyleCard(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Widget con cho món đồ nhỏ trong Outfit đề xuất
  Widget _buildMiniItem(String label, IconData icon) {
    return Column(
      children: [
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  // Widget con cho thẻ phong cách gợi ý
  Widget _buildStyleCard(int index) {
    List<String> styles = ["Minimalist", "Streetwear", "Vintage", "Office"];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        image: const DecorationImage(
          image: NetworkImage("https://via.placeholder.com/150"), // Thay bằng ảnh phối đồ mẫu
          fit: BoxFit.cover,
          opacity: 0.5,
        ),
      ),
      child: Container(
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [Colors.transparent, Colors.black87],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Text(
          styles[index % 4],
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}