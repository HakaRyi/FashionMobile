import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/google_login_button.dart';
import 'main_screen.dart'; // Giả sử đây là trang chứa Navbar của bạn
import '../services/auth_service.dart';
import 'register_screen.dart';

import '../managers/google_auth_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService(); // Khởi tạo Service
  final GoogleAuthManager _googleAuthManager = GoogleAuthManager();

  bool _isLoading = false;
  Future<void> _handleLogin() async {
    String email = _emailController.text.trim();
    String pass = _passwordController.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      _showSnackBar("Vui lòng nhập đầy đủ thông tin");
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.login(email, pass);

    setState(() => _isLoading = false);

    if (result['success']) {
      // Lưu Token vào bộ nhớ nếu cần (ví dụ: SharedPreferences) rồi qua trang Home
      print("Token: ${result['data']['accessToken']}");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else {
      // Hiển thị lỗi từ API trả về
      _showSnackBar(result['message']);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    try {
      final idToken = await _googleAuthManager.getGoogleIdToken();

      if (idToken == null) {
        setState(() => _isLoading = false);
        return;
      }

      final result = await _authService.loginWithGoogle(idToken);

      if (result['success']) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', result['data']['accessToken']);

        if (mounted) {
          if (result['isNewUser'] == true) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const OnboardingScreen()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen()),
            );
          }
        }
      } else {
        if (mounted) _showSnackBar(result['message']);
      }
    } catch (e) {
      if (mounted) _showSnackBar(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 100),
            // Logo hoặc Icon App
            Image.asset(
              'assets/images/logowapo.png',
              height: 35,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),

            const SizedBox(height: 40),

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

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text("Quên mật khẩu?", style: TextStyle(color: Colors.grey)),
              ),
            ),

            const SizedBox(height: 20),
            // Nút Login chính
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: const LinearGradient(colors: [Color(0xFFFC00A6), Color(0xFFB50076)]),
              ),
              child: ElevatedButton(
                onPressed: _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2))
                    : const Text("ĐĂNG NHẬP",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 20),
            const Text("HOẶC", style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 20),

            GoogleLoginButton(
              onTap: _isLoading ? () {} : _handleGoogleLogin,
            ),

            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Chưa có tài khoản?", style: TextStyle(color: Colors.white70)),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterScreen()),
                    );
                  },
                  child: const Text("Đăng ký ngay", style: TextStyle(color: AppColors.textPink)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}