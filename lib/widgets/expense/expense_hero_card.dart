// lib/widgets/expense/expense_hero_card.dart

import 'package:flutter/material.dart';
import '../../utils/expense_formatters.dart';
import '../../models/expense_summary_model.dart';

class ExpenseHeroCard extends StatelessWidget {
  final DateTimeRange? selectedDateRange;
  final ExpenseSummaryModel? summary;

  const ExpenseHeroCard({
    super.key,
    this.selectedDateRange,
    required this.summary,
  });

  String _periodLabel() {
    final range = selectedDateRange;
    if (range == null) return 'Unknown Period';

    final start = range.start;
    final end = range.end;

    if (start.year == end.year && start.month == end.month) {
      return 'Month ${start.month}/${start.year}';
    }

    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    return '${fmt(start)} – ${fmt(end)}';
  }

  @override
  Widget build(BuildContext context) {
    final currentBalance = summary?.currentBalance ?? 0;
    final lockedBalance = summary?.currentLockedBalance ?? 0;
    final totalIncome = summary?.totalIncome ?? 0;
    final totalExpense = summary?.totalExpense ?? 0;
    final netAmount = summary?.netAmount ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.24),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _periodLabel(),
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: Text(
                  '${summary?.totalTransactions ?? 0} txs', // Rút gọn nhẹ tiêu đề item nếu cần thiết
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Current balance',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 7),
          SizedBox(
            height: 42,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatMoney(currentBalance),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32, // Tăng nhẹ size vì đã có không gian thoải mái hơn
                    height: 1.1,
                    fontWeight: FontWeight.w900),
              ),
            ),
          ),
          // const SizedBox(height: 8),
          // Text(
          //   'Locked balance: ${formatMoney(lockedBalance)}',
          //   maxLines: 1,
          //   overflow: TextOverflow.ellipsis,
          //   style: const TextStyle(
          //       color: Colors.white70,
          //       fontSize: 13,
          //       fontWeight: FontWeight.w500),
          // ),
          const SizedBox(height: 20),

          // Thay đổi chiến thuật: Sử dụng Row nhưng thiết kế item tối ưu chiều dọc
          Row(
            children: [
              Expanded(
                child: _HeroMiniInfo(
                  icon: Icons.arrow_downward_rounded,
                  label: 'Income',
                  value: formatMoney(totalIncome),
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroMiniInfo(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Expense',
                  value: formatMoney(totalExpense),
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _HeroMiniInfo(
            icon: netAmount >= 0
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            label: 'Net cashflow',
            value: formatMoney(netAmount),
            color: netAmount >= 0
                ? const Color(0xFF38BDF8)
                : const Color(0xFFF59E0B),
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}

class _HeroMiniInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool fullWidth;

  const _HeroMiniInfo({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      // Sử dụng lồng ghép linh hoạt: Trục ngang cho FullWidth và cấu trúc tối ưu cho nửa màn hình
      child: fullWidth
          ? Row(
        children: [
          _buildIcon(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel(),
                const SizedBox(height: 4),
                _buildValueText(),
              ],
            ),
          ),
        ],
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildIcon(),
              const SizedBox(width: 8),
              Expanded(child: _buildLabel()),
            ],
          ),
          const SizedBox(height: 10),
          _buildValueText(),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }

  Widget _buildLabel() {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
          color: Colors.white60,
          fontSize: 12,
          fontWeight: FontWeight.w500),
    );
  }

  Widget _buildValueText() {
    return SizedBox(
      height: 24,
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15.5, // Tăng kích thước chữ số tiền lớn hơn ban đầu
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}