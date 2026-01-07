import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final List<String> _history = [
    "Đôn Lằng",
    "Chó Đôn",
    "Đôn heo",
    "Đăng loz",
    "Quỷ Đôn"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Tìm kiếm",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            _buildSectionTitle("Lịch sử tìm kiếm"),
            _buildSearchHistory(),
            _buildSectionTitle("Gợi ý cho bạn"),
            _buildSuggestedProfiles(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.pink.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.pink.withOpacity(0.1)),
        ),
        child: const TextField(
          decoration: InputDecoration(
            hintText: "Tìm kiếm người dùng hoặc xu hướng...",
            hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: Colors.pinkAccent),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 20, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSearchHistory() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _history.map((item) => ActionChip(
          label: Text(item),
          avatar: const Icon(Icons.history, size: 16, color: AppColors.textPrimary),
          backgroundColor: Colors.grey[800],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          onPressed: () {},
        )).toList(),
      ),
    );
  }

  Widget _buildSuggestedProfiles() {
    int itemCount = 5; // Giả lập số lượng item

    return Column(
      children: [
        const Divider(
          height: 1,
          thickness: 1,
          color: Color(0xFFF1F1F1),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          padding: EdgeInsets.zero,
          itemBuilder: (context, index) {
            return Column(
              children: [
                _buildProfileCard(
                  name: "Nguyễn Mỹ Linh",
                  username: "@mylinh_fashion",
                  followers: "${(index + 1) * 2.5}K người theo dõi",
                  imageUrl: "https://i.pravatar.cc/150?u=$index",
                ),
                if (index < itemCount - 1)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 90,
                    color: Color(0xFFF1F1F1),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildProfileCard({
    required String name,
    required String username,
    required String followers,
    required String imageUrl,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.pinkAccent.withOpacity(0.3), width: 2),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundImage: NetworkImage(imageUrl),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  username,
                  style: const TextStyle(
                    color: Colors.pinkAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  followers,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent.withOpacity(0.1),
              foregroundColor: Colors.pinkAccent,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              "Theo dõi",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}