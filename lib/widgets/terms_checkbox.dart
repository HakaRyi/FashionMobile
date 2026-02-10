import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class TermsCheckbox extends StatefulWidget {
  final Function(bool?) onChanged;
  const TermsCheckbox({super.key, required this.onChanged});

  @override
  State<TermsCheckbox> createState() => _TermsCheckboxState();
}

class _TermsCheckboxState extends State<TermsCheckbox> {
  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: _isChecked,
          activeColor: AppColors.textPink,
          checkColor: Colors.white,
          side: const BorderSide(color: Colors.grey),
          onChanged: (value) {
            setState(() => _isChecked = value!);
            widget.onChanged(value);
          },
        ),
        const Expanded(
          child: Text(
            "Tôi đồng ý với Điều khoản sử dụng và Chính sách bảo mật",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      ],
    );
  }
}