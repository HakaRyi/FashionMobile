// lib/widgets/expense/expense_transaction_list.dart

import 'package:flutter/material.dart';
import '../../models/transaction_history_model.dart';
import '../../utils/expense_formatters.dart';
import 'expense_common_widgets.dart';

class ExpenseTransactionList extends StatelessWidget {
  final List<TransactionHistoryModel> transactions;
  final void Function(int transactionId) onTapDetail;

  const ExpenseTransactionList({
    super.key,
    required this.transactions,
    required this.onTapDetail,
  });

  @override
  Widget build(BuildContext context) {
    return ExpenseSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExpenseSectionHeader(
            icon: Icons.receipt_long_rounded,
            title: 'Transaction history',
            subtitle: '${transactions.length} recent transactions',
          ),
          const SizedBox(height: 14),
          if (transactions.isEmpty)
            const ExpenseEmptyState('No transactions found.')
          else
            ...transactions.map((item) => _TransactionItem(
              item: item,
              onTap: () => onTapDetail(item.transactionId),
            )),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final TransactionHistoryModel item;
  final VoidCallback onTap;

  const _TransactionItem({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final displayType = resolveDisplayType(item.type, item.amount);
    final isCredit = displayType == 'Credit';
    final amountColor = typeColor(displayType);
    final sColor = statusColor(item.status);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: amountColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(typeIcon(displayType), color: amountColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(mapTransactionType(item.type),
                          style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF111827))),
                      const SizedBox(height: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ExpenseStatusPill(
                              text: mapStatus(item.status), color: sColor),
                          const SizedBox(height: 8),
                          ExpenseInfoPill(
                              icon: Icons.schedule_rounded,
                              text: formatVietnamTime(item.createdAt)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(item.description ?? 'No description',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    height: 1.35)),
            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ExpenseInfoPill(
                    icon: Icons.tag_rounded, text: item.transactionCode),
                if (item.orderCode != null && item.orderCode!.isNotEmpty)
                  ExpenseInfoPill(
                    icon: Icons.shopping_bag_rounded,
                    text: 'Order: ${item.orderCode}',
                  ),
              ],
            ),

            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  Expanded(
                      child: _BalanceMini(
                          label: 'Before',
                          value: formatAdaptiveMoney(item.balanceBefore,
                              compact: true))),
                  Container(
                      width: 1,
                      height: 30,
                      color: const Color(0xFFE5E7EB)),
                  Expanded(
                      child: _BalanceMini(
                          label: 'After',
                          value: formatAdaptiveMoney(item.balanceAfter,
                              compact: true))),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${isCredit ? '+' : '-'} ${formatAdaptiveMoney(item.amount.abs(), compact: true)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: amountColor),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border:
                    Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Details',
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF374151))),
                      SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded,
                          size: 18, color: Color(0xFF9CA3AF)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceMini extends StatelessWidget {
  final String label;
  final String value;
  const _BalanceMini({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          SizedBox(
            height: 18,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}