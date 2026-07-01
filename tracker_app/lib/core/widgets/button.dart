import 'package:flutter/material.dart';
import '../constants/colors.dart';

enum SunsetButtonVariant { primary, secondary, ghost, danger }

class SunsetButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final SunsetButtonVariant variant;
  final IconData? icon;

  const SunsetButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = SunsetButtonVariant.primary,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color btnColor;
    Color textColor;
    
    switch (variant) {
      case SunsetButtonVariant.primary:
        btnColor = SunsetColors.primary;
        textColor = Colors.white;
        break;
      case SunsetButtonVariant.secondary:
        btnColor = SunsetColors.primary.withValues(alpha: 0.1);
        textColor = SunsetColors.primary;
        break;
      case SunsetButtonVariant.danger:
        btnColor = SunsetColors.expense;
        textColor = Colors.white;
        break;
      case SunsetButtonVariant.ghost:
        btnColor = Colors.transparent;
        textColor = SunsetColors.dark.withValues(alpha: 0.6);
        break;
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: btnColor,
        foregroundColor: textColor,
        elevation: variant == SunsetButtonVariant.primary ? 4 : 0,
        shadowColor: variant == SunsetButtonVariant.primary 
            ? SunsetColors.primary.withValues(alpha: 0.3) 
            : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }
}