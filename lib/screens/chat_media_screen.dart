import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ChatMediaScreen extends StatelessWidget {
  const ChatMediaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text("Ảnh & Video", style: TextStyle(fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // 3 ảnh một hàng
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: 20, // Số lượng ảnh demo
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage("https://picsum.photos/200/200?random=$index"),
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }
}