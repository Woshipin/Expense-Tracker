// lib/views/dashboard/widgets/category_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class CategoryChart extends StatelessWidget {
  final List<dynamic> pieData;
  const CategoryChart({super.key, required this.pieData});

  // 解析并构造 Flutter Color
  Color _parseHexColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return Colors.grey;
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    if (pieData.isEmpty) {
      return const Center(
        child: Text("No spending", style: TextStyle(color: Colors.grey, fontSize: 12)),
      );
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 50, // 甜甜圈形状内部半径
        sections: List.generate(pieData.length, (index) {
          final item = pieData[index];
          final color = _parseHexColor(item['color']);
          final value = (item['value'] as num).toDouble();
          
          return PieChartSectionData(
            color: color,
            value: value,
            title: '', // 不在扇区内部写字，由外部 Legend 呈现，图表更清爽
            radius: 24, // 外圈厚度
          );
        }),
      ),
    );
  }
}