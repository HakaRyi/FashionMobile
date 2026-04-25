// lib/widgets/wapo_pay_sheet.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../screens/create_post_screens.dart';
import '../../screens/settings_screen.dart';
import '../../services/account_service.dart';
import '../../services/post_service.dart';
import '../../utils/route_transitions.dart';
import '../../widgets/post_item.dart';
import '../../models/post_feed_model.dart';

// [THÊM MỚI]
import '../screens/transaction_history_screen.dart';
import '../screens/deposit_screen.dart';

class WapoPaySheet extends StatefulWidget {
  final double initialBalance;
  const WapoPaySheet({super.key, required this.initialBalance});

  @override
  State<WapoPaySheet> createState() => _WapoPaySheetState();
}

class _WapoPaySheetState extends State<WapoPaySheet> {
  bool _isBalanceObscured = false;
  final NumberFormat _currencyFormat = NumberFormat.decimalPattern('vi_VN');

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.text,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // [SỬA LẠI]
          Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, color: AppColors.text),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      SlideRoute(page: const TransactionHistoryScreen()),
                    );
                  },
                ),
              ),
              const Text(
                "Wapo Pay",
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(16),

            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Wallet balance",
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isBalanceObscured = !_isBalanceObscured;
                        });
                      },
                      child: Icon(
                        _isBalanceObscured ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.text,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _isBalanceObscured ? "******" : _currencyFormat.format(widget.initialBalance),
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!_isBalanceObscured)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 4, left: 4),
                        child: Text(
                          "đ",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // [SỬA LẠI]
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                SlideRoute(page: const DepositScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              "Top up",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}