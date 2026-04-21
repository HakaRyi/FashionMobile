import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/notification_type.dart';
import '../utils/app_notification.dart';
import '../widgets/custom_text_field.dart';
import '../services/auth_service.dart';

class VerifyScreen extends StatefulWidget {
  final String email;

  const VerifyScreen({super.key, required this.email});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final TextEditingController _codeController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleVerify() async {
    String code = _codeController.text.trim();

    if (code.isEmpty) {
      NotificationService.show(
        context,
        title: "Thông báo",
        message: "Vui lòng nhập mã xác thực",
        type: NotificationType.warning,
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.verifyAccount(widget.email, code);

    if (mounted) {
      setState(() => _isLoading = false);

      if (result['success']) {
        NotificationService.show(
          context,
          title: "Thành công",
          message: "Tài khoản đã được xác thực, vui lòng đăng nhập",
          type: NotificationType.success,
        );

        Navigator.pop(context);
      } else {
        NotificationService.show(
          context,
          title: "Lỗi",
          message: result['message'],
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              "Xác thực Email",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Mã xác thực đã được gửi đến:\n${widget.email}",
              style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 40),

            CustomTextField(
              hintText: "Nhập mã 6 chữ số",
              icon: Icons.security,
              controller: _codeController,
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
                onPressed: _isLoading ? null : _handleVerify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("XÁC THỰC", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}