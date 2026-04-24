import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/notification_type.dart';
import '../managers/payment_manager.dart';
import '../services/notification_service.dart' as local_noti;
import '../utils/app_notification.dart';
import '../utils/notification_utils.dart';

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

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _amountController.dispose();
    super.dispose();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();

    _linkSubscription = _appLinks.uriLinkStream.listen(
          (Uri uri) async {
        if (!mounted) {
          return;
        }

        if (uri.scheme == 'fashionmobile' && uri.host == 'payment-result') {
          final String? status = uri.queryParameters['status'];

          if (status == '00') {
            await _showDepositSuccessNotification();
            _showSuccessDialog();
          } else {
            await _showDepositFailedNotification();
            _showErrorDialog();
          }
        }
      },
      onError: (_) async {
        if (!mounted) {
          return;
        }

        await _showDepositFailedNotification();
        _showErrorDialog();
      },
    );
  }

  String _formatMoney(double value) {
    return '${_currencyFormat.format(value)} VND';
  }

  String _formatMoneyShort(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M VND';
    }

    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K VND';
    }

    return _formatMoney(value);
  }

  Future<void> _showDepositSuccessNotification() async {
    if (!mounted) {
      return;
    }

    NotificationUtils.showTopRight(
      context,
      message: 'Top-up successful.',
    );

    await local_noti.NotificationService().showManualLocalNotification(
      title: 'Top-up successful',
      body: 'You added ${_formatMoney(_selectedAmount)} to your wallet.',
      channelId: 'wallet_channel',
      channelName: 'Wallet notifications',
    );
  }

  Future<void> _showDepositFailedNotification() async {
    if (!mounted) {
      return;
    }

    NotificationUtils.showTopRight(
      context,
      message: 'Top-up failed.',
      isError: true,
    );

    await local_noti.NotificationService().showManualLocalNotification(
      title: 'Top-up failed',
      body: 'The top-up transaction failed or was cancelled.',
      channelId: 'wallet_channel',
      channelName: 'Wallet notifications',
    );
  }

  Future<void> _processPayment() async {
    FocusScope.of(context).unfocus();

    if (_selectedAmount < 10000) {
      NotificationService.show(
        context,
        title: 'Failed',
        message: 'The minimum top-up amount is 10,000 VND.',
        type: NotificationType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _paymentManager.processPayment(_selectedAmount);
    } catch (_) {
      if (!mounted) {
        return;
      }

      NotificationService.show(
        context,
        title: 'Failed',
        message: 'System error. Please try again.',
        type: NotificationType.error,
      );

      await _showDepositFailedNotification();
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onQuickAmountSelected(double amount) {
    setState(() {
      _selectedAmount = amount;
      _amountController.text = _currencyFormat.format(amount);
      _amountController.selection = TextSelection.fromPosition(
        TextPosition(offset: _amountController.text.length),
      );
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
    if (!mounted) {
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF16A34A),
            size: 64,
          ),
          content: const Text(
            'Payment successful. Your wallet balance will be updated shortly.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                if (mounted) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text(
                'DONE',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog() {
    if (!mounted) {
      return;
    }

    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Icon(
            Icons.error_rounded,
            color: Colors.redAccent,
            size: 64,
          ),
          content: const Text(
            'The transaction failed or was cancelled. Please try again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'CLOSE',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  bool get _canPay {
    return !_isLoading && _selectedAmount >= 10000;
  }

  @override
  Widget build(BuildContext context) {
    final bool hasAmount = _selectedAmount > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'TOP UP',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 17,
            letterSpacing: 0.4,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
        children: <Widget>[
          _buildHeaderCard(),
          const SizedBox(height: 16),
          _buildAmountInputCard(),
          const SizedBox(height: 16),
          _buildQuickAmountSection(),
          const SizedBox(height: 16),
          _buildPaymentMethodSection(),
          const SizedBox(height: 16),
          _buildSummaryCard(hasAmount),
          const SizedBox(height: 24),
          _buildPayButton(),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.add_card_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top up your wallet',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Add balance to pay for orders and Wapo services.',
                  style: TextStyle(
                    color: Colors.black45,
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInputCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.payments_outlined,
            title: 'Amount',
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
            onChanged: _onAmountChanged,
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: const TextStyle(
                color: Colors.black26,
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
              suffixText: 'VND',
              suffixStyle: const TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
              filled: true,
              fillColor: const Color(0xFFF7F7F7),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: Colors.black.withOpacity(0.05),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: Colors.black,
                  width: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Minimum top-up amount is 10,000 VND.',
            style: TextStyle(
              color: Colors.black45,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.bolt_rounded,
            title: 'Quick amount',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _quickAmounts.map((double amount) {
              final bool isSelected = _selectedAmount == amount;

              return InkWell(
                onTap: () => _onQuickAmountSelected(amount),
                borderRadius: BorderRadius.circular(999),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.black : const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isSelected
                          ? Colors.black
                          : Colors.black.withOpacity(0.06),
                    ),
                  ),
                  child: Text(
                    _formatMoneyShort(amount),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.credit_card_rounded,
            title: 'Payment method',
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFF2563EB).withOpacity(0.25),
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Center(
                    child: Text(
                      'VNP',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'VNPay Sandbox',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Pay securely through the VNPay gateway.',
                        style: TextStyle(
                          color: Colors.black45,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF2563EB),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(bool hasAmount) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.receipt_long_outlined,
            title: 'Payment summary',
          ),
          const SizedBox(height: 14),
          _summaryRow(
            label: 'Top-up amount',
            value: hasAmount ? _formatMoney(_selectedAmount) : '0 VND',
          ),
          const SizedBox(height: 10),
          _summaryRow(
            label: 'Gateway fee',
            value: '0 VND',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              height: 1,
              color: Color(0xFFEDEDED),
            ),
          ),
          _summaryRow(
            label: 'Total payment',
            value: hasAmount ? _formatMoney(_selectedAmount) : '0 VND',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _canPay ? _processPayment : null,
        icon: _isLoading
            ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : const Icon(Icons.lock_rounded),
        label: Text(
          _isLoading
              ? 'PROCESSING...'
              : 'PAY ${_selectedAmount > 0 ? _formatMoney(_selectedAmount) : ''}',
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.3,
          ),
        ),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFEDEDED),
          disabledForegroundColor: Colors.black38,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow({
    required String label,
    required String value,
    bool isTotal = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isTotal ? Colors.black : Colors.black54,
              fontSize: isTotal ? 15 : 13.5,
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.black,
              fontSize: isTotal ? 15.5 : 13.5,
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.black,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: Colors.black.withOpacity(0.05),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}