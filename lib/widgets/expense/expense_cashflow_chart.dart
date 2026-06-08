// lib/widgets/expense/expense_cashflow_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/cashflow_point_model.dart';
import '../../utils/expense_formatters.dart';
import 'expense_common_widgets.dart';

class ExpenseCashflowChart extends StatelessWidget {
  final List<CashflowPointModel> cashflows;

  const ExpenseCashflowChart({super.key, required this.cashflows});

  String _formatFullDate(String period) {
    try {
      final dateTime = DateTime.parse(period);
      return DateFormat('dd/MM/yy').format(dateTime);
    } catch (e) {
      return period;
    }
  }

  double _calcInterval() {
    if (cashflows.isEmpty) return 1;
    double maxValue = 0;
    for (final item in cashflows) {
      if (item.income > maxValue) maxValue = item.income;
      if (item.expense > maxValue) maxValue = item.expense;
    }
    if (maxValue <= 100000)   return 20000;
    if (maxValue <= 500000)   return 100000;
    if (maxValue <= 1000000)  return 200000;
    if (maxValue <= 5000000)  return 1000000;
    if (maxValue <= 10000000) return 2000000;
    return maxValue / 4;
  }

  double _calcMaxY() {
    double maxValue = 0;
    for (final item in cashflows) {
      if (item.income > maxValue) maxValue = item.income;
      if (item.expense > maxValue) maxValue = item.expense;
    }
    return maxValue <= 0 ? 100000 : maxValue * 1.25;
  }

  @override
  Widget build(BuildContext context) {
    return ExpenseSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ExpenseSectionHeader(
            icon: Icons.show_chart_rounded,
            title: 'Cashflow chart',
            subtitle: 'Income and expense during the selected period.',
          ),
          const SizedBox(height: 18),
          if (cashflows.isEmpty)
            const ExpenseEmptyState('No cashflow data available.')
          else
            Column(
              children: [
                // Bọc thêm Padding bên phải/dưới để biểu đồ có không gian thở, không đè chữ
                Padding(
                  padding: const EdgeInsets.only(right: 16, bottom: 8),
                  child: SizedBox(
                    height: 240, // Tăng nhẹ chiều cao tổng thể để chứa text xoay góc
                    child: LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: _calcMaxY(),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: _calcInterval(),
                          getDrawingHorizontalLine: (_) => const FlLine(
                            color: Color(0xFFE5E7EB),
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 46, // Tăng nhẹ để không bị mất số tiền lớn
                              interval: _calcInterval(),
                              getTitlesWidget: (value, _) => Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Text(
                                  formatCompactMoney(value),
                                  style: const TextStyle(
                                      fontSize: 10.5,
                                      color: Color(0xFF6B7280),
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 50, // Đảm bảo đủ khoảng trống cho text khi xoay
                              interval: cashflows.length > 8 ? 2 : 1,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= cashflows.length) {
                                  return const SizedBox.shrink();
                                }

                                // Sử dụng SideTitleWidget chuẩn của fl_chart để tự động căn lề
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  space: 12, // Tăng khoảng cách từ đường chart đến text nhằm tránh bị đè
                                  child: Transform.rotate(
                                    angle: -0.6, // Giảm góc xoay một chút (khoảng -35 độ) giúp text nằm ngang hơn, không đâm lên chart
                                    child: Text(
                                      _formatFullDate(cashflows[index].period),
                                      style: const TextStyle(
                                          fontSize: 9.5,
                                          color: Color(0xFF6B7280),
                                          fontWeight: FontWeight.w600),
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
                            getTooltipItems: (spots) => spots.map((spot) {
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
                            }).toList(),
                          ),
                        ),
                        lineBarsData: [
                          _barData(
                            color: const Color(0xFF10B981),
                            spots: cashflows.asMap().entries
                                .map((e) => FlSpot(e.key.toDouble(), e.value.income))
                                .toList(),
                          ),
                          _barData(
                            color: const Color(0xFFEF4444),
                            spots: cashflows.asMap().entries
                                .map((e) => FlSpot(e.key.toDouble(), e.value.expense))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Row(
                  children: [
                    _ChartLegend(color: Color(0xFF10B981), label: 'Income'),
                    SizedBox(width: 16),
                    _ChartLegend(color: Color(0xFFEF4444), label: 'Expense'),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  LineChartBarData _barData(
      {required Color color, required List<FlSpot> spots}) {
    return LineChartBarData(
      isCurved: true,
      barWidth: 3,
      color: color,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
          show: true, color: color.withOpacity(0.10)),
      spots: spots,
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
              color: color, borderRadius: BorderRadius.circular(99)),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}