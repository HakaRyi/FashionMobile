// lib/screens/deposit_screen.dart
import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/notification_type.dart';
import '../utils/app_notification.dart';
import '../../constants/app_colors.dart';
import '../managers/payment_manager.dart';

class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final TextEditingController _amountController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat.decimalPattern('vi_VN');

  final List<double> _quickAmounts = <double>[
    10000,
    20000,
    50000,
    100000,
    200000,
    500000,
  ];

  final PaymentManager _paymentManager = PaymentManager();

  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  double _selectedAmount = 0.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();

    _linkSubscription = _appLinks.uriLinkStream.listen(
          (Uri uri) {
        if (!mounted) return;

        if (uri.scheme == 'fashionmobile' && uri.host == 'payment-result') {
          final String? status = uri.queryParameters['status'];

          if (status == '00') {
            _showSuccessDialog();
          } else {
            _showErrorDialog();
          }
        }
      },
      onError: (_) {
        if (!mounted) return;
        _showErrorDialog();
      },
    );
  }

  Future<void> _processPayment() async {
    if (_selectedAmount < 10000) {
      NotificationService.show(
        context,
        title: "Thất bại",
        message: "Số tiền nạp tối thiểu là 10.000đ",
        type: NotificationType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _paymentManager.processPayment(_selectedAmount);
    } catch (e) {
      if (!mounted) return;

      NotificationService.show(
        context,
        title: "Thất bại",
        message: "Lỗi hệ thống",
        type: NotificationType.error,
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onQuickAmountSelected(double amount) {
    setState(() {
      _selectedAmount = amount;
      _amountController.text = _currencyFormat.format(amount);
    });
  }

  void _onAmountChanged(String value) {
    final String cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanValue.isEmpty) {
      setState(() {
        _selectedAmount = 0.0;
      });
      return;
    }

    final double amount = double.tryParse(cleanValue) ?? 0.0;

    setState(() {
      _selectedAmount = amount;
    });
  }

  void _showSuccessDialog() {
    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 64,
          ),
          content: const Text(
            'Thanh toán thành công! Số dư của bạn sẽ được cập nhật trong giây lát.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text(
                'Xác nhận',
                style: TextStyle(color: Colors.pink),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog() {
    if (!mounted) return;

    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Icon(
            Icons.error,
            color: Colors.red,
            size: 64,
          ),
          content: const Text(
            'Giao dịch thất bại hoặc đã bị hủy. Vui lòng thử lại.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Đóng',
                style: TextStyle(color: Colors.pink),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Nạp tiền Wapo Pay'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Nhập số tiền cần nạp',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              onChanged: _onAmountChanged,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                suffixText: 'đ',
                suffixStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _quickAmounts.map((double amount) {
                final bool isSelected = _selectedAmount == amount;

                return GestureDetector(
                  onTap: () => _onQuickAmountSelected(amount),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.pink
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Colors.pinkAccent
                            : Colors.white10,
                      ),
                    ),
                    child: Text(
                      '${_currencyFormat.format(amount)}đ',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),
            const Text(
              'Phương thức thanh toán',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.blueAccent.withOpacity(0.5),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'VNP',
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'VNPay (Sandbox)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Thanh toán qua cổng VNPay',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.check_circle,
                    color: Colors.blueAccent,
                  ),
                ],
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isLoading ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : Text(
                'Thanh toán ${_currencyFormat.format(_selectedAmount)}đ',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}