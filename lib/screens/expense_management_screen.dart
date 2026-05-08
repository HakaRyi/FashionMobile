import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/cashflow_point_model.dart';
import '../models/expense_summary_model.dart';
import '../models/spending_limit_model.dart';
import '../models/transaction_history_model.dart';
import '../models/update_spending_limit_request.dart';
import '../services/expense_service.dart';

class ExpenseManagementScreen extends StatefulWidget {
  const ExpenseManagementScreen({super.key});

  @override
  State<ExpenseManagementScreen> createState() =>
      _ExpenseManagementScreenState();
}

class _ExpenseManagementScreenState extends State<ExpenseManagementScreen> {
  final ExpenseService _expenseService = ExpenseService();
  final NumberFormat _moneyFormat = NumberFormat('#,###', 'vi_VN');
  final TextEditingController _keywordController = TextEditingController();

  late int selectedMonth;
  late int selectedYear;

  bool isLoading = true;
  bool isUpdatingSpendingLimit = false;
  bool _isLoadingTransactionDetail = false;

  String selectedType = '';
  String selectedStatus = '';
  String selectedReferenceType = '';

  ExpenseSummaryModel? summary;
  SpendingLimitModel? spendingLimit;
  List<TransactionHistoryModel> transactions = [];
  List<CashflowPointModel> cashflows = [];

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    selectedMonth = now.month;
    selectedYear = now.year;

    _loadData();
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  String formatMoney(double value) {
    return '${_moneyFormat.format(value)} VND';
  }

  String formatCompactMoney(double value) {
    final abs = value.abs();

    if (abs >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    }

    if (abs >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }

    if (abs >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }

    return _moneyFormat.format(value);
  }

  String formatShortMoney(double value) {
    final abs = value.abs();

    if (abs >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    }

    if (abs >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }

    if (abs >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }

    return '${_moneyFormat.format(value)} VND';
  }

  String formatAdaptiveMoney(double value, {bool compact = false}) {
    if (compact) {
      return formatShortMoney(value);
    }

    return formatMoney(value);
  }

  DateTime _toVietnamTime(DateTime dateTime) {
    if (dateTime.isUtc) {
      return dateTime.add(const Duration(hours: 7));
    }

    return dateTime;
  }

  String _formatVietnamTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(_toVietnamTime(dateTime));
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final fromDate = DateTime(selectedYear, selectedMonth, 1);
      final toDate = DateTime(selectedYear, selectedMonth + 1, 0);

      final results = await Future.wait([
        _expenseService.getExpenseSummary(
          month: selectedMonth,
          year: selectedYear,
        ),
        _expenseService.getMyTransactions(
          page: 1,
          pageSize: 30,
          status: selectedStatus.isEmpty ? null : selectedStatus,
          referenceType:
          selectedReferenceType.isEmpty ? null : selectedReferenceType,
          keyword: _keywordController.text.trim(),
          fromDate: fromDate,
          toDate: toDate,
        ),
        _expenseService.getCashflow(
          fromDate: fromDate,
          toDate: toDate,
          groupBy: 'day',
        ),
        _expenseService.getMySpendingLimit(
          month: selectedMonth,
          year: selectedYear,
        ),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        summary = results[0] as ExpenseSummaryModel;

        final transactionResult = results[1] as Map<String, dynamic>;
        transactions =
        transactionResult['items'] as List<TransactionHistoryModel>;

        cashflows = results[2] as List<CashflowPointModel>;
        spendingLimit = results[3] as SpendingLimitModel;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load data: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String _resolveDisplayType(TransactionHistoryModel item) {
    final rawType = item.type.trim().toLowerCase();
    final amount = item.amount;

    const debitTypes = {
      'debit',
      'orderpayment',
      'tryon',
      'airecommendation',
      'packagepurchase',
      'withdraw',
      'event_entry_fee_paid',
      'system_fee_payment',
      'escrow_hold',
    };

    const creditTypes = {
      'credit',
      'topup',
      'orderrefund',
      'refund',
      'prize_reward',
      'event_refund',
      'event_cancel_refund',
      'event_reject_refund',
      'event_revenue_locked',
      'event_revenue_released',
      'system_fee_revenue',
    };

    if (debitTypes.contains(rawType)) {
      return 'Debit';
    }

    if (creditTypes.contains(rawType)) {
      return 'Credit';
    }

    if (amount < 0) {
      return 'Debit';
    }

    if (amount > 0) {
      return 'Credit';
    }

    return 'Debit';
  }

  String _resolveDetailDisplayType(dynamic detail) {
    final rawType = (detail.type ?? '').toString().trim().toLowerCase();
    final amount = ((detail.amount ?? 0) as num).toDouble();

    const debitTypes = {
      'debit',
      'orderpayment',
      'tryon',
      'airecommendation',
      'packagepurchase',
      'withdraw',
      'event_entry_fee_paid',
      'system_fee_payment',
      'escrow_hold',
    };

    const creditTypes = {
      'credit',
      'topup',
      'orderrefund',
      'refund',
      'prize_reward',
      'event_refund',
      'event_cancel_refund',
      'event_reject_refund',
      'event_revenue_locked',
      'event_revenue_released',
      'system_fee_revenue',
    };

    if (debitTypes.contains(rawType)) {
      return 'Debit';
    }

    if (creditTypes.contains(rawType)) {
      return 'Credit';
    }

    if (amount < 0) {
      return 'Debit';
    }

    if (amount > 0) {
      return 'Credit';
    }

    return 'Debit';
  }

  double _resolveDisplayAmount(double value) {
    return value.abs();
  }

  Color _typeColor(String type) {
    if (type.toLowerCase() == 'credit') {
      return const Color(0xFF10B981);
    }

    if (type.toLowerCase() == 'debit') {
      return const Color(0xFFEF4444);
    }

    return const Color(0xFF6B7280);
  }

  IconData _typeIcon(String type) {
    if (type.toLowerCase() == 'credit') {
      return Icons.arrow_downward_rounded;
    }

    return Icons.arrow_upward_rounded;
  }

  Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'success':
      case 'completed':
        return const Color(0xFF10B981);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'failed':
        return const Color(0xFFEF4444);
      case 'cancelled':
      case 'canceled':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _mapReferenceType(String value) {
    switch (value.trim()) {
      case 'TopUp':
        return 'Top up';
      case 'OrderPayment':
        return 'Order payment';
      case 'OrderRefund':
        return 'Order refund';
      case 'TryOn':
        return 'AI try-on';
      case 'AIRecommendation':
        return 'Smart recommendation';
      case 'Event':
        return 'Event';
      case 'EventReward':
        return 'Event reward';
      case 'Event_Reject':
        return 'Event reject';
      default:
        return value.trim().isEmpty ? 'Other' : value;
    }
  }

  String _mapTransactionType(String value) {
    switch (value.trim()) {
      case 'Credit':
        return 'Income';
      case 'Debit':
        return 'Expense';
      case 'TopUp':
        return 'Wallet top up';
      case 'OrderPayment':
        return 'Order payment';
      case 'OrderRefund':
        return 'Order refund';
      case 'TryOn':
        return 'AI try-on payment';
      case 'AIRecommendation':
        return 'Smart recommendation payment';
      case 'Event_Entry_Fee_Paid':
        return 'Event entry fee';
      case 'Event_Revenue_Locked':
        return 'Event revenue locked';
      case 'Event_Revenue_Released':
        return 'Event revenue released';
      case 'System_Fee_Payment':
        return 'Event system fee';
      case 'System_Fee_Revenue':
        return 'System fee revenue';
      case 'Escrow_Hold':
        return 'Event prize escrow';
      case 'Prize_Reward':
        return 'Event prize reward';
      case 'Event_Refund':
        return 'Event refund';
      case 'Event_Cancel_Refund':
        return 'Event cancellation refund';
      case 'Event_Reject_Refund':
        return 'Rejected event refund';
      default:
        return value.trim().isEmpty ? 'Transaction' : value;
    }
  }

  String _mapStatus(String value) {
    switch (value.trim().toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'success':
      case 'completed':
        return 'Success';
      case 'failed':
        return 'Failed';
      case 'cancelled':
      case 'canceled':
        return 'Cancelled';
      default:
        return value;
    }
  }

  List<TransactionHistoryModel> get _displayTransactions {
    return transactions.where((item) {
      final displayType = _resolveDisplayType(item);

      if (selectedType.isNotEmpty && displayType != selectedType) {
        return false;
      }

      return true;
    }).toList();
  }

  String _shortPeriod(String period) {
    final digits =
    RegExp(r'\d+').allMatches(period).map((e) => e.group(0)).toList();

    if (digits.isNotEmpty) {
      return digits.last ?? period;
    }

    return period;
  }

  Widget _buildPageTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expense Management',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Track wallet spending, income, and transaction history.',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildHeroCard() {
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
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
            Color(0xFF334155),
          ],
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
              const Icon(
                Icons.calendar_month_rounded,
                color: Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Month $selectedMonth/$selectedYear',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.12),
                  ),
                ),
                child: Text(
                  '${summary?.totalTransactions ?? 0} transactions',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Current balance',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
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
                  fontWeight: FontWeight.w900,
                ),
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
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildHeroMiniInfo(
                  icon: Icons.arrow_downward_rounded,
                  label: 'Income',
                  value: formatMoney(totalIncome),
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildHeroMiniInfo(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Expense',
                  value: formatMoney(totalExpense),
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildHeroMiniInfo(
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

  Widget _buildHeroMiniInfo({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
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
            child: Icon(
              icon,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 22,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthYearPicker() {
    final months = List.generate(12, (index) => index + 1);
    final currentYear = DateTime.now().year;
    final years = List.generate(5, (index) => currentYear - 2 + index);

    return _buildSectionCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: _buildDropdown(
              value: selectedMonth.toString(),
              hint: 'Month',
              items: months.map((e) => e.toString()).toList(),
              labelBuilder: (v) => 'Month $v',
              onChanged: (v) {
                if (v == null) {
                  return;
                }

                setState(() {
                  selectedMonth = int.parse(v);
                });

                _loadData();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildDropdown(
              value: selectedYear.toString(),
              hint: 'Year',
              items: years.map((e) => e.toString()).toList(),
              labelBuilder: (v) => v,
              onChanged: (v) {
                if (v == null) {
                  return;
                }

                setState(() {
                  selectedYear = int.parse(v);
                });

                _loadData();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryMetricCard(
            title: 'Income',
            value: formatAdaptiveMoney(
              summary?.totalIncome ?? 0,
              compact: true,
            ),
            icon: Icons.south_west_rounded,
            color: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryMetricCard(
            title: 'Expense',
            value: formatAdaptiveMoney(
              summary?.totalExpense ?? 0,
              compact: true,
            ),
            icon: Icons.north_east_rounded,
            color: const Color(0xFFEF4444),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return _buildSectionCard(
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
            child: Icon(
              icon,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 22,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetCard() {
    final net = summary?.netAmount ?? 0;
    final isPositive = net >= 0;

    return _buildSectionCard(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (isPositive
                  ? const Color(0xFF2563EB)
                  : const Color(0xFFF59E0B))
                  .withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isPositive ? Icons.insights_rounded : Icons.show_chart_rounded,
              color: isPositive
                  ? const Color(0xFF2563EB)
                  : const Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Net cashflow',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 24,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatMoney(net),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
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
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateLimitButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isUpdatingSpendingLimit ? null : _showUpdateSpendingLimitSheet,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isUpdatingSpendingLimit) ...[
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
              ] else ...[
                const Icon(
                  Icons.edit_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
              ],
              const Text(
                'Update',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpendingLimitCard() {
    final data = spendingLimit;

    if (data == null) {
      return _buildSectionCard(
        child: _buildEmptyState('No spending limit data available.'),
      );
    }

    final hasLimit =
        data.monthlySpendingLimit != null && data.monthlySpendingLimit! > 0;

    final progress = hasLimit ? (data.usedPercent / 100).clamp(0.0, 1.0) : 0.0;

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

    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Spending limit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              _buildUpdateLimitButton(),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Maximum amount you can spend this month. New spending will be blocked when the limit is exceeded.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildLimitMetric(
                  label: 'Monthly limit',
                  value: hasLimit
                      ? formatMoney(data.monthlySpendingLimit!)
                      : 'Not set',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLimitMetric(
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
                child: _buildLimitMetric(
                  label: 'Remaining',
                  value: hasLimit ? formatMoney(data.remainingAmount) : '--',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLimitMetric(
                  label: 'Used',
                  value:
                  hasLimit ? '${data.usedPercent.toStringAsFixed(1)}%' : '--',
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
              _buildStatusPill(
                text: statusText,
                color: statusColor,
              ),
              _buildNeutralPill('Hard limit enabled'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLimitMetric({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF111827),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required String hint,
    required List<String> items,
    required String Function(String value) labelBuilder,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(16),
          hint: Text(
            hint,
            style: const TextStyle(fontSize: 14),
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                labelBuilder(item),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.filter_alt_outlined,
            title: 'Transaction filters',
            subtitle: 'Search and narrow down your wallet activities.',
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _keywordController,
            decoration: InputDecoration(
              hintText: 'Search by transaction description...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _keywordController.text.trim().isNotEmpty
                  ? IconButton(
                onPressed: () {
                  _keywordController.clear();
                  setState(() {});
                  _loadData();
                },
                icon: const Icon(Icons.close_rounded),
              )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFE5E7EB),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFE5E7EB),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF6366F1),
                  width: 1.2,
                ),
              ),
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _loadData(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  value: selectedType,
                  hint: 'Type',
                  items: const ['', 'Credit', 'Debit'],
                  labelBuilder: (v) {
                    if (v.isEmpty) {
                      return 'All';
                    }

                    return v == 'Credit' ? 'Income' : 'Expense';
                  },
                  onChanged: (v) {
                    setState(() {
                      selectedType = v ?? '';
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDropdown(
                  value: selectedStatus,
                  hint: 'Status',
                  items: const [
                    '',
                    'Pending',
                    'Success',
                    'Failed',
                    'Cancelled',
                  ],
                  labelBuilder: (v) => v.isEmpty ? 'All' : _mapStatus(v),
                  onChanged: (v) {
                    setState(() {
                      selectedStatus = v ?? '';
                    });

                    _loadData();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildDropdown(
            value: selectedReferenceType,
            hint: 'Reference type',
            items: const [
              '',
              'TopUp',
              'OrderPayment',
              'OrderRefund',
              'TryOn',
              'AIRecommendation',
              'Event',
            ],
            labelBuilder: (v) {
              if (v.isEmpty) {
                return 'All reference types';
              }

              return _mapReferenceType(v);
            },
            onChanged: (v) {
              setState(() {
                selectedReferenceType = v ?? '';
              });

              _loadData();
            },
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  selectedType = '';
                  selectedStatus = '';
                  selectedReferenceType = '';
                  _keywordController.clear();
                });

                _loadData();
              },
              icon: const Icon(
                Icons.refresh_rounded,
                size: 18,
              ),
              label: const Text(
                'Reset filters',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashflowChartSection() {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.show_chart_rounded,
            title: 'Cashflow chart',
            subtitle: 'Income and expense during the selected month.',
          ),
          const SizedBox(height: 18),
          if (cashflows.isEmpty)
            _buildEmptyState('No cashflow data available.')
          else
            Column(
              children: [
                SizedBox(
                  height: 220,
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _calcIntervalForChart(),
                        getDrawingHorizontalLine: (value) {
                          return const FlLine(
                            color: Color(0xFFE5E7EB),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            interval: _calcIntervalForChart(),
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Text(
                                  formatCompactMoney(value),
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: Color(0xFF6B7280),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            interval: cashflows.length > 12 ? 2 : 1,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();

                              if (index < 0 || index >= cashflows.length) {
                                return const SizedBox.shrink();
                              }

                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  _shortPeriod(cashflows[index].period),
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: Color(0xFF6B7280),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineTouchData: LineTouchData(
                        handleBuiltInTouches: true,
                        touchTooltipData: LineTouchTooltipData(
                          tooltipRoundedRadius: 14,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final isIncome = spot.barIndex == 0;

                              return LineTooltipItem(
                                '${isIncome ? 'Income' : 'Expense'}\n${formatMoney(spot.y)}',
                                TextStyle(
                                  color: isIncome
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: true,
                          barWidth: 3,
                          color: const Color(0xFF10B981),
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color(0xFF10B981).withOpacity(0.10),
                          ),
                          spots: cashflows.asMap().entries.map((entry) {
                            return FlSpot(
                              entry.key.toDouble(),
                              entry.value.income,
                            );
                          }).toList(),
                        ),
                        LineChartBarData(
                          isCurved: true,
                          barWidth: 3,
                          color: const Color(0xFFEF4444),
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color(0xFFEF4444).withOpacity(0.10),
                          ),
                          spots: cashflows.asMap().entries.map((entry) {
                            return FlSpot(
                              entry.key.toDouble(),
                              entry.value.expense,
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Row(
                  children: [
                    _ChartLegend(
                      color: Color(0xFF10B981),
                      label: 'Income',
                    ),
                    SizedBox(width: 16),
                    _ChartLegend(
                      color: Color(0xFFEF4444),
                      label: 'Expense',
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  double _calcIntervalForChart() {
    if (cashflows.isEmpty) {
      return 1;
    }

    double maxValue = 0;

    for (final item in cashflows) {
      if (item.income > maxValue) {
        maxValue = item.income;
      }

      if (item.expense > maxValue) {
        maxValue = item.expense;
      }
    }

    if (maxValue <= 100000) {
      return 20000;
    }

    if (maxValue <= 500000) {
      return 100000;
    }

    if (maxValue <= 1000000) {
      return 200000;
    }

    if (maxValue <= 5000000) {
      return 1000000;
    }

    if (maxValue <= 10000000) {
      return 2000000;
    }

    return maxValue / 4;
  }

  Widget _buildTransactionList() {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.receipt_long_rounded,
            title: 'Transaction history',
            subtitle: '${_displayTransactions.length} recent transactions',
          ),
          const SizedBox(height: 14),
          if (_displayTransactions.isEmpty)
            _buildEmptyState('No transactions found.')
          else
            ..._displayTransactions.map((item) {
              final displayType = _resolveDisplayType(item);
              final bool isCredit = displayType == 'Credit';
              final Color amountColor = _typeColor(displayType);
              final Color statusColor = _statusColor(item.status);

              return InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _showTransactionDetail(item.transactionId),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                    ),
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
                            child: Icon(
                              _typeIcon(displayType),
                              color: amountColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _mapTransactionType(item.type),
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildStatusPill(
                                      text: _mapStatus(item.status),
                                      color: statusColor,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildInfoPill(
                                      icon: Icons.schedule_rounded,
                                      text: _formatVietnamTime(item.createdAt),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.description ?? 'No description',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildInfoPill(
                        icon: Icons.tag_rounded,
                        text: item.transactionCode,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildBalanceMini(
                                label: 'Before',
                                value: formatAdaptiveMoney(
                                  item.balanceBefore,
                                  compact: true,
                                ),
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 30,
                              color: const Color(0xFFE5E7EB),
                            ),
                            Expanded(
                              child: _buildBalanceMini(
                                label: 'After',
                                value: formatAdaptiveMoney(
                                  item.balanceAfter,
                                  compact: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${isCredit ? '+' : '-'} ${formatAdaptiveMoney(_resolveDisplayAmount(item.amount), compact: true)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: amountColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Details',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildBalanceMini({
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          SizedBox(
            height: 18,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPill({
    required IconData icon,
    required String text,
    Color color = const Color(0xFF6B7280),
    Color backgroundColor = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withOpacity(0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill({
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildNeutralPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF374151),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.inbox_rounded,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            size: 20,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showTransactionDetail(int transactionId) async {
    if (_isLoadingTransactionDetail) {
      return;
    }

    _isLoadingTransactionDetail = true;

    try {
      final detail = await _expenseService.getTransactionDetail(transactionId);

      if (!mounted) {
        return;
      }

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) {
          final displayType = _resolveDetailDisplayType(detail);
          final isCredit = displayType == 'Credit';
          final typeColor = _typeColor(displayType);
          final detailType = (detail.type ?? '').toString();

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.72,
            minChildSize: 0.45,
            maxChildSize: 0.92,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
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
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            _typeIcon(displayType),
                            color: typeColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                detail.displayTitle ??
                                    _mapTransactionType(detailType),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                detail.transactionCode,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            typeColor.withOpacity(0.10),
                            typeColor.withOpacity(0.04),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Text(
                            isCredit ? 'Income' : 'Expense',
                            style: TextStyle(
                              fontSize: 13,
                              color: typeColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 32,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${isCredit ? '+' : '-'} ${formatMoney(_resolveDisplayAmount((detail.amount as num).toDouble()))}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: typeColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildDetailGroup(
                      title: 'General information',
                      children: [
                        _detailRow('Type', _mapTransactionType(detailType)),
                        _detailRow('Direction', displayType),
                        _detailRow(
                          'Reference type',
                          _mapReferenceType(detail.referenceType),
                        ),
                        _detailRow('Status', _mapStatus(detail.status)),
                        _detailRow(
                          'Time',
                          _formatVietnamTime(detail.createdAt),
                        ),
                        _detailRow('Description', detail.description ?? '--'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildDetailGroup(
                      title: 'Balance changes',
                      children: [
                        _detailRow(
                          'Amount',
                          formatMoney(
                            _resolveDisplayAmount(
                              (detail.amount as num).toDouble(),
                            ),
                          ),
                        ),
                        _detailRow(
                          'Balance before',
                          formatMoney(detail.balanceBefore),
                        ),
                        _detailRow(
                          'Balance after',
                          formatMoney(detail.balanceAfter),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load transaction details: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      _isLoadingTransactionDetail = false;
    }
  }

  Widget _buildDetailGroup({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showUpdateSpendingLimitSheet() async {
    final selectedLimit = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _SpendingLimitSheet(
          initialLimit: spendingLimit?.monthlySpendingLimit,
          moneyFormat: _moneyFormat,
        );
      },
    );

    if (!mounted || selectedLimit == null) {
      return;
    }

    await _updateSpendingLimit(
      monthlySpendingLimit: selectedLimit,
      isHardSpendingLimit: true,
      spendingWarningThresholdPercent: 100,
    );
  }

  Future<void> _updateSpendingLimit({
    required double? monthlySpendingLimit,
    required bool isHardSpendingLimit,
    required double spendingWarningThresholdPercent,
  }) async {
    try {
      setState(() {
        isUpdatingSpendingLimit = true;
      });

      await _expenseService.updateMySpendingLimit(
        UpdateSpendingLimitRequest(
          monthlySpendingLimit: monthlySpendingLimit,
          isHardSpendingLimit: isHardSpendingLimit,
          spendingWarningThresholdPercent: spendingWarningThresholdPercent,
        ),
      );

      await _loadData();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Spending limit updated successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update spending limit: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isUpdatingSpendingLimit = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF3F6FB),
        foregroundColor: const Color(0xFF111827),
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          'EXPENSES',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 17,
            letterSpacing: 0.4,
          ),
        ),
        actions: [
          IconButton(
            onPressed: isLoading ? null : _loadData,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: isLoading
            ? const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF111827),
          ),
        )
            : RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFF111827),
          backgroundColor: Colors.white,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _buildPageTitle(),
              _buildHeroCard(),
              const SizedBox(height: 16),
              _buildMonthYearPicker(),
              const SizedBox(height: 16),
              _buildSummaryGrid(),
              const SizedBox(height: 12),
              _buildNetCard(),
              const SizedBox(height: 16),
              _buildSpendingLimitCard(),
              const SizedBox(height: 16),
              _buildFilterSection(),
              const SizedBox(height: 16),
              _buildCashflowChartSection(),
              const SizedBox(height: 16),
              _buildTransactionList(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpendingLimitSheet extends StatefulWidget {
  final double? initialLimit;
  final NumberFormat moneyFormat;

  const _SpendingLimitSheet({
    required this.initialLimit,
    required this.moneyFormat,
  });

  @override
  State<_SpendingLimitSheet> createState() => _SpendingLimitSheetState();
}

class _SpendingLimitSheetState extends State<_SpendingLimitSheet> {
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
    if (number == null) {
      return;
    }

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
      setState(() {
        _errorText = 'Please enter a monthly limit.';
      });
      return;
    }

    final limit = double.tryParse(raw);

    if (limit == null || limit <= 0) {
      setState(() {
        _errorText = 'Monthly limit must be greater than 0.';
      });
      return;
    }

    Navigator.of(context).pop(limit);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
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
                const Text(
                  'Update spending limit',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This hard limit blocks new wallet spending when your monthly spending reaches the limit.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFC7D2FE),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: Color(0xFF4F46E5),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Hard limit is always enabled. Warning threshold is not used.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3730A3),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _limitController,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    if (_errorText != null) {
                      setState(() {
                        _errorText = null;
                      });
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFFE5E7EB),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFFE5E7EB),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFF4F46E5),
                      ),
                    ),
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
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Save limit',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
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

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegend({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
