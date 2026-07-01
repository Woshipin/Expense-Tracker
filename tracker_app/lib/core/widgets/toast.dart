import 'package:flutter/material.dart';

enum SunsetToastType { success, error, warning }

class SunsetToast {
  static void show(BuildContext context, String message, {SunsetToastType type = SunsetToastType.success}) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (type) {
      case SunsetToastType.success:
        bgColor = const Color(0xFFF0FDF4);
        textColor = const Color(0xFF166534);
        // 【修改】：官方成功图标
        icon = Icons.check_circle_outline;
        break;
      case SunsetToastType.error:
        bgColor = const Color(0xFFFEF2F2);
        textColor = const Color(0xFF991B1B);
        // 【修改】：官方错误图标
        icon = Icons.error_outline;
        break;
      case SunsetToastType.warning:
        bgColor = const Color(0xFFFFF7ED);
        textColor = const Color(0xFF9A3412);
        // 【修改】：官方警告图标
        icon = Icons.warning_amber_rounded;
        break;
    }

    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height * 0.08,
        left: 0,
        right: 0,
        child: Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: Colors.transparent,
            child: Container(
              // 核心改进：限制最大宽度为 350px，保持和 Next.js 一样精致小巧
              constraints: const BoxConstraints(maxWidth: 350),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: textColor.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: textColor, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    
    // 自动在 1.5 秒后关闭
    Future.delayed(const Duration(milliseconds: 1500), () {
      overlayEntry.remove();
    });
  }
}