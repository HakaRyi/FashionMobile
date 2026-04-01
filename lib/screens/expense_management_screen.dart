import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/cashflow_point_model.dart';
import '../models/expense_by_reference_type_model.dart';
import '../models/expense_summary_model.dart';
import '../models/transaction_detail_model.dart';
import '../models/transaction_history_model.dart';
import '../services/expense_service.dart';

class ExpenseManagementScreen extends StatefulWidget {
  const ExpenseManagementScreen({super.key});

  @override
  State<ExpenseManagementScreen> createState() => _ExpenseManagementScreenState();
}

class _ExpenseManagementScreenState extends State<ExpenseManagementScreen> {
  final ExpenseService _expenseService = ExpenseService();
  final NumberFormat _moneyFormat = NumberFormat('#,###', 'vi_VN');
  final TextEditingController _keywordController = TextEditingController();

  late int selectedMonth;
  late int selectedYear;

  bool isLoading = true;
  String selectedType = '';
  String selectedStatus = '';
  String selectedReferenceType = '';

  ExpenseSummaryModel? summary;
  List<TransactionHistoryModel> transactions = [];
  List<ExpenseByReferenceTypeModel> expenseByType = [];
  List<CashflowPointModel> cashflows = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedMonth = now.month;
    selectedYear = now.year;
    _loadData();
  }

  String formatMoney(double value) {
    return '${_moneyFormat.format(value)} đ';
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    try {
      final summaryResult = await _expenseService.getExpenseSummary(
        month: selectedMonth,
        year: selectedYear,
      );

      final expenseTypeResult = await _expenseService.getExpenseByReferenceType(
        month: selectedMonth,
        year: selectedYear,
        type: 'Debit',
      );

      final transactionResult = await _expenseService.getMyTransactions(
        page: 1,
        pageSize: 30,
        type: selectedType.isEmpty ? null : selectedType,
        status: selectedStatus.isEmpty ? null : selectedStatus,
        referenceType: selectedReferenceType.isEmpty ? null : selectedReferenceType,
        keyword: _keywordController.text,
      );

      final now = DateTime.now();
      final cashflowResult = await _expenseService.getCashflow(
        fromDate: DateTime(now.year, now.month, 1),
        toDate: DateTime(now.year, now.month + 1, 0),
        groupBy: 'day',
      );

      setState(() {
        summary = summaryResult;
        expenseByType = expenseTypeResult;
        transactions = (transactionResult['items'] as List<TransactionHistoryModel>);
        cashflows = cashflowResult;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Color _typeColor(String type) {
    if (type.toLowerCase() == 'credit') return Colors.green;
    if (type.toLowerCase() == 'debit') return Colors.red;
    return Colors.grey;
  }

  String _mapReferenceType(String value) {
    switch (value) {
      case 'TopUp':
        return 'Nạp tiền';
      case 'OrderPayment':
        return 'Thanh toán đơn hàng';
      case 'OrderRefund':
        return 'Hoàn tiền đơn hàng';
      case 'TryOn':
        return 'Try-On';
      case 'EventReward':
        return 'Thưởng sự kiện';
      case 'Withdraw':
        return 'Rút tiền';
      case 'Adjustment':
        return 'Điều chỉnh';
      case 'PackagePurchase':
        return 'Mua gói dịch vụ';
      default:
        return value;
    }
  }

  String _mapStatus(String value) {
    switch (value) {
      case 'Pending':
        return 'Đang xử lý';
      case 'Success':
        return 'Thành công';
      case 'Failed':
        return 'Thất bại';
      case 'Cancelled':
        return 'Đã hủy';
      default:
        return value;
    }
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconBg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
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
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(hint),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          TextField(
            controller: _keywordController,
            decoration: InputDecoration(
              hintText: 'Tìm theo mô tả giao dịch...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xFFF6F7FB),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (_) => _loadData(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  value: selectedType,
                  hint: 'Loại tiền',
                  items: const ['', 'Credit', 'Debit'],
                  labelBuilder: (v) {
                    if (v.isEmpty) return 'Tất cả';
                    return v == 'Credit' ? 'Tiền vào' : 'Tiền ra';
                  },
                  onChanged: (v) {
                    setState(() => selectedType = v ?? '');
                    _loadData();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDropdown(
                  value: selectedStatus,
                  hint: 'Trạng thái',
                  items: const ['', 'Pending', 'Success', 'Failed', 'Cancelled'],
                  labelBuilder: (v) => v.isEmpty ? 'Tất cả' : _mapStatus(v),
                  onChanged: (v) {
                    setState(() => selectedStatus = v ?? '');
                    _loadData();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildDropdown(
            value: selectedReferenceType,
            hint: 'Nghiệp vụ',
            items: const [
              '',
              'TopUp',
              'OrderPayment',
              'OrderRefund',
              'TryOn',
              'EventReward',
              'Withdraw',
              'Adjustment',
              'PackagePurchase',
            ],
            labelBuilder: (v) =>
            v.isEmpty ? 'Tất cả nghiệp vụ' : _mapReferenceType(v),
            onChanged: (v) {
              setState(() => selectedReferenceType = v ?? '');
              _loadData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseByType() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chi tiêu theo nhóm',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (expenseByType.isEmpty)
            const Text(
              'Chưa có dữ liệu chi tiêu.',
              style: TextStyle(color: Colors.black54),
            )
          else
            ...expenseByType.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _mapReferenceType(item.referenceType),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      formatMoney(item.amount),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildCashflowSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cashflow tháng này',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (cashflows.isEmpty)
            const Text(
              'Chưa có dữ liệu cashflow.',
              style: TextStyle(color: Colors.black54),
            )
          else
            ...cashflows.take(7).map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.period,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '+ ${formatMoney(item.income)}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '- ${formatMoney(item.expense)}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lịch sử giao dịch',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (transactions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Không có giao dịch nào.',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            )
          else
            ...transactions.map((item) {
              final isCredit = item.type.toLowerCase() == 'credit';

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _showTransactionDetail(item.transactionId),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FD),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _typeColor(item.type).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isCredit ? Icons.south_west : Icons.north_east,
                          color: _typeColor(item.type),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _mapReferenceType(item.referenceType),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.description ?? 'Không có mô tả',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd/MM/yyyy HH:mm').format(item.createdAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black45,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.transactionCode,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black45,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isCredit ? '+' : '-'} ${formatMoney(item.amount)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _typeColor(item.type),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _mapStatus(item.status),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _showTransactionDetail(int transactionId) async {
    try {
      final detail = await _expenseService.getTransactionDetail(transactionId);

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            child: SafeArea(
              child: Wrap(
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    detail.displayTitle ?? 'Chi tiết giao dịch',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _detailRow('Mã giao dịch', detail.transactionCode),
                  _detailRow('Loại', detail.type),
                  _detailRow('Nghiệp vụ', _mapReferenceType(detail.referenceType)),
                  _detailRow('Trạng thái', _mapStatus(detail.status)),
                  _detailRow('Số tiền', formatMoney(detail.amount)),
                  _detailRow('Số dư trước', formatMoney(detail.balanceBefore)),
                  _detailRow('Số dư sau', formatMoney(detail.balanceAfter)),
                  _detailRow('Nguồn', detail.sourceName ?? '--'),
                  _detailRow('Mã nguồn', detail.sourceCode ?? '--'),
                  _detailRow(
                    'Thời gian',
                    DateFormat('dd/MM/yyyy HH:mm').format(detail.createdAt),
                  ),
                  _detailRow('Mô tả', detail.description ?? '--'),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được chi tiết giao dịch: $e')),
      );
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final monthYearText = 'Tháng $selectedMonth/$selectedYear';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          'Quản lý chi tiêu',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF111827), Color(0xFF1F2937)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    monthYearText,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatMoney(summary?.currentBalance ?? 0),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Số dư hiện tại • Đang giữ ${formatMoney(summary?.currentLockedBalance ?? 0)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Tiền vào',
                    value: formatMoney(summary?.totalIncome ?? 0),
                    icon: Icons.arrow_downward_rounded,
                    iconBg: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Tiền ra',
                    value: formatMoney(summary?.totalExpense ?? 0),
                    icon: Icons.arrow_upward_rounded,
                    iconBg: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSummaryCard(
              title: 'Dòng tiền ròng',
              value: formatMoney(summary?.netAmount ?? 0),
              icon: Icons.account_balance_wallet_outlined,
              iconBg: Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildFilterSection(),
            const SizedBox(height: 16),
            _buildExpenseByType(),
            const SizedBox(height: 16),
            _buildCashflowSection(),
            const SizedBox(height: 16),
            _buildTransactionList(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}