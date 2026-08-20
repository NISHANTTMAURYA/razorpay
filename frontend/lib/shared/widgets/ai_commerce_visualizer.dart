import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/brik_theme.dart';

class AiCommerceVisualizer extends StatefulWidget {
  final double height;

  const AiCommerceVisualizer({
    super.key,
    this.height = 200,
  });

  @override
  State<AiCommerceVisualizer> createState() => _AiCommerceVisualizerState();
}

class _AiCommerceVisualizerState extends State<AiCommerceVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final List<String> _shoppingIntents = [
    'Wireless Audio',
    'Under ₹3,000',
    'Compare Specs',
    'Razorpay Pay',
    'Instant Order'
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(double.infinity, widget.height),
              painter: _CommerceWavePainter(animationValue: _controller.value),
            ),
            // Floating ambient shopping intent badge
            Positioned(
              top: widget.height * 0.25 + sin(_controller.value * 2 * pi) * 12,
              left: 20 + cos(_controller.value * 2 * pi) * 10,
              child: _buildFloatingPill(
                _shoppingIntents[(_controller.value * _shoppingIntents.length).floor() % _shoppingIntents.length],
              ),
            ),
            Positioned(
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: BrikTheme.cardSurfaceSecondary,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.auto_awesome, color: BrikTheme.brandNavy, size: 14),
                    SizedBox(width: 8),
                    Text(
                      'AI Agent Reasoning & Price Engine Active',
                      style: TextStyle(
                        color: BrikTheme.brandNavy,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFloatingPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: BrikTheme.brandNavy.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrikTheme.brandNavy.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: BrikTheme.brandNavy,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _CommerceWavePainter extends CustomPainter {
  final double animationValue;

  _CommerceWavePainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Harmonic multi-wave path
    final wavePaint1 = Paint()
      ..color = BrikTheme.brandNavy.withValues(alpha: 0.45)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final wavePaint2 = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final path1 = Path();
    final path2 = Path();

    path1.moveTo(0, h * 0.5);
    path2.moveTo(0, h * 0.55);

    for (double x = 0; x <= w; x += 4) {
      final y1 = h * 0.5 + sin((x / w * 4 * pi) + (animationValue * 2 * pi)) * 26;
      final y2 = h * 0.55 + cos((x / w * 3 * pi) - (animationValue * 2 * pi)) * 18;
      path1.lineTo(x, y1);
      path2.lineTo(x, y2);
    }

    canvas.drawPath(path2, wavePaint2);
    canvas.drawPath(path1, wavePaint1);

    // Glowing orbital beads along active wave
    final beadX = (animationValue * w) % w;
    final beadY = h * 0.5 + sin((beadX / w * 4 * pi) + (animationValue * 2 * pi)) * 26;

    final glow = Paint()
      ..color = BrikTheme.brandNavy.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final solid = Paint()..color = Colors.white;

    canvas.drawCircle(Offset(beadX, beadY), 10, glow);
    canvas.drawCircle(Offset(beadX, beadY), 6, solid);
  }

  @override
  bool shouldRepaint(covariant _CommerceWavePainter oldDelegate) => true;
}
