import 'package:flutter/material.dart';
import '../../core/theme/brik_theme.dart';

class WaveVisualizer extends StatefulWidget {
  final double height;
  final bool isListening;

  const WaveVisualizer({
    super.key,
    this.height = 200,
    this.isListening = true,
  });

  @override
  State<WaveVisualizer> createState() => _WaveVisualizerState();
}

class _WaveVisualizerState extends State<WaveVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset _dragOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _dragOffset = details.localPosition;
        });
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size(double.infinity, widget.height),
            painter: _WavePainter(
              animationValue: _controller.value,
              dragOffset: _dragOffset,
              isListening: widget.isListening,
            ),
          );
        },
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double animationValue;
  final Offset dragOffset;
  final bool isListening;

  _WavePainter({
    required this.animationValue,
    required this.dragOffset,
    required this.isListening,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(w * 0.1, h * 0.7);

    // Smooth Bezier Curve resembling inspiration aesthetic
    final p1 = Offset(w * 0.35, h * 0.95);
    final p2 = Offset(w * 0.38, h * 0.2);
    final p3 = Offset(w * 0.85, h * 0.05);

    path.cubicTo(p1.dx, p1.dy, p2.dx, p2.dy, p3.dx, p3.dy);

    canvas.drawPath(path, linePaint);

    // Glowing Trail/Orb Beads along curve
    final t = (animationValue + (dragOffset.dx > 0 ? (dragOffset.dx / w) * 0.2 : 0)) % 1.0;

    const trailCount = 6;
    for (int i = 0; i < trailCount; i++) {
      final lag = (t - (i * 0.025)) % 1.0;
      final lagPos = _calculateBezierPoint(lag, Offset(w * 0.1, h * 0.7), p1, p2, p3);
      final opacity = (1.0 - (i / trailCount)) * 0.8;

      final glowPaint = Paint()
        ..color = BrikTheme.brandNavy.withValues(alpha: opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.0 + (i * 1.5));

      final solidPaint = Paint()
        ..color = Colors.white.withValues(alpha: opacity);

      canvas.drawCircle(lagPos, 14.0 - (i * 1.8), glowPaint);
      canvas.drawCircle(lagPos, 11.0 - (i * 1.5), solidPaint);
    }
  }

  Offset _calculateBezierPoint(double t, Offset p0, Offset p1, Offset p2, Offset p3) {
    final u = 1 - t;
    final tt = t * t;
    final uu = u * u;
    final uuu = uu * u;
    final ttt = tt * t;

    final x = uuu * p0.dx + 3 * uu * t * p1.dx + 3 * u * tt * p2.dx + ttt * p3.dx;
    final y = uuu * p0.dy + 3 * uu * t * p1.dy + 3 * u * tt * p2.dy + ttt * p3.dy;

    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => true;
}
