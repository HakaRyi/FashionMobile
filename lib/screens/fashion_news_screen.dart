import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
// chắc trang này làm kiểu về mấy tính năng thời trang khác đi ha, để tạm bài báo mốt thay cái khác :))
class FashionNewsScreen extends StatelessWidget {
  const FashionNewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Xu hướng thời trang",
          style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: 5, // Số lượng tin tức giả định
        itemBuilder: (context, index) {
          return _buildNewsCard(index);
        },
      ),
    );
  }

  Widget _buildNewsCard(int index) {
    // Dữ liệu giả định
    List<String> titles = [
      "Xu hướng Streetwear 2026: Sự trỗi dậy của Techwear",
      "Cách phối đồ với tông màu Pastel cực chất",
      "Bộ sưu tập Xuân Hè 'Starbucks Fashion' vừa ra mắt",
      "Top 5 phụ kiện không thể thiếu trong mùa lễ hội",
      "AI đang thay đổi ngành công nghiệp thời trang như thế nào?"
    ];

    return Container(

      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hình ảnh tin tức
          Stack(
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    // Sau này thay bằng link ảnh thật
                    image: NetworkImage("https://picsum.photos/id/${index + 10}/600/400"),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Tag phân loại
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.textPink,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "TRENDING",
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          // Nội dung tin tức
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titles[index % titles.length],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Khám phá những phong cách mới nhất và cách áp dụng chúng vào tủ đồ của bạn ngay hôm nay...",
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("15 phút trước", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    TextButton(
                      onPressed: () {},
                      child: const Text("Đọc thêm", style: TextStyle(color: AppColors.textPink)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}