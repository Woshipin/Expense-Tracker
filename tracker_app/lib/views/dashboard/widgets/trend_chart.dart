import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/colors.dart';

class TrendChart extends StatelessWidget {
  const TrendChart({super.key});

  @override
  Widget build(BuildContext context) {
    const days = ['Wed', 'Thu', 'Fri', 'Sat', 'Sun', 'Mon', 'Tue'];

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < days.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      days[value.toInt()],
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
        // 添加悬浮提示 Tooltip
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            // 修改后
            tooltipBgColor: Colors.white,
            tooltipRoundedRadius: 12,
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              if (touchedSpots.isEmpty) return [];
              final dayIndex = touchedSpots[0].x.toInt();
              final dayName = days[dayIndex];

              return [
                LineTooltipItem(
                  '$dayName\n',
                  const TextStyle(color: SunsetColors.dark, fontWeight: FontWeight.bold, fontSize: 14),
                  children: [
                    TextSpan(
                      text: 'Income : RM 0\n',
                      style: TextStyle(color: SunsetColors.dark.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.normal, height: 1.5),
                    ),
                    TextSpan(
                      text: 'Expense : RM ${touchedSpots[0].y.toInt()}',
                      style: TextStyle(color: SunsetColors.dark.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.normal, height: 1.5),
                    ),
                  ],
                ),
                // 第二条线不需要重复显示外框，返回 null 即可
                if (touchedSpots.length > 1) null,
              ].whereType<LineTooltipItem>().toList();
            },
          ),
        ),
        lineBarsData: [
          // 支出线 (红色)
          LineChartBarData(
            spots: const [
              FlSpot(0, 800),
              FlSpot(1, 200),
              FlSpot(2, 20),
              FlSpot(3, 10),
              FlSpot(4, 5),
              FlSpot(5, 5),
              FlSpot(6, 2),
            ],
            isCurved: true,
            color: SunsetColors.expense,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  SunsetColors.expense.withValues(alpha: 0.3),
                  SunsetColors.expense.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // 收入线 (绿色)
          LineChartBarData(
            spots: const [
              FlSpot(0, 10),
              FlSpot(1, 10),
              FlSpot(2, 10),
              FlSpot(3, 10),
              FlSpot(4, 10),
              FlSpot(5, 10),
              FlSpot(6, 10),
            ],
            isCurved: true,
            color: SunsetColors.income,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}