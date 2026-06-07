// lib/sheets/spending_limit_sheet.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SpendingLimitSheet extends StatefulWidget {
  final double? initialLimit;
  final double spentThisMonth;
  final NumberFormat moneyFormat;

  const SpendingLimitSheet({
    super.key,
    required this.initialLimit,
    required this.spentThisMonth,
    required this.moneyFormat,
  });

  @override
  State<SpendingLimitSheet> createState() => _SpendingLimitSheetState();
}

class _SpendingLimitSheetState extends State<SpendingLimitSheet> {
  late final TextEditingController _limitController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final initialLimit = widget.initialLimit;
    _limitController = TextEditingController(
      text: initialLimit != null && initialLimit > 0
          ? widget.moneyFormat.format(initialLimit)
          : '',
    );
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  void _formatLimitInput(String value) {
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      _limitController.value = const TextEditingValue(text: '');
      return;
    }
    final number = num.tryParse(digitsOnly);
    if (number == null) return;
    final formatted = widget.moneyFormat.format(number);
    _limitController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  void _submit() {
    final raw = _limitController.text
        .replaceAll('.', '')
        .replaceAll(',', '')
        .trim();

    if (raw.isEmpty) {
      setState(() => _errorText = 'Please enter a monthly limit.');
      return;
    }
    final limit = double.tryParse(raw);
    if (limit == null) {
      setState(() => _errorText = 'Monthly limit is invalid.');
      return;
    }
    if (limit <= 0) {
      setState(() => _errorText = 'Monthly limit must be greater than 0.');
      return;
    }
    if (limit < 10000) {
      setState(() => _errorText = 'Monthly limit must be at least 10.000 VND.');
      return;
    }
    if (limit > 1000000000) {
      setState(
              () => _errorText = 'Monthly limit cannot exceed 1.000.000.000 VND.');
      return;
    }
    if (limit < widget.spentThisMonth) {
      setState(() => _errorText =
      'Monthly limit cannot be lower than your current spending this month.');
      return;
    }
    Navigator.of(context).pop(limit);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Update spending limit',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827))),
                const SizedBox(height: 8),
                const Text(
                  'This hard limit blocks new wallet spending when your monthly spending reaches the limit.',
                  style: TextStyle(
                      fontSize: 13, color: Color(0xFF6B7280), height: 1.35),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFC7D2FE)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: Color(0xFF4F46E5)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Hard limit is always enabled. Warning threshold is not used.',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3730A3),
                              height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _limitController,
                  keyboardType: TextInputType.number,
                  cursorColor: const Color(0xFF111827),
                  style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 15,
                      fontWeight: FontWeight.w700),
                  onChanged: (value) {
                    if (_errorText != null) {
                      setState(() => _errorText = null);
                    }
                    _formatLimitInput(value);
                  },
                  decoration: InputDecoration(
                    labelText: 'Monthly limit',
                    hintText: 'Example: 2.000.000',
                    suffixText: 'VND',
                    errorText: _errorText,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    labelStyle: const TextStyle(
                        color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
                    hintStyle: const TextStyle(
                        color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500),
                    suffixStyle: const TextStyle(
                        color: Color(0xFF374151), fontWeight: FontWeight.w700),
                    errorStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                        const BorderSide(color: Color(0xFFE5E7EB))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                        const BorderSide(color: Color(0xFFE5E7EB))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                        const BorderSide(color: Color(0xFF4F46E5))),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF111827),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Save limit',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}