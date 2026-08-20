import 'package:flutter/material.dart';
import '../../core/theme/brik_theme.dart';

/// BRIK Floating Segmented Navigation Bar
///
/// Matches the reference UI exactly:
/// - Left: Circular floating action button (Dashboard / Home icon [ ⚑ ]).
/// - Center: Floating capsule with segmented pill toggle ([ AGENT ] / [ DISCOVER ]).
/// - Right: Circular floating action button (Cart [ 🛒 ] / More [ ••• ] with badge).
class SegmentedPillNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onIndexChanged;
  final int cartItemCount;

  const SegmentedPillNav({
    super.key,
    required this.selectedIndex,
    required this.onIndexChanged,
    this.cartItemCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── 1. Left Circular Button (Dashboard / Overview) ─────────────
            _buildCircleButton(
              index: 0,
              icon: Icons.flag_outlined,
              selectedIcon: Icons.flag_rounded,
              onTap: () => onIndexChanged(0),
            ),
            const SizedBox(width: 10),

            // ── 2. Center Segmented Capsule (AI Agent & Product Discovery) ─
            _buildCenterSegmentedPill(),
            const SizedBox(width: 10),

            // ── 3. Right Circular Button (Cart & Checkout) ─────────────────
            _buildCircleButton(
              index: 3,
              icon: Icons.shopping_bag_outlined,
              selectedIcon: Icons.shopping_bag_rounded,
              badgeCount: cartItemCount,
              onTap: () => onIndexChanged(3),
            ),
          ],
        ),
      ),
    );
  }

  /// Circular dark floating button
  Widget _buildCircleButton({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected
                  ? BrikTheme.cardSurface
                  : BrikTheme.brandNavy,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? Colors.white
                    : BrikTheme.brandNavyLight,
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected
                    ? BrikTheme.brandNavy
                    : Colors.white,
                size: 20,
              ),
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                decoration: BoxDecoration(
                  color: BrikTheme.cardSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: BrikTheme.brandNavy,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Center dark capsule with smooth segmented pill selector
  Widget _buildCenterSegmentedPill() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: BrikTheme.brandNavy,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: BrikTheme.brandNavy, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Segment 1: AI AGENT (Index 1)
          _buildPillSegment(
            index: 1,
            label: 'AGENT',
            onTap: () => onIndexChanged(1),
          ),
          const SizedBox(width: 4),

          // Segment 2: DISCOVERY (Index 2)
          _buildPillSegment(
            index: 2,
            label: 'DISCOVER',
            onTap: () => onIndexChanged(2),
          ),
        ],
      ),
    );
  }

  Widget _buildPillSegment({
    required int index,
    required String label,
    required VoidCallback onTap,
  }) {
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? BrikTheme.cardSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.75),
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}
