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
import '../screens/expense_management_screen.dart';
import '../utils/route_transitions.dart';

class WapoPaySheet extends StatefulWidget {
  final double initialBalance;

  const WapoPaySheet({
    super.key,
    required this.initialBalance,
  });

  @override
  State<WapoPaySheet> createState() => _WapoPaySheetState();
}

class _WapoPaySheetState extends State<WapoPaySheet> {
  final NumberFormat _currencyFormat = NumberFormat.decimalPattern('vi_VN');

  bool _isBalanceObscured = false;

  String _formatMoney(double value) {
    return '${_currencyFormat.format(value)} VND';
  }

  String _displayBalance() {
    if (_isBalanceObscured) {
      return '••••••••';
    }

    return _formatMoney(widget.initialBalance);
  }

  void _openDepositScreen() {
    Navigator.pop(context);

    Navigator.push(
      context,
      SlideRoute(page: const DepositScreen()),
    );
  }

  void _openExpenseManagement() {
    Navigator.pop(context);

    Navigator.push(
      context,
      SlideRoute(page: const ExpenseManagementScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F5),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.text,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            _buildHeader(),
            const SizedBox(height: 16),
            _buildBalanceCard(),
            const SizedBox(height: 16),
            _buildActionRow(),
            const SizedBox(height: 14),
            _buildWalletNote(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.black.withOpacity(0.06),
            ),
          ),
          child: const Icon(
            Icons.account_balance_wallet_outlined,
            color: Colors.black,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Wapo Pay',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Wallet balance and quick actions',
                style: TextStyle(
                  color: Colors.black45,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _openExpenseManagement,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(
                color: Colors.black.withOpacity(0.05),
              ),
            ),
          ),
          icon: const Icon(
            Icons.bar_chart_rounded,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Wallet balance',
                  style: TextStyle(
                    color: Colors.black45,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _isBalanceObscured = !_isBalanceObscured;
                  });
                },
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F3F3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isBalanceObscured
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.black54,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 46,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                _displayBalance(),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSmallInfoBox(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Orders',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSmallInfoBox(
                  icon: Icons.auto_awesome_outlined,
                  label: 'AI services',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSmallInfoBox(
                  icon: Icons.checkroom_outlined,
                  label: 'Try-on',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallInfoBox({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black.withOpacity(0.04),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.black,
            size: 20,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow() {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            icon: Icons.add_rounded,
            title: 'Top up',
            subtitle: 'Add balance',
            isPrimary: true,
            onTap: _openDepositScreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            icon: Icons.receipt_long_outlined,
            title: 'History',
            subtitle: 'View expenses',
            isPrimary: false,
            onTap: _openExpenseManagement,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isPrimary ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isPrimary ? Colors.black : Colors.black.withOpacity(0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.025),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isPrimary
                    ? Colors.white.withOpacity(0.15)
                    : const Color(0xFFF3F3F3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: isPrimary ? Colors.white : Colors.black,
                size: 22,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isPrimary ? Colors.white : Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isPrimary ? Colors.white70 : Colors.black45,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.black.withOpacity(0.05),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Colors.black45,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Use Wapo Pay for orders, try-on, AI suggestions, and other in-app services.',
              style: TextStyle(
                color: Colors.black45,
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}