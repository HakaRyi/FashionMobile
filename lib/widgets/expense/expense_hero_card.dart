// lib/widgets/expense/expense_hero_card.dart

import 'package:flutter/material.dart';
import '../../utils/expense_formatters.dart';
import '../../models/expense_summary_model.dart';

class ExpenseHeroCard extends StatelessWidget {
  final int selectedMonth;
  final int selectedYear;
  final ExpenseSummaryModel? summary;

  const ExpenseHeroCard({
    super.key,
    required this.selectedMonth,
    required this.selectedYear,
    required this.summary,
  });

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
              const Icon(Icons.calendar_month_rounded,
                  color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(
                'Month $selectedMonth/$selectedYear',
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                  border:
                  Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: Text(
                  '${summary?.totalTransactions ?? 0} transactions',
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
            height: 40,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatMoney(currentBalance),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 31,
                    height: 1.1,
                    fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Locked balance: ${formatMoney(lockedBalance)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 18),
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
              const SizedBox(width: 10),
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
          const SizedBox(height: 10),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                SizedBox(
                  height: 22,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(value,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}