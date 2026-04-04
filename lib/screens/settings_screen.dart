// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/account_service.dart';
import '../utils/route_transitions.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';
import 'expense_management_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Cài đặt và Hoạt động",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          _buildSectionTitle("Cách bạn sử dụng Fashion AI"),
          _buildSettingItem(Icons.person_outline, "Chỉnh sửa hồ sơ", () async {
            final profile = await AccountService().getMyProfile();
            if (profile != null && context.mounted) {
              final updated = await Navigator.push(
                  context,
                  SlideRoute(
                    page: EditProfileScreen(currentProfile: profile),
                  ),
              );
              if (updated == true && context.mounted) {
                Navigator.pop(context, true);
              }
            }
          }),
          _buildSettingItem(Icons.notifications_none, "Thông báo", () {}),
          _buildSettingItem(Icons.lock_outline, "Quyền riêng tư", () {}),

          const SizedBox(height: 20),

          _buildSectionTitle("Hoạt động của bạn"),
          _buildSettingItem(Icons.history, "Nhật ký thử đồ", () {}),
          _buildSettingItem(Icons.favorite_border, "Trang phục đã lưu", () {}),
          _buildSettingItem(Icons.analytics_outlined, "Thống kê phong cách", () {}),
          _buildSettingItem(
            Icons.account_balance_wallet_outlined,
            "Quản lý chi tiêu",
                () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ExpenseManagementScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          _buildSectionTitle("Thông tin thêm"),
          _buildSettingItem(Icons.help_outline, "Trợ giúp", () {}),
          _buildSettingItem(Icons.info_outline, "Về chúng tôi", () {}),

          const SizedBox(height: 40),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton(
              onPressed: () => _showLogoutDialog(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.redAccent, width: 1),
                ),
              ),
              child: const Text(
                "Đăng xuất",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Colors.white, size: 22),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 15),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: Colors.white24,
        size: 14,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          "Đăng xuất?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Bạn có chắc chắn muốn đăng xuất khỏi tài khoản này không?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
              );
            },
            child: const Text(
              "Đăng xuất",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}