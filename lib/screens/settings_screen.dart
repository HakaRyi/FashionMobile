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
      backgroundColor: const Color(0xFFF5F5F5), // Nền xám nhạt đồng bộ toàn app
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "SETTINGS",
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0, // Giãn chữ phong cách Fashion Magazine
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          _buildSectionTitle("ACCOUNT"),
          _buildSettingsGroup([
            _buildSettingItem(Icons.person_outline, "Edit Profile", () async {
              final profile = await AccountService().getMyProfile();
              if (profile != null && context.mounted) {
                final updated = await Navigator.push(
                  context,
                  SlideRoute(page: EditProfileScreen(currentProfile: profile)),
                );
                if (updated == true && context.mounted) {
                  Navigator.pop(context, true);
                }
              }
            }),
            _buildSettingItem(Icons.notifications_none, "Notifications", () {}),
            _buildSettingItem(Icons.lock_outline, "Privacy & Safety", () {}),
          ]),

          _buildSectionTitle("YOUR ACTIVITY"),
          _buildSettingsGroup([
            _buildSettingItem(Icons.history, "Try-on History", () {}),
            _buildSettingItem(Icons.favorite_border, "Saved Outfits", () {}),
            _buildSettingItem(Icons.analytics_outlined, "Style Analytics", () {}),
            _buildSettingItem(Icons.account_balance_wallet_outlined, "Expense Management", () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseManagementScreen()));
            }),
          ]),

          _buildSectionTitle("SUPPORT"),
          _buildSettingsGroup([
            _buildSettingItem(Icons.help_outline, "Help Center", () {}),
            _buildSettingItem(Icons.info_outline, "About Wapo", () {}),
          ]),

          const SizedBox(height: 40),

          // Nút Đăng xuất thiết kế lại cho tinh tế
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextButton(
              onPressed: () => _showLogoutDialog(context),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.black.withOpacity(0.05)),
                ),
              ),
              child: const Text(
                "LOG OUT",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
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
      padding: const EdgeInsets.fromLTRB(8, 24, 20, 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.black45,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  // Group các item vào một Card trắng
  Widget _buildSettingsGroup(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: items,
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Colors.black, size: 22),
      title: Text(
        title,
        style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w600
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: Colors.black12,
        size: 14,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "Log Out?",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
        ),
        content: const Text(
          "Are you sure you want to log out of your Wapo account?",
          style: TextStyle(color: Colors.black54, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL", style: TextStyle(color: Colors.black26, fontWeight: FontWeight.w900, fontSize: 12)),
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
              "LOG OUT",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}