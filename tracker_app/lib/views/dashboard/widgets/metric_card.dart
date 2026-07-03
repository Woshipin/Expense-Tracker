import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0), // 去除上下内边距，完全靠 Row 的居中保证绝对等高
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // 🌟 强力保证：Icon 与数据处于同一行且水平绝对居中对齐
        children: [
          // 左侧：Icon 容器 (图标缩小到 20px)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14), // 图标与文字的数据间距
          
          // 右侧：紧凑的指标文字数据
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // 紧凑包裹，消除多余空白
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: SunsetColors.dark.withValues(alpha: 0.4),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: SunsetColors.dark,
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}