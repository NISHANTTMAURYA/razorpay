import 'package:flutter/material.dart';
import '../../core/theme/brik_theme.dart';
import 'app_logo.dart';
import 'brik_card.dart';
import 'pill_badge.dart';

/// A standardized, reusable top header card used across all pages in the app.
///
/// Ensures 100% pixel-perfect consistency in height, width, padding, logo size,
/// and alignment across every page.
class BrikHeaderCard extends StatelessWidget {
  /// Simple text for the right-hand pill badge (e.g. 'AGENT ACTIVE', '2 ITEMS IN CART').
  final String? tagText;

  /// Background color for the tag badge (defaults to [BrikTheme.accentLavender]).
  final Color? tagBackgroundColor;

  /// Text color for the tag badge (defaults to [BrikTheme.cardSurface]).
  final Color? tagTextColor;

  /// Optional custom trailing widget on the right (overrides [tagText] if provided).
  final Widget? trailing;

  /// Optional leading widget before the logo (e.g. a back button).
  final Widget? leading;

  /// Optional callback to show a back button automatically.
  final VoidCallback? onBack;

  /// Optional callback for settings icon in the top header.
  final VoidCallback? onSettingsPressed;

  /// Bottom margin for the card (defaults to 10.0).
  final EdgeInsetsGeometry margin;

  /// Custom padding inside the header (defaults to 20px horizontal, 13px vertical).
  final EdgeInsetsGeometry padding;

  const BrikHeaderCard({
    super.key,
    this.tagText,
    this.tagBackgroundColor,
    this.tagTextColor,
    this.trailing,
    this.leading,
    this.onBack,
    this.onSettingsPressed,
    this.margin = const EdgeInsets.only(bottom: 10),
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
  });

  @override
  Widget build(BuildContext context) {
    return BrikCard(
      margin: margin,
      padding: padding,
      borderRadius: 24.0,
      height: 60.0, // Fixed height for absolute consistency across all pages
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left side: Optional back button + App Logo
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (onBack != null) ...[
                GestureDetector(
                  onTap: onBack,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ] else if (leading != null) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: leading!,
                ),
              ],
              const AppLogo(width: 96, height: 26),
            ],
          ),

          // Right side: Custom trailing widget or standardized PillBadge + Settings Icon
          if (trailing != null)
            trailing!
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (tagText != null)
                  PillBadge(
                    text: tagText!,
                    backgroundColor: tagBackgroundColor ?? BrikTheme.brandNavy,
                    textColor: tagTextColor ?? Colors.white,
                  ),
                if (onSettingsPressed != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onSettingsPressed,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: BrikTheme.brandNavy,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.settings_outlined,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
