// lib/widgets/expense/expense_summary_grid.dart

import 'package:flutter/material.dart';
import '../../utils/expense_formatters.dart';
import '../../models/expense_summary_model.dart';
import 'expense_common_widgets.dart';

class ExpenseSummaryGrid extends StatelessWidget {
  final ExpenseSummaryModel? summary;
  const ExpenseSummaryGrid({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Income',
                value: formatAdaptiveMoney(summary?.totalIncome ?? 0, compact: true),
                icon: Icons.south_west_rounded,
                color: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Expense',
                value: formatAdaptiveMoney(summary?.totalExpense ?? 0, compact: true),
                icon: Icons.north_east_rounded,
                color: const Color(0xFFEF4444),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _NetCard(summary: summary),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ExpenseSectionCard(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                SizedBox(
                  height: 22,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(value,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF111827))),
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

class _NetCard extends StatelessWidget {
  final ExpenseSummaryModel? summary;
  const _NetCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final net = summary?.netAmount ?? 0;
    final isPositive = net >= 0;
    final color = isPositive ? const Color(0xFF2563EB) : const Color(0xFFF59E0B);

    return ExpenseSectionCard(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isPositive ? Icons.insights_rounded : Icons.show_chart_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Net cashflow',
                    style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                SizedBox(
                  height: 24,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(formatMoney(net),
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF111827))),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: isPositive
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFFFEDD5),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isPositive ? 'Positive' : 'Negative',
              style: TextStyle(
                  color: isPositive
                      ? const Color(0xFF166534)
                      : const Color(0xFF9A3412),
                  fontSize: 12,
                  fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}