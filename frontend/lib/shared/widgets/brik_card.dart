import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import '../../core/theme/brik_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BrikCard — standard single card with rounded corners
// ─────────────────────────────────────────────────────────────────────────────

class BrikCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color backgroundColor;
  final double borderRadius;
  final BorderRadiusGeometry? borderRadiusGeometry;
  final Border? border;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const BrikCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
    this.margin = const EdgeInsets.only(bottom: 12),
    this.backgroundColor = BrikTheme.cardSurface,
    this.borderRadius = 28.0,
    this.borderRadiusGeometry,
    this.border,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedRadius =
        borderRadiusGeometry ?? BorderRadius.circular(borderRadius);

    final container = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: resolvedRadius,
        border: border ?? Border.all(color: BrikTheme.cardBorder, width: 1.2),
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: container);
    }

    return container;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// JoinedCardGroup — BRIK Signature Precision Slit Joined Cards (Vertical Stack)
// ─────────────────────────────────────────────────────────────────────────────

class JoinedCardGroup extends StatefulWidget {
  final List<JoinedCardSlot> children;

  /// Outer corner radius of the card (default: 32.0)
  final double outerRadius;

  /// Inward horizontal depth of the slit (default: 38.0 for deep penetration)
  final double notchDepth;

  /// Vertical half-height of the slit (default: 4.5 -> 9px sleek slit gap)
  final double notchHalfHeight;

  /// Large outer corner radius where the vertical edge flares into the slit (default: 20.0)
  final double notchCornerRadius;

  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final EdgeInsetsGeometry margin;

  const JoinedCardGroup({
    super.key,
    required this.children,
    this.outerRadius = 32.0,
    this.notchDepth = 38.0,
    this.notchHalfHeight = 4.5,
    this.notchCornerRadius = 20.0,
    this.backgroundColor = BrikTheme.cardSurface,
    this.borderColor = BrikTheme.cardBorder,
    this.borderWidth = 1.2,
    this.margin = const EdgeInsets.only(bottom: 10),
  });

  @override
  State<JoinedCardGroup> createState() => _JoinedCardGroupState();
}

class _JoinedCardGroupState extends State<JoinedCardGroup> {
  late List<GlobalKey> _slotKeys;
  List<double> _dividerY = [];

  @override
  void initState() {
    super.initState();
    _slotKeys = List.generate(widget.children.length, (_) => GlobalKey());
  }

  @override
  void didUpdateWidget(JoinedCardGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.children.length != widget.children.length) {
      _slotKeys = List.generate(widget.children.length, (_) => GlobalKey());
      _dividerY = [];
    }
  }

  void _scheduleRemeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      double cumY = 0;
      final positions = <double>[];
      for (int i = 0; i < _slotKeys.length - 1; i++) {
        final ctx = _slotKeys[i].currentContext;
        if (ctx == null) return;
        final box = ctx.findRenderObject() as RenderBox?;
        if (box == null || !box.hasSize) return;
        cumY += box.size.height;
        positions.add(cumY);
      }
      if (!listEquals(_dividerY, positions)) {
        setState(() => _dividerY = positions);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _scheduleRemeasure();

    return Container(
      margin: widget.margin,
      child: CustomPaint(
        foregroundPainter: _NotchedBorderPainter(
          borderColor: widget.borderColor,
          borderWidth: widget.borderWidth,
          outerRadius: widget.outerRadius,
          notchDepth: widget.notchDepth,
          notchHalfHeight: widget.notchHalfHeight,
          notchCornerRadius: widget.notchCornerRadius,
          dividerY: _dividerY,
        ),
        child: ClipPath(
          clipper: _NotchedClipper(
            outerRadius: widget.outerRadius,
            notchDepth: widget.notchDepth,
            notchHalfHeight: widget.notchHalfHeight,
            notchCornerRadius: widget.notchCornerRadius,
            dividerY: _dividerY,
          ),
          child: Container(
            color: widget.backgroundColor,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < widget.children.length; i++) ...[
                  Container(
                    key: _slotKeys[i],
                    width: double.infinity,
                    padding: widget.children[i].padding,
                    color: widget.children[i].backgroundColor ??
                        widget.backgroundColor,
                    child: widget.children[i].child,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HorizontalJoinedCardGroup — Side-by-Side Cards Joined Horizontally
//
// Fuses two side-by-side cards into a single continuous surface with top and
// bottom vertical slit notches at the seam.
// ─────────────────────────────────────────────────────────────────────────────

class HorizontalJoinedCardGroup extends StatefulWidget {
  final List<JoinedCardSlot> children;

  /// Outer corner radius of the card (default: 32.0)
  final double outerRadius;

  /// Inward vertical depth of the slit notch from top and bottom (default: 34.0)
  final double notchDepth;

  /// Horizontal half-width of the slit (default: 4.5 -> 9px sleek slit gap)
  final double notchHalfWidth;

  /// Large outer corner radius where the horizontal edge flares into the slit (default: 18.0)
  final double notchCornerRadius;

  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final EdgeInsetsGeometry margin;

  const HorizontalJoinedCardGroup({
    super.key,
    required this.children,
    this.outerRadius = 32.0,
    this.notchDepth = 34.0,
    this.notchHalfWidth = 4.5,
    this.notchCornerRadius = 18.0,
    this.backgroundColor = BrikTheme.cardSurface,
    this.borderColor = BrikTheme.cardBorder,
    this.borderWidth = 1.2,
    this.margin = const EdgeInsets.only(bottom: 10),
  });

  @override
  State<HorizontalJoinedCardGroup> createState() =>
      _HorizontalJoinedCardGroupState();
}

class _HorizontalJoinedCardGroupState extends State<HorizontalJoinedCardGroup> {
  late List<GlobalKey> _slotKeys;
  List<double> _dividerX = [];

  @override
  void initState() {
    super.initState();
    _slotKeys = List.generate(widget.children.length, (_) => GlobalKey());
  }

  @override
  void didUpdateWidget(HorizontalJoinedCardGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.children.length != widget.children.length) {
      _slotKeys = List.generate(widget.children.length, (_) => GlobalKey());
      _dividerX = [];
    }
  }

  void _scheduleRemeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      double cumX = 0;
      final positions = <double>[];
      for (int i = 0; i < _slotKeys.length - 1; i++) {
        final ctx = _slotKeys[i].currentContext;
        if (ctx == null) return;
        final box = ctx.findRenderObject() as RenderBox?;
        if (box == null || !box.hasSize) return;
        cumX += box.size.width;
        positions.add(cumX);
      }
      if (!listEquals(_dividerX, positions)) {
        setState(() => _dividerX = positions);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _scheduleRemeasure();

    return Container(
      margin: widget.margin,
      child: CustomPaint(
        foregroundPainter: _HorizontalNotchedBorderPainter(
          borderColor: widget.borderColor,
          borderWidth: widget.borderWidth,
          outerRadius: widget.outerRadius,
          notchDepth: widget.notchDepth,
          notchHalfWidth: widget.notchHalfWidth,
          notchCornerRadius: widget.notchCornerRadius,
          dividerX: _dividerX,
        ),
        child: ClipPath(
          clipper: _HorizontalNotchedClipper(
            outerRadius: widget.outerRadius,
            notchDepth: widget.notchDepth,
            notchHalfWidth: widget.notchHalfWidth,
            notchCornerRadius: widget.notchCornerRadius,
            dividerX: _dividerX,
          ),
          child: Container(
            color: widget.backgroundColor,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int i = 0; i < widget.children.length; i++) ...[
                    Expanded(
                      child: Container(
                        key: _slotKeys[i],
                        padding: widget.children[i].padding,
                        color: widget.children[i].backgroundColor ??
                            widget.backgroundColor,
                        child: widget.children[i].child,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vertical Slit Notched Path (Horizontal Joined Group)
// ─────────────────────────────────────────────────────────────────────────────

Path _buildHorizontalNotchedPath(
  Size size,
  double outerRadius,
  double notchDepth,
  double notchHalfWidth,
  double notchCornerRadius,
  List<double> dividerX,
) {
  // Guard: degenerate size → return simple rounded rect
  if (size.width <= 0 || size.height <= 0) {
    return Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width.clamp(0.0, double.infinity), size.height.clamp(0.0, double.infinity)),
        Radius.circular(outerRadius.clamp(0.0, double.infinity)),
      ));
  }
  final r = outerRadius.clamp(0.0, size.height / 2);
  final d = notchDepth.clamp(0.0, size.height / 2.5);
  final w = notchHalfWidth;
  final cr = notchCornerRadius;
  final path = Path();

  // ── 1. Top-Left Corner ───────────────────────────────────────────────────
  path.moveTo(0, r);
  path.arcToPoint(Offset(r, 0), radius: Radius.circular(r), clockwise: true);

  // ── 2. Top Edge (Going Rightward with Vertical Slits Downward) ────────────
  double currentX = r;
  for (final x in dividerX) {
    final entryX = (x - w - cr).clamp(currentX, size.width);
    final exitX = (x + w + cr).clamp(entryX, size.width);

    path.lineTo(entryX, 0);

    // Left shoulder: curve downward into the slit
    path.arcToPoint(
      Offset(x - w, cr),
      radius: Radius.circular(cr),
      clockwise: true,
    );

    // Slit left edge: vertical line downward into card
    final innerCapY = d - w;
    path.lineTo(x - w, innerCapY);

    // Inner Capsule Tip: tight rounded bottom tip
    path.arcToPoint(
      Offset(x + w, innerCapY),
      radius: Radius.circular(w),
      clockwise: false,
    );

    // Slit right edge: vertical line back up
    path.lineTo(x + w, cr);

    // Right shoulder: curve back to top horizontal edge
    path.arcToPoint(
      Offset(exitX, 0),
      radius: Radius.circular(cr),
      clockwise: true,
    );

    currentX = exitX;
  }

  path.lineTo(size.width - r, 0);
  path.arcToPoint(Offset(size.width, r),
      radius: Radius.circular(r), clockwise: true);

  // ── 3. Right Edge ────────────────────────────────────────────────────────
  path.lineTo(size.width, size.height - r);
  path.arcToPoint(Offset(size.width - r, size.height),
      radius: Radius.circular(r), clockwise: true);

  // ── 4. Bottom Edge (Going Leftward with Vertical Slits Upward) ───────────
  currentX = size.width - r;
  for (final x in dividerX.reversed) {
    final entryX = (x + w + cr).clamp(0.0, currentX);
    final exitX = (x - w - cr).clamp(0.0, entryX);

    path.lineTo(entryX, size.height);

    // Right shoulder: curve upward into the bottom slit
    path.arcToPoint(
      Offset(x + w, size.height - cr),
      radius: Radius.circular(cr),
      clockwise: true,
    );

    // Slit right edge: vertical line upward into card
    final innerCapY = size.height - d + w;
    path.lineTo(x + w, innerCapY);

    // Inner Capsule Tip: tight rounded top tip
    path.arcToPoint(
      Offset(x - w, innerCapY),
      radius: Radius.circular(w),
      clockwise: false,
    );

    // Slit left edge: vertical line back down
    path.lineTo(x - w, size.height - cr);

    // Left shoulder: curve back to bottom horizontal edge
    path.arcToPoint(
      Offset(exitX, size.height),
      radius: Radius.circular(cr),
      clockwise: true,
    );

    currentX = exitX;
  }

  path.lineTo(r, size.height);
  path.arcToPoint(Offset(0, size.height - r),
      radius: Radius.circular(r), clockwise: true);

  // ── 5. Left Edge ─────────────────────────────────────────────────────────
  path.lineTo(0, r);
  path.close();

  return path;
}

// ─────────────────────────────────────────────────────────────────────────────
// Horizontal Notched Clipper & Border Painter
// ─────────────────────────────────────────────────────────────────────────────

class _HorizontalNotchedClipper extends CustomClipper<Path> {
  final double outerRadius, notchDepth, notchHalfWidth, notchCornerRadius;
  final List<double> dividerX;

  const _HorizontalNotchedClipper({
    required this.outerRadius,
    required this.notchDepth,
    required this.notchHalfWidth,
    required this.notchCornerRadius,
    required this.dividerX,
  });

  @override
  Path getClip(Size size) {
    if (dividerX.isEmpty || size.width <= 0 || size.height <= 0) {
      return Path()
        ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width.clamp(0.0, double.infinity), size.height.clamp(0.0, double.infinity)),
          Radius.circular(outerRadius),
        ));
    }
    return _buildHorizontalNotchedPath(
      size,
      outerRadius,
      notchDepth,
      notchHalfWidth,
      notchCornerRadius,
      dividerX,
    );
  }

  @override
  bool shouldReclip(_HorizontalNotchedClipper old) =>
      old.outerRadius != outerRadius ||
      old.notchDepth != notchDepth ||
      old.notchHalfWidth != notchHalfWidth ||
      old.notchCornerRadius != notchCornerRadius ||
      !listEquals(old.dividerX, dividerX);
}

class _HorizontalNotchedBorderPainter extends CustomPainter {
  final Color borderColor;
  final double borderWidth, outerRadius, notchDepth, notchHalfWidth, notchCornerRadius;
  final List<double> dividerX;

  const _HorizontalNotchedBorderPainter({
    required this.borderColor,
    required this.borderWidth,
    required this.outerRadius,
    required this.notchDepth,
    required this.notchHalfWidth,
    required this.notchCornerRadius,
    required this.dividerX,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    if (dividerX.isEmpty) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(outerRadius),
        ),
        paint,
      );
      return;
    }

    canvas.drawPath(
      _buildHorizontalNotchedPath(
        size,
        outerRadius,
        notchDepth,
        notchHalfWidth,
        notchCornerRadius,
        dividerX,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_HorizontalNotchedBorderPainter old) =>
      old.borderColor != borderColor ||
      old.borderWidth != borderWidth ||
      old.outerRadius != outerRadius ||
      old.notchDepth != notchDepth ||
      old.notchHalfWidth != notchHalfWidth ||
      old.notchCornerRadius != notchCornerRadius ||
      !listEquals(old.dividerX, dividerX);
}

// ─────────────────────────────────────────────────────────────────────────────
// Sleek-Slit Notched Path Builder (Vertical Joined Group)
// ─────────────────────────────────────────────────────────────────────────────

Path _buildNotchedPath(
  Size size,
  double outerRadius,
  double notchDepth,
  double notchHalfHeight,
  double notchCornerRadius,
  List<double> dividerY,
) {
  final r = outerRadius.clamp(0.0, size.height / 2);
  final d = notchDepth.clamp(0.0, size.width / 3);
  final h = notchHalfHeight;
  final cr = notchCornerRadius;
  final path = Path();

  // ── Top Edge ─────────────────────────────────────────────────────────────
  path.moveTo(r, 0);
  path.lineTo(size.width - r, 0);
  path.arcToPoint(Offset(size.width, r),
      radius: Radius.circular(r), clockwise: true);

  // ── Right Edge (Going Downward) ──────────────────────────────────────────
  double currentY = r;
  for (final y in dividerY) {
    final entryY = (y - h - cr).clamp(currentY, size.height);
    final exitY = (y + h + cr).clamp(entryY, size.height);

    path.lineTo(size.width, entryY);

    // 1. Top Shoulder: large outer curve from vertical edge inward
    path.arcToPoint(
      Offset(size.width - cr, y - h),
      radius: Radius.circular(cr),
      clockwise: true,
    );

    // 2. Slit top edge: straight horizontal line deep into the card
    final innerCapX = size.width - d + h;
    path.lineTo(innerCapX, y - h);

    // 3. Inner Capsule Tip: tight rounded end
    path.arcToPoint(
      Offset(innerCapX, y + h),
      radius: Radius.circular(h),
      clockwise: false,
    );

    // 4. Slit bottom edge: straight horizontal line back out
    path.lineTo(size.width - cr, y + h);

    // 5. Bottom Shoulder: large outer curve back to vertical edge
    path.arcToPoint(
      Offset(size.width, exitY),
      radius: Radius.circular(cr),
      clockwise: true,
    );

    currentY = exitY;
  }

  path.lineTo(size.width, size.height - r);
  path.arcToPoint(Offset(size.width - r, size.height),
      radius: Radius.circular(r), clockwise: true);

  // ── Bottom Edge ───────────────────────────────────────────────────────────
  path.lineTo(r, size.height);
  path.arcToPoint(Offset(0, size.height - r),
      radius: Radius.circular(r), clockwise: true);

  // ── Left Edge (Going Upward) ─────────────────────────────────────────────
  currentY = size.height - r;
  for (final y in dividerY.reversed) {
    final entryY = (y + h + cr).clamp(0.0, currentY);
    final exitY = (y - h - cr).clamp(0.0, entryY);

    path.lineTo(0, entryY);

    // 1. Bottom Shoulder: large outer curve from vertical edge inward
    path.arcToPoint(
      Offset(cr, y + h),
      radius: Radius.circular(cr),
      clockwise: true,
    );

    // 2. Slit bottom edge: straight horizontal line deep into the card
    final innerCapX = d - h;
    path.lineTo(innerCapX, y + h);

    // 3. Inner Capsule Tip: tight rounded end
    path.arcToPoint(
      Offset(innerCapX, y - h),
      radius: Radius.circular(h),
      clockwise: false,
    );

    // 4. Slit top edge: straight horizontal line back out
    path.lineTo(cr, y - h);

    // 5. Top Shoulder: large outer curve back to vertical edge
    path.arcToPoint(
      Offset(0, exitY),
      radius: Radius.circular(cr),
      clockwise: true,
    );

    currentY = exitY;
  }

  path.lineTo(0, r);
  path.arcToPoint(Offset(r, 0), radius: Radius.circular(r), clockwise: true);
  path.close();

  return path;
}

// ─────────────────────────────────────────────────────────────────────────────
// Clipper & Border Painter for Vertical Joined Group
// ─────────────────────────────────────────────────────────────────────────────

class _NotchedClipper extends CustomClipper<Path> {
  final double outerRadius, notchDepth, notchHalfHeight, notchCornerRadius;
  final List<double> dividerY;

  const _NotchedClipper({
    required this.outerRadius,
    required this.notchDepth,
    required this.notchHalfHeight,
    required this.notchCornerRadius,
    required this.dividerY,
  });

  @override
  Path getClip(Size size) {
    if (dividerY.isEmpty) {
      return Path()
        ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(outerRadius),
        ));
    }
    return _buildNotchedPath(
      size,
      outerRadius,
      notchDepth,
      notchHalfHeight,
      notchCornerRadius,
      dividerY,
    );
  }

  @override
  bool shouldReclip(_NotchedClipper old) =>
      old.outerRadius != outerRadius ||
      old.notchDepth != notchDepth ||
      old.notchHalfHeight != notchHalfHeight ||
      old.notchCornerRadius != notchCornerRadius ||
      !listEquals(old.dividerY, dividerY);
}

class _NotchedBorderPainter extends CustomPainter {
  final Color borderColor;
  final double borderWidth, outerRadius, notchDepth, notchHalfHeight, notchCornerRadius;
  final List<double> dividerY;

  const _NotchedBorderPainter({
    required this.borderColor,
    required this.borderWidth,
    required this.outerRadius,
    required this.notchDepth,
    required this.notchHalfHeight,
    required this.notchCornerRadius,
    required this.dividerY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    if (dividerY.isEmpty) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(outerRadius),
        ),
        paint,
      );
      return;
    }

    canvas.drawPath(
      _buildNotchedPath(
        size,
        outerRadius,
        notchDepth,
        notchHalfHeight,
        notchCornerRadius,
        dividerY,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_NotchedBorderPainter old) =>
      old.borderColor != borderColor ||
      old.borderWidth != borderWidth ||
      old.outerRadius != outerRadius ||
      old.notchDepth != notchDepth ||
      old.notchHalfHeight != notchHalfHeight ||
      old.notchCornerRadius != notchCornerRadius ||
      !listEquals(old.dividerY, dividerY);
}

// ─────────────────────────────────────────────────────────────────────────────
// Public Slot Data Classes
// ─────────────────────────────────────────────────────────────────────────────

class JoinedCardSlot {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const JoinedCardSlot({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
    this.backgroundColor,
    this.onTap,
  });
}

class JoinedCard extends JoinedCardSlot {
  const JoinedCard({
    required super.child,
    super.padding,
    super.backgroundColor,
    super.onTap,
  });
}
