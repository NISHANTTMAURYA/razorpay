import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double? size;
  final double? width;
  final double? height;
  final Color? color;

  const AppLogo({
    super.key,
    this.size,
    this.width,
    this.height,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveWidth = width ?? (size != null ? size! * 2.8 : 120.0);
    final effectiveHeight = height ?? (size != null ? size! * 0.75 : 36.0);

    return SizedBox(
      width: effectiveWidth,
      height: effectiveHeight,
      child: Image.asset(
        'assets/images/logo.png',
        width: effectiveWidth,
        height: effectiveHeight,
        fit: BoxFit.contain,
        color: color,
        colorBlendMode: color != null ? BlendMode.srcIn : null,
        errorBuilder: (context, error, stackTrace) => Container(
          width: effectiveHeight,
          height: effectiveHeight,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.shopping_bag_outlined,
            color: color ?? Colors.white,
            size: effectiveHeight * 0.6,
          ),
        ),
      ),
    );
  }
}
