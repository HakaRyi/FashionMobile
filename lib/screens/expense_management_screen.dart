import 'package:fl_chart/fl_chart.dart';
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
  String selectedType = '';
  String selectedStatus = '';
  String selectedReferenceType = '';

  ExpenseSummaryModel? summary;
  List<TransactionHistoryModel> transactions = [];
  List<ExpenseByReferenceTypeModel> expenseByType = [];
  List<CashflowPointModel> cashflows = [];

  final List<Color> _chartColors = const [
    Color(0xFF4F46E5),
    Color(0xFF06B6D4),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
  ];

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

  String formatCompactMoney(double value) {
    if (value.abs() >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    }
    if (value.abs() >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return _moneyFormat.format(value);
  }

  String formatShortMoney(double value) {
    final abs = value.abs();

    if (abs >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)} tỷ';
    }
    if (abs >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)} triệu';
    }
    if (abs >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return '${_moneyFormat.format(value)} đ';
  }

  String formatAdaptiveMoney(double value, {bool compact = false}) {
    if (compact) return formatShortMoney(value);
    return formatMoney(value);
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() => isLoading = true);
    }

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
        referenceType:
        selectedReferenceType.isEmpty ? null : selectedReferenceType,
        keyword: _keywordController.text,
      );

      final fromDate = DateTime(selectedYear, selectedMonth, 1);
      final toDate = DateTime(selectedYear, selectedMonth + 1, 0);

      final cashflowResult = await _expenseService.getCashflow(
        fromDate: fromDate,
        toDate: toDate,
        groupBy: 'day',
      );

      if (!mounted) return;
      setState(() {
        summary = summaryResult;
        expenseByType = expenseTypeResult;
        transactions =
        (transactionResult['items'] as List<TransactionHistoryModel>);
        cashflows = cashflowResult;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải dữ liệu: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Color _typeColor(String type) {
    if (type.toLowerCase() == 'credit') return const Color(0xFF10B981);
    if (type.toLowerCase() == 'debit') return const Color(0xFFEF4444);
    return Colors.grey;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Success':
        return const Color(0xFF10B981);
      case 'Pending':
        return const Color(0xFFF59E0B);
      case 'Failed':
        return const Color(0xFFEF4444);
      case 'Cancelled':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF6B7280);
    }
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

  String _shortPeriod(String period) {
    final digits = RegExp(
      r'\d+',
    ).allMatches(period).map((e) => e.group(0)).toList();
    if (digits.isNotEmpty) return digits.last ?? period;
    return period;
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.28),
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
                Icons.account_balance_wallet_rounded,
                color: Colors.white70,
              ),
              const SizedBox(width: 8),
              Text(
                'Tháng $selectedMonth/$selectedYear',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
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
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: Text(
                  '${summary?.totalTransactions ?? 0} giao dịch',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Số dư hiện tại',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 38,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatMoney(currentBalance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Đang giữ: ${formatMoney(lockedBalance)}',
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
                  label: 'Tiền vào',
                  value: formatMoney(totalIncome),
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildHeroMiniInfo(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Tiền ra',
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
            label: 'Dòng tiền ròng',
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

  Widget _buildSummaryGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryMetricCard(
            title: 'Tiền vào',
            value: formatAdaptiveMoney(summary?.totalIncome ?? 0, compact: true),
            icon: Icons.south_west_rounded,
            color: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryMetricCard(
            title: 'Tiền ra',
            value: formatAdaptiveMoney(summary?.totalExpense ?? 0, compact: true),
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
                        fontWeight: FontWeight.w800,
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color:
              (isPositive
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
                  'Dòng tiền ròng',
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
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: (isPositive
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFFFEDD5)),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isPositive ? 'Tích cực' : 'Giảm',
              style: TextStyle(
                color: isPositive
                    ? const Color(0xFF166534)
                    : const Color(0xFF9A3412),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
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
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(16),
          hint: Text(hint, style: const TextStyle(fontSize: 14)),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(labelBuilder(item), overflow: TextOverflow.ellipsis),
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
          const Text(
            'Bộ lọc giao dịch',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _keywordController,
            decoration: InputDecoration(
              hintText: 'Tìm theo mô tả giao dịch...',
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
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
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
                  items: const [
                    '',
                    'Pending',
                    'Success',
                    'Failed',
                    'Cancelled',
                  ],
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

  Widget _buildCashflowChartSection() {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Biểu đồ dòng tiền',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Thu và chi trong tháng đã chọn',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 18),
          if (cashflows.isEmpty)
            _buildEmptyState('Chưa có dữ liệu cashflow.')
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
                          return FlLine(
                            color: const Color(0xFFE5E7EB),
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
                                '${isIncome ? 'Thu' : 'Chi'}\n${formatMoney(spot.y)}',
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
                          spots: cashflows.asMap().entries.map((e) {
                            return FlSpot(e.key.toDouble(), e.value.income);
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
                          spots: cashflows.asMap().entries.map((e) {
                            return FlSpot(e.key.toDouble(), e.value.expense);
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: const [
                    _ChartLegend(color: Color(0xFF10B981), label: 'Thu nhập'),
                    SizedBox(width: 16),
                    _ChartLegend(color: Color(0xFFEF4444), label: 'Chi tiêu'),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  double _calcIntervalForChart() {
    if (cashflows.isEmpty) return 1;
    double maxValue = 0;
    for (final item in cashflows) {
      if (item.income > maxValue) maxValue = item.income;
      if (item.expense > maxValue) maxValue = item.expense;
    }
    if (maxValue <= 100000) return 20000;
    if (maxValue <= 500000) return 100000;
    if (maxValue <= 1000000) return 200000;
    if (maxValue <= 5000000) return 1000000;
    if (maxValue <= 10000000) return 2000000;
    return maxValue / 4;
  }

  Widget _buildExpenseByTypeSection() {
    final double total = expenseByType.fold<double>(
      0.0,
          (sum, e) => sum + e.amount,
    );

    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chi tiêu theo nhóm',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tỷ trọng từng nghiệp vụ trong tháng',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          if (expenseByType.isEmpty)
            _buildEmptyState('Chưa có dữ liệu chi tiêu.')
          else ...[
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 48,
                  sectionsSpace: 3,
                  pieTouchData: PieTouchData(enabled: true),
                  sections: expenseByType.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final double percent = total == 0
                        ? 0.0
                        : (item.amount / total) * 100;
                    final color = _chartColors[index % _chartColors.length];

                    return PieChartSectionData(
                      value: item.amount,
                      color: color,
                      radius: 52,
                      title: percent >= 8
                          ? '${percent.toStringAsFixed(0)}%'
                          : '',
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 18),
            ...expenseByType.asMap().entries.map((entry) {
              final int index = entry.key;
              final item = entry.value;
              final double percent = total == 0 ? 0.0 : item.amount / total;
              final Color color = _chartColors[index % _chartColors.length];

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _mapReferenceType(item.referenceType),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                        Text(
                          '${(percent * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: percent,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            formatAdaptiveMoney(item.amount, compact: true),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${item.transactionCount} giao dịch',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lịch sử giao dịch',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${transactions.length} giao dịch gần nhất',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 14),
          if (transactions.isEmpty)
            _buildEmptyState('Không có giao dịch nào.')
          else
            ...transactions.map((item) {
              final bool isCredit = item.type.toLowerCase() == 'credit';
              final Color amountColor = _typeColor(item.type);
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
                            child: Icon(
                              isCredit
                                  ? Icons.south_west_rounded
                                  : Icons.north_east_rounded,
                              color: amountColor,
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
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        _mapStatus(item.status),
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                    _buildInfoPill(
                                      icon: Icons.schedule_rounded,
                                      text: DateFormat(
                                        'dd/MM/yyyy HH:mm',
                                      ).format(item.createdAt),
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
                        item.description ?? 'Không có mô tả',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildInfoPill(
                            icon: Icons.tag_rounded,
                            text: item.transactionCode,
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
                              child: _buildBalanceMini(
                                label: 'Trước',
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
                                label: 'Sau',
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
                              '${isCredit ? '+' : '-'} ${formatAdaptiveMoney(item.amount, compact: true)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
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
                                  'Chi tiết',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
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
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildBalanceMini({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Số dư $label',
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
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPill({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF6B7280)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF374151),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
              child: const Icon(Icons.inbox_rounded, color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 12),
            Text(
              text,
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

  Future<void> _showTransactionDetail(int transactionId) async {
    try {
      final detail = await _expenseService.getTransactionDetail(transactionId);

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) {
          final isCredit = detail.type.toLowerCase() == 'credit';
          final typeColor = _typeColor(detail.type);

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.72,
            minChildSize: 0.45,
            maxChildSize: 0.92,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                            isCredit
                                ? Icons.south_west_rounded
                                : Icons.north_east_rounded,
                            color: typeColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                detail.displayTitle ?? 'Chi tiết giao dịch',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
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
                            isCredit ? 'Tiền vào' : 'Tiền ra',
                            style: TextStyle(
                              fontSize: 13,
                              color: typeColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 32,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${isCredit ? '+' : '-'} ${formatMoney(detail.amount)}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
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
                      title: 'Thông tin chung',
                      children: [
                        _detailRow('Loại', detail.type),
                        _detailRow(
                          'Nghiệp vụ',
                          _mapReferenceType(detail.referenceType),
                        ),
                        _detailRow('Trạng thái', _mapStatus(detail.status)),
                        _detailRow(
                          'Thời gian',
                          DateFormat(
                            'dd/MM/yyyy HH:mm',
                          ).format(detail.createdAt),
                        ),
                        _detailRow('Mô tả', detail.description ?? '--'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildDetailGroup(
                      title: 'Biến động số dư',
                      children: [
                        _detailRow('Số tiền', formatMoney(detail.amount)),
                        _detailRow(
                          'Số dư trước',
                          formatMoney(detail.balanceBefore),
                        ),
                        _detailRow(
                          'Số dư sau',
                          formatMoney(detail.balanceAfter),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildDetailGroup(
                      title: 'Nguồn tham chiếu',
                      children: [
                        _detailRow('Nguồn', detail.sourceName ?? '--'),
                        _detailRow('Mã nguồn', detail.sourceCode ?? '--'),
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không tải được chi tiết giao dịch: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
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
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                height: 1.35,
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
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF3F6FB),
        foregroundColor: const Color(0xFF111827),
        title: const Text(
          'Quản lý chi tiêu',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _buildHeroCard(),
              const SizedBox(height: 16),
              _buildSummaryGrid(),
              const SizedBox(height: 12),
              _buildNetCard(),
              const SizedBox(height: 16),
              _buildFilterSection(),
              const SizedBox(height: 16),
              _buildCashflowChartSection(),
              const SizedBox(height: 16),
              _buildExpenseByTypeSection(),
              const SizedBox(height: 16),
              _buildTransactionList(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegend({required this.color, required this.label});

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
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}