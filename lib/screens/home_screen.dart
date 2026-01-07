import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/main_app_bar.dart';
import '../widgets/post_item.dart';
import '../widgets/create_post_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MainAppBar(),
      body: AnimatedOpacity(
        duration: const Duration(milliseconds: 600),
        opacity: _isVisible ? 1.0 : 0.0,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            const CreatePostHeader(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                "Bản tin mới nhất",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 10,
              separatorBuilder: (context, index) => const Divider(
                color: AppColors.divider,
                height: 1,
              ),
              itemBuilder: (context, index) => const PostItem(),
            ),
          ],
        ),
      ),
    );
  }
}