import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/notification_type.dart';
import '../utils/app_notification.dart';
import '../widgets/custom_text_field.dart';
import '../services/auth_service.dart';
import 'verify_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _handleRegister() async {
    String email = _emailController.text.trim();
    String pass = _passwordController.text.trim();
    String confirmPass = _confirmPasswordController.text.trim();
    String username = _usernameController.text.trim();
    String dobText = _dobController.text.trim();

    if (email.isEmpty || pass.isEmpty || username.isEmpty || dobText.isEmpty) {
      NotificationService.show(
        context,
        title: "Thông báo",
        message: "Vui lòng nhập đầy đủ thông tin",
        type: NotificationType.warning,
      );
      return;
    }

    DateTime parsedDob;
    try {
      parsedDob = DateFormat('dd/MM/yyyy').parseStrict(dobText);
    } catch (e) {
      NotificationService.show(
        context,
        title: "Lỗi định dạng",
        message: "Ngày sinh phải theo định dạng DD/MM/YYYY",
        type: NotificationType.error,
      );
      return;
    }

    if (pass != confirmPass) {
      NotificationService.show(
        context,
        title: "Lỗi nhập liệu",
        message: "Mật khẩu xác nhận không khớp",
        type: NotificationType.error,
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.register(email, pass, username, parsedDob);

    if (mounted) {
      setState(() => _isLoading = false);

      if (result['success']) {
        NotificationService.show(
          context,
          title: "Thành công",
          message: "Vui lòng kiểm tra email để lấy mã xác thực",
          type: NotificationType.success,
        );

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => VerifyScreen(email: email),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutCubic;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(position: animation.drive(tween), child: child);
            },
          ),
        );
      } else {
        NotificationService.show(
          context,
          title: "Lỗi",
          message: 'Đăng ký thất bại',
          type: NotificationType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              "Tạo tài khoản",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Bắt đầu hành trình thời trang của bạn",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 40),

            CustomTextField(
              hintText: "Tên hiển thị",
              icon: Icons.person_outline,
              controller: _usernameController,
            ),
            CustomTextField(
              hintText: "Email",
              icon: Icons.email_outlined,
              controller: _emailController,
            ),

            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(15),
              ),
              child: TextFormField(
                controller: _dobController,
                keyboardType: TextInputType.datetime,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: "Ngày sinh (DD/MM/YYYY)",
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.calendar_today_outlined, color: AppColors.textSecondary),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.date_range, color: AppColors.primary),
                    onPressed: _selectDate,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
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
            const SizedBox(height: 30),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF7AE7), Color(0xFFFBAECD)],
                ),
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("ĐĂNG KÝ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}