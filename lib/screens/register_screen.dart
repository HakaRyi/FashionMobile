
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  late AnimationController _fabricController;

  @override
  void initState() {
    super.initState();
    _fabricController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _fabricController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

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
              primary: Colors.black,
              onPrimary: Colors.white,
              onSurface: Colors.black,
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
        title: "Notice",
        message: "Please fill in all fields",
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
        title: "Format Error",
        message: "Date of birth must be in DD/MM/YYYY format",
        type: NotificationType.error,
      );
      return;
    }

    if (pass != confirmPass) {
      NotificationService.show(
        context,
        title: "Input Error",
        message: "Passwords do not match",
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
          title: "Success",
          message: "Please check your email for the verification code",
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
          title: "Error",
          message: "Registration failed",
          type: NotificationType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _fabricController,
              builder: (context, child) {
                return CustomPaint(
                  painter: FabricPainter(_fabricController.value),
                );
              },
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    "CREATE ACCOUNT",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Start your fashion journey today",
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  const SizedBox(height: 40),

                  CustomTextField(
                    hintText: "Display Name",
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
                      color: Colors.black.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black.withOpacity(0.08)),
                    ),
                    child: TextFormField(
                      controller: _dobController,
                      keyboardType: TextInputType.datetime,
                      style: const TextStyle(color: Colors.black, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: "Date of Birth (DD/MM/YYYY)",
                        hintStyle: const TextStyle(color: Colors.black45, fontSize: 14),
                        prefixIcon: const Icon(Icons.calendar_today_outlined, color: Colors.black87, size: 20),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.date_range, color: Colors.black54),
                          onPressed: _selectDate,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      ),
                    ),
                  ),

                  CustomTextField(
                    hintText: "Password",
                    icon: Icons.lock_outline,
                    isPassword: true,
                    controller: _passwordController,
                  ),
                  CustomTextField(
                    hintText: "Confirm Password",
                    icon: Icons.lock_reset,
                    isPassword: true,
                    controller: _confirmPasswordController,
                  ),

                  const SizedBox(height: 30),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("REGISTER", style: TextStyle(color: Colors.white, fontSize: 15, letterSpacing: 2, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account?", style: TextStyle(color: Colors.black54)),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Login", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}