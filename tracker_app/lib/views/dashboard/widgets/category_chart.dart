import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/colors.dart';

class CategoryChart extends StatelessWidget {
  const CategoryChart({super.key});

  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 50, // 增大内部空心半径，变成甜甜圈形状
        sections: [
          PieChartSectionData(
            color: const Color(0xFF64748B),
            value: 9150,
            title: '',
            radius: 24, // 减小外圈厚度
          ),
          PieChartSectionData(
            color: SunsetColors.expense,
            value: 1000,
            title: '',
            radius: 24,
          ),
          PieChartSectionData(
            color: const Color(0xFFF59E0B),
            value: 100,
            title: '',
            radius: 24,
          ),
        ],
      ),
    );
  }
}