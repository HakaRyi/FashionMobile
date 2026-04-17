import 'package:flutter/material.dart';

class AppColors {
  // static const Color background = Colors.black;
  static const Color surface = Color(0xFF1C1C1E);
  // static const Color textPrimary = Colors.white;
  // static const Color textSecondary = Colors.grey;
  // static const Color textPink = Color(0xFFFC00A6);
  // static const Color accent = Colors.deepPurple;
  // static const Color divider = Color(0xFF262626);
  //
  // static const Color primary = Color(0xFFFC00A6);
  // static const Color background = Colors.white;
  // static const Color surface = Color(0xFF1C1C1E);
  // static const Color textPrimary = Colors.black;
  // static const Color textSecondary = Colors.grey;
  // static const Color textPink = Color(0xFFFC00A6);
  // static const Color accent = Colors.deepPurple;
  // static const Color divider = Color(0xFF262626);
  //
  // static const Color primary = Color(0xFFFC00A6);

  // Ông cố ơi ông cố:
  // --- HỆ THỐNG NỀN (BACKGROUND & SURFACES) ---
  // 1. Nền dưới cùng (dùng cho Scaffold background)
  static const Color background = Colors.white;

  // 2. Nền cấp 2, đè lên nền trắng (dùng cho Card, Container, ListTile)
  // Màu trắng pha chút sắc hồng cực nhẹ (Lavender Blush)
  static const Color backgroundSecondary = Color(0xFFFFE9F7);

  // 3. Nền cấp 3, đè lên cấp 2 (dùng cho các Pop-up, BottomSheet, hoặc khối nổi bật)
  // Màu hồng nhạt (Pink 50), đậm hơn Secondary một chút để phân biệt rõ ràng
  static const Color backgroundTertiary = Color(0xFFFD9FBB);
  static final Color borderPrimary = Colors.pink.withOpacity(0.1);

  // --- HỆ THỐNG CHỮ (TYPOGRAPHY) ---
  // Chữ trên nền sáng phải là màu tối
  static const Color textPrimary = Color(0xFF1A1A1A); // Đen xám đậm (dịu mắt hơn đen tuyền)
  static const Color textSecondary = Color(0xFF757575); // Xám trung tính
  static const Color textPink = Color(0xFFFC00A6); // Giữ nguyên màu hồng nhấn của bạn

  // --- MÀU CHỦ ĐẠO & NHẤN (BRAND COLORS) ---
  static const Color primary = Color(0xFFFC00A6); // Hồng chủ đạo (dùng cho Button chính)
  static const Color accent = Color(0xFFFF4081); // Hồng phấn sáng (dùng cho icon, badge, button phụ)

  // --- CÁC THÀNH PHẦN KHÁC ---
  // Viền/Divider cần nhạt mờ để không làm rối mắt trên nền sáng
  static const Color divider = Color(0xFFF0E6EA); // Xám pha chút hồng nhạt
}