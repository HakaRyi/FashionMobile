import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/terms_checkbox.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isAccepted = false;

  void _handleRegister() {
    if (!_isAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng đồng ý với điều khoản dịch vụ")),
      );
      return;
    }
    // Demo đăng ký thành công
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Đăng ký thành công! Vui lòng đăng nhập.")),
    );
    Navigator.pop(context); // Quay lại trang Login
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const Text(
              "TẠO TÀI KHOẢN",
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Tham gia cộng đồng Fashion AI ngay hôm nay",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 40),

            CustomTextField(
              hintText: "Họ và tên",
              icon: Icons.person_outline,
              controller: _nameController,
            ),
            CustomTextField(
              hintText: "Email",
              icon: Icons.email_outlined,
              controller: _emailController,
            ),
            CustomTextField(
              hintText: "Mật khẩu",
              icon: Icons.lock_outline,
              isPassword: true,
              controller: _passwordController,
            ),
            CustomTextField(
              hintText: "Xác nhận mật khẩu",
              icon: Icons.lock_reset,
              isPassword: true,
              controller: _confirmPasswordController,
            ),

            TermsCheckbox(onChanged: (val) => _isAccepted = val ?? false),

            const SizedBox(height: 30),

            // Nút Register chính
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFC00A6), Color(0xFFB50076)],
                ),
              ),
              child: ElevatedButton(
                onPressed: _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text(
                  "ĐĂNG KÝ",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Đã có tài khoản?", style: TextStyle(color: Colors.white70)),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Đăng nhập", style: TextStyle(color: AppColors.textPink)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}