// lib/screens/expense_management_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/cashflow_point_model.dart';
import '../models/expense_summary_model.dart';
import '../models/spending_limit_model.dart';
import '../models/transaction_history_model.dart';
import '../services/expense_service.dart';
import '../utils/app_toast.dart';
import '../utils/expense_formatters.dart';
import '../widgets/expense/expense_hero_card.dart';
import '../widgets/expense/expense_cashflow_chart.dart';
import '../widgets/expense/expense_transaction_list.dart';
import '../widgets/expense/expense_common_widgets.dart';

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

  DateTimeRange? selectedDateRange;

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
    _resetDateRangeToDefault(shouldLoadData: false);
    _loadData();
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  void _resetDateRangeToDefault({required bool shouldLoadData}) {
    final now = DateTime.now();
    setState(() {
      selectedDateRange = DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: now,
      );
    });
    if (shouldLoadData) {
      _loadData();
    }
  }

  // ─── Data ────────────────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    if (mounted) setState(() => isLoading = true);

    try {
      final fromDate = selectedDateRange?.start ?? DateTime(DateTime.now().year, DateTime.now().month, 1);
      final toDate = selectedDateRange?.end ?? DateTime.now();

      final results = await Future.wait([
        _expenseService.getExpenseSummary(
            fromDate: fromDate, toDate: toDate),
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
            fromDate: fromDate, toDate: toDate, groupBy: 'day'),
        _expenseService.getMySpendingLimit(
            month: fromDate.month, year: fromDate.year),
      ]);

      if (!mounted) return;

      setState(() {
        summary = results[0] as ExpenseSummaryModel;
        final transactionResult = results[1] as Map<String, dynamic>;
        transactions =
        transactionResult['items'] as List<TransactionHistoryModel>;
        cashflows = results[2] as List<CashflowPointModel>;
        spendingLimit = results[3] as SpendingLimitModel;
      });
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(context, 'Failed to load data: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

// ─── Filtered transactions ────────────────────────────────────────────────────

  List<TransactionHistoryModel> get _displayTransactions {
    final keyword = _keywordController.text.trim().toLowerCase();

    return transactions.where((item) {
      final dt = resolveDisplayType(item.type, item.amount);
      if (selectedType.isNotEmpty && dt != selectedType) return false;

      if (keyword.isNotEmpty) {
        final descriptionMatches = (item.description ?? '').toLowerCase().contains(keyword);
        final orderCodeMatches = (item.orderCode ?? '').toLowerCase().contains(keyword);

        if (!descriptionMatches && !orderCodeMatches) return false;
      }

      return true;
    }).toList();
  }

  // ─── Transaction detail sheet ─────────────────────────────────────────────────

  Future<void> _showTransactionDetail(int transactionId) async {
    if (_isLoadingTransactionDetail) return;
    _isLoadingTransactionDetail = true;

    try {
      final detail = await _expenseService.getTransactionDetail(transactionId);
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) {
          final displayType =
          resolveDisplayType((detail.type ?? '').toString(),
              ((detail.amount ?? 0) as num).toDouble());
          final isCredit = displayType == 'Credit';
          final tColor = typeColor(displayType);
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
                  borderRadius:
                  BorderRadius.vertical(top: Radius.circular(28)),
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
                            color: tColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(typeIcon(displayType), color: tColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                detail.displayTitle ??
                                    mapTransactionType(detailType),
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF111827)),
                              ),
                              const SizedBox(height: 4),
                              Text(detail.transactionCode,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF6B7280),
                                      fontWeight: FontWeight.w600)),
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
                            tColor.withOpacity(0.10),
                            tColor.withOpacity(0.04),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Text(isCredit ? 'Income' : 'Expense',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: tColor,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 32,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${isCredit ? '+' : '-'} ${formatMoney(((detail.amount as num).toDouble()).abs())}',
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: tColor),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildDetailGroup('General information', [
                      _detailRow('Type', mapTransactionType(detailType)),
                      _detailRow('Direction', displayType),
                      _detailRow('Reference type',
                          mapReferenceType(detail.referenceType)),
                      if (detail.orderCode != null && detail.orderCode!.isNotEmpty)
                        _detailRow('Order code', detail.orderCode!),

                      _detailRow('Status', mapStatus(detail.status)),
                      _detailRow('Time', formatVietnamTime(detail.createdAt)),
                      _detailRow(
                          'Description', detail.description ?? '--'),
                    ]),
                    const SizedBox(height: 14),
                    _buildDetailGroup('Balance changes', [
                      _detailRow(
                          'Amount',
                          formatMoney(
                              (detail.amount as num).toDouble().abs())),
                      _detailRow('Balance before',
                          formatMoney(detail.balanceBefore)),
                      _detailRow(
                          'Balance after', formatMoney(detail.balanceAfter)),
                    ]),
                  ],
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(context, 'Failed to load transaction details: $e');
    } finally {
      _isLoadingTransactionDetail = false;
    }
  }

  Widget _buildDetailGroup(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827))),
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
            child: Text(label,
                style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    height: 1.35)),
          ),
        ],
      ),
    );
  }

// ─── Filter section ───────────────────────────────────────────────────────────

  Widget _buildFilterSection() {
    String formatDate(DateTime date) =>
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    final now = DateTime.now();
    final isDefaultRange = selectedDateRange != null &&
        selectedDateRange!.start.year == now.year &&
        selectedDateRange!.start.month == now.month &&
        selectedDateRange!.start.day == 1 &&
        selectedDateRange!.end.year == now.year &&
        selectedDateRange!.end.month == now.month &&
        selectedDateRange!.end.day == now.day;

    final dateLabel = selectedDateRange == null
        ? 'Select date range'
        : '${formatDate(selectedDateRange!.start)}  ➔  ${formatDate(selectedDateRange!.end)}';

    return ExpenseSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ExpenseSectionHeader(
            icon: Icons.filter_alt_outlined,
            title: 'Transaction filters',
            subtitle: 'Search and narrow down your wallet activities.',
          ),
          const SizedBox(height: 14),

          // ── Date range ──────────────────────────────────────────
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              final DateTimeRange? picked = await showDateRangePicker(
                context: context,
                initialDateRange: selectedDateRange,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFF111827),
                      onPrimary: Colors.white,
                      onSurface: Color(0xFF111827),
                    ),
                  ),
                  child: child!,
                ),
              );
              if (picked != null && picked != selectedDateRange) {
                setState(() => selectedDateRange = picked);
                _loadData();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded,
                      color: Color(0xFF111827), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(dateLabel,
                        style: const TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                  ),
                  if (!isDefaultRange && selectedDateRange != null)
                    GestureDetector(
                      onTap: () => _resetDateRangeToDefault(shouldLoadData: true),
                      child: const Icon(Icons.close_rounded,
                          color: Color(0xFFEF4444), size: 20),
                    )
                  else
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: Color(0xFF6B7280), size: 13),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Keyword search ───────────────────────────────────────
          TextField(
            controller: _keywordController,
            decoration: InputDecoration(
              hintText: 'Search by order code or description...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _keywordController.text.trim().isNotEmpty
                  ? IconButton(
                onPressed: () {
                  _keywordController.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.close_rounded),
              )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                  const BorderSide(color: Color(0xFF6366F1), width: 1.2)),
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _loadData(),
          ),
          const SizedBox(height: 10),

          // ── Type dropdown ────────────────────────────────────────
          _buildDropdown(
            value: selectedType,
            hint: 'Type',
            items: const ['', 'Credit', 'Debit'],
            labelBuilder: (v) {
              if (v.isEmpty) return 'All types';
              return v == 'Credit' ? 'Income' : 'Expense';
            },
            onChanged: (v) => setState(() => selectedType = v ?? ''),
          ),
          const SizedBox(height: 10),

          // ── Reference type dropdown ──────────────────────────────
          _buildDropdown(
            value: selectedReferenceType,
            hint: 'Reference type',
            items: const [
              '', 'TopUp', 'OrderPayment', 'OrderRefund',
              'TryOn', 'AIRecommendation', 'Event',
            ],
            labelBuilder: (v) =>
            v.isEmpty ? 'All reference types' : mapReferenceType(v),
            onChanged: (v) {
              setState(() => selectedReferenceType = v ?? '');
              _loadData();
            },
          ),
          const SizedBox(height: 10),

          // ── Reset ────────────────────────────────────────────────
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
                _resetDateRangeToDefault(shouldLoadData: true);
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reset filters',
                  style: TextStyle(fontWeight: FontWeight.w700)),
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
    required String Function(String) labelBuilder,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(16),
          hint: Text(hint, style: const TextStyle(fontSize: 14)),
          items: items
              .map((item) => DropdownMenuItem<String>(
            value: item,
            child: Text(labelBuilder(item),
                overflow: TextOverflow.ellipsis),
          ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDateRangePicker() {
    String formatDate(DateTime date) {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }

    final label = selectedDateRange == null
        ? 'Select date range'
        : '${formatDate(selectedDateRange!.start)}  ➔  ${formatDate(selectedDateRange!.end)}';

    final now = DateTime.now();
    final isDefaultRange = selectedDateRange != null &&
        selectedDateRange!.start.year == now.year &&
        selectedDateRange!.start.month == now.month &&
        selectedDateRange!.start.day == 1 &&
        selectedDateRange!.end.year == now.year &&
        selectedDateRange!.end.month == now.month &&
        selectedDateRange!.end.day == now.day;

    return ExpenseSectionCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final DateTimeRange? picked = await showDateRangePicker(
            context: context,
            initialDateRange: selectedDateRange,
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFF111827),
                    onPrimary: Colors.white,
                    onSurface: Color(0xFF111827),
                  ),
                ),
                child: child!,
              );
            },
          );

          if (picked != null && picked != selectedDateRange) {
            setState(() {
              selectedDateRange = picked;
            });
            _loadData();
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                color: Color(0xFF111827),
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (!isDefaultRange && selectedDateRange != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                  onPressed: () {
                    _resetDateRangeToDefault(shouldLoadData: true);
                  },
                )
              else
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFF6B7280),
                  size: 14,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final displayMonth = selectedDateRange?.start.month ?? DateTime.now().month;
    final displayYear = selectedDateRange?.start.year ?? DateTime.now().year;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF3F6FB),
        foregroundColor: const Color(0xFF111827),
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text('EXPENSES',
            style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 17,
                letterSpacing: 0.4)),
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
            child: CircularProgressIndicator(color: Color(0xFF111827)))
            : RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFF111827),
          backgroundColor: Colors.white,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              // Page title
              Padding(
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
                          color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Expense Management',
                              style: TextStyle(
                                  color: Color(0xFF111827),
                                  fontSize: 21,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.2)),
                          SizedBox(height: 3),
                          Text(
                              'Track wallet spending, income, and transaction history.',
                              style: TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ExpenseHeroCard(
                selectedDateRange: selectedDateRange,
                summary: summary,
              ),
              const SizedBox(height: 16),
              _buildFilterSection(),
              const SizedBox(height: 16),
              ExpenseCashflowChart(cashflows: cashflows),
              const SizedBox(height: 16),
              ExpenseTransactionList(
                transactions: _displayTransactions,
                onTapDetail: _showTransactionDetail,
              ),
            ],
          ),
        ),
      ),
    );
  }
}