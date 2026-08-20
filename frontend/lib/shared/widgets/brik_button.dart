import 'package:flutter/material.dart';
import '../../core/theme/brik_theme.dart';

enum BrikButtonStyle { primaryDark, primaryLilac, secondary, outline }

class BrikButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final BrikButtonStyle style;
  final Widget? icon;
  final bool isFullWidth;
  final EdgeInsets padding;
  final double fontSize;

  const BrikButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.style = BrikButtonStyle.primaryDark,
    this.icon,
    this.isFullWidth = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    this.fontSize = 13.0,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color textColor;
    Border? border;

    switch (style) {
      case BrikButtonStyle.primaryLilac:
        bg = BrikTheme.brandNavy;
        textColor = Colors.white;
        break;
      case BrikButtonStyle.primaryDark:
        bg = BrikTheme.cardSurface;
        textColor = Colors.white;
        border = Border.all(color: BrikTheme.cardBorder);
        break;
      case BrikButtonStyle.secondary:
        bg = BrikTheme.cardSurfaceSecondary;
        textColor = Colors.white;
        border = Border.all(color: BrikTheme.cardBorder);
        break;
      case BrikButtonStyle.outline:
        bg = Colors.transparent;
        textColor = Colors.white;
        border = Border.all(color: Colors.white24);
        break;
    }

    Widget content = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          icon!,
          const SizedBox(width: 8),
        ],
        Text(
          text.toUpperCase(),
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          border: border,
        ),
        child: content,
      ),
    );
  }
}
