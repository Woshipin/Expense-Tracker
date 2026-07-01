import 'package:flutter/material.dart';
import '../constants/colors.dart';

class SunsetDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;

  const SunsetDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: SunsetColors.dark,
                  ),
                ),
                IconButton(
                  // 【修改】：使用官方的关闭图标
                  icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const Divider(height: 20, color: Color(0xFFF1F5F9)),
            Flexible(child: SingleChildScrollView(child: content)),
            if (actions != null) ...[
              const SizedBox(height: 20),
              Wrap(
                spacing: 12, // 水平间距，相当于 gap
                alignment: WrapAlignment.end, // 右对齐，相当于 MainAxisAlignment.end
                children: actions!,
              )
            ]
          ],
        ),
      ),
    );
  }
}