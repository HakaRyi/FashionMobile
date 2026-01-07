import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/main_app_bar.dart';
import '../widgets/main_bottom_nav.dart';
import '../widgets/post_item.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MainAppBar(),
      body: ListView.separated(
        itemCount: 3,
        separatorBuilder: (context, index) => const Divider(color: AppColors.divider, height: 1),
        itemBuilder: (context, index) => const PostItem(),
      ),
      bottomNavigationBar: const MainBottomNav(),
    );
  }
}