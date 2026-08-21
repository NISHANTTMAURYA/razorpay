import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

/// Circular Mitrai Accessibility & Brand Logo using new2.svg
class CircularLogo extends StatelessWidget {
  final double size;
  final Color? backgroundColor;
  final Color? borderColor;

  const CircularLogo({
    super.key,
    this.size = 48.0,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFF0F172A),
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor ?? const Color(0xFF3B82F6),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SvgPicture.asset(
        'assets/images/new2.svg',
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholderBuilder: (context) => Center(
          child: Text(
            '⚡',
            style: TextStyle(fontSize: size * 0.45),
          ),
        ),
      ),
    );
  }
}
