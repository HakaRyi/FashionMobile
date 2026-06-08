// lib/widgets/expense/expense_spending_limit_card.dart

import 'package:flutter/material.dart';
import '../../utils/expense_formatters.dart';
import '../../models/spending_limit_model.dart';
import 'expense_common_widgets.dart';

class ExpenseSpendingLimitCard extends StatelessWidget {
  final SpendingLimitModel? spendingLimit;
  final bool isUpdating;
  final VoidCallback onUpdate;
  final VoidCallback onRemove;

  const ExpenseSpendingLimitCard({
    super.key,
    required this.spendingLimit,
    required this.isUpdating,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final data = spendingLimit;

    if (data == null) {
      return ExpenseSectionCard(
        child: ExpenseEmptyState('No spending limit data available.'),
      );
    }

    final hasLimit =
        data.monthlySpendingLimit != null && data.monthlySpendingLimit! > 0;
    final progress =
    hasLimit ? (data.usedPercent / 100).clamp(0.0, 1.0) : 0.0;

    Color statusColor;
    String statusText;

    if (!hasLimit) {
      statusColor = const Color(0xFF6B7280);
      statusText = 'No limit set';
    } else if (data.isExceeded) {
      statusColor = const Color(0xFFEF4444);
      statusText = 'Limit exceeded';
    } else {
      statusColor = const Color(0xFF10B981);
      statusText = 'Within limit';
    }

    return ExpenseSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Spending limit',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827))),
              ),
              _UpdateLimitButton(
                hasLimit: hasLimit,
                isUpdating: isUpdating,
                onUpdate: onUpdate,
                onRemove: onRemove,
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Maximum amount you can spend this month. New spending will be blocked when the limit is exceeded.',
            style: TextStyle(
                fontSize: 13, color: Color(0xFF6B7280), height: 1.35),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _LimitMetric(
                  label: 'Monthly limit',
                  value: hasLimit
                      ? formatMoney(data.monthlySpendingLimit!)
                      : 'Not set',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LimitMetric(
                  label: 'Spent',
                  value: formatMoney(data.spentThisMonth),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _LimitMetric(
                  label: 'Remaining',
                  value: hasLimit ? formatMoney(data.remainingAmount) : '--',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LimitMetric(
                  label: 'Used',
                  value: hasLimit
                      ? '${data.usedPercent.toStringAsFixed(1)}%'
                      : '--',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ExpenseStatusPill(text: statusText, color: statusColor),
              const ExpenseNeutralPill('Hard limit enabled'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LimitMetric extends StatelessWidget {
  final String label;
  final String value;
  const _LimitMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _UpdateLimitButton extends StatelessWidget {
  final bool hasLimit;
  final bool isUpdating;
  final VoidCallback onUpdate;
  final VoidCallback onRemove;

  const _UpdateLimitButton({
    required this.hasLimit,
    required this.isUpdating,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasLimit) ...[
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isUpdating ? null : onRemove,
              borderRadius: BorderRadius.circular(14),
              child: Ink(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_outline_rounded,
                        size: 16, color: Color(0xFFDC2626)),
                    SizedBox(width: 6),
                    Text('Remove',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFDC2626))),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isUpdating ? null : onUpdate,
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isUpdating) ...[
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                  ] else ...[
                    const Icon(Icons.edit_rounded,
                        size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                  ],
                  const Text('Update',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}