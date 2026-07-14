// lib/views/dashboard/widgets/trend_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/colors.dart';

class TrendChart extends StatelessWidget {
  final List<dynamic> chartData;
  const TrendChart({super.key, required this.chartData});

  @override
  Widget build(BuildContext context) {
    if (chartData.isEmpty) {
      return const Center(
        child: Text("No trend data", style: TextStyle(color: Colors.grey, fontSize: 12)),
      );
    }

    // 动态提取天数标签队列（例如 ['Wed', 'Thu']）
    final List<String> days = chartData.map((item) => (item['name'] as String? ?? '')).toList();

    // 映射支出数据 spots
    final List<FlSpot> expenseSpots = List.generate(chartData.length, (index) {
      final val = (chartData[index]['expense'] as num? ?? 0).toDouble();
      return FlSpot(index.toDouble(), val);
    });

    // 映射收入数据 spots
    final List<FlSpot> incomeSpots = List.generate(chartData.length, (index) {
      final val = (chartData[index]['income'] as num? ?? 0).toDouble();
      return FlSpot(index.toDouble(), val);
    });

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index >= 0 && index < days.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      days[index],
                      style: TextStyle(color: SunsetColors.dark.withValues(alpha: 0.4), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        // 🌟 核心优化：高保真自适应悬浮数据 Tooltip 设计
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.white,
            tooltipRoundedRadius: 12,
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              if (touchedSpots.isEmpty) return [];
              final dayIndex = touchedSpots[0].x.toInt();
              if (dayIndex < 0 || dayIndex >= days.length) return [];
              
              final dayName = days[dayIndex];
              final expenseVal = (chartData[dayIndex]['expense'] as num? ?? 0).toDouble();
              final incomeVal = (chartData[dayIndex]['income'] as num? ?? 0).toDouble();

              return [
                LineTooltipItem(
                  '$dayName\n',
                  const TextStyle(color: SunsetColors.dark, fontWeight: FontWeight.bold, fontSize: 14),
                  children: [
                    TextSpan(
                      text: 'Income : RM ${incomeVal.toStringAsFixed(2)}\n',
                      style: TextStyle(color: const Color(0xFF0D9488), fontSize: 13, fontWeight: FontWeight.normal, height: 1.5),
                    ),
                    TextSpan(
                      text: 'Expense : RM ${expenseVal.toStringAsFixed(2)}',
                      style: TextStyle(color: SunsetColors.expense, fontSize: 13, fontWeight: FontWeight.normal, height: 1.5),
                    ),
                  ],
                ),
                // 第二条收入线无需重复叠加 Tooltip
                if (touchedSpots.length > 1) null,
              ].whereType<LineTooltipItem>().toList();
            },
          ),
        ),
        lineBarsData: [
          // 1. 支出折线 (红色)
          LineChartBarData(
            spots: expenseSpots,
            isCurved: true,
            color: SunsetColors.expense,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  SunsetColors.expense.withValues(alpha: 0.25),
                  SunsetColors.expense.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // 2. 收入折线 (绿色)
          LineChartBarData(
            spots: incomeSpots,
            isCurved: true,
            color: SunsetColors.income,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  SunsetColors.income.withValues(alpha: 0.25),
                  SunsetColors.income.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}