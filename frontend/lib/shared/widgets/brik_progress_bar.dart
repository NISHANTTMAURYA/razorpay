import 'package:flutter/material.dart';
import '../../core/theme/brik_theme.dart';

class BrikProgressBar extends StatelessWidget {
  final int percentage;
  final int totalSegments;
  final double height;
  final Color activeColor;
  final Color inactiveColor;

  const BrikProgressBar({
    super.key,
    required this.percentage,
    this.totalSegments = 24,
    this.height = 28,
    this.activeColor = BrikTheme.brandNavy,
    this.inactiveColor = BrikTheme.cardSurfaceSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final activeSegments = ((percentage / 100) * totalSegments).round();

    return Row(
      children: List.generate(totalSegments, (index) {
        final isActive = index < activeSegments;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            height: height,
            decoration: BoxDecoration(
              color: isActive ? activeColor : inactiveColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}
