import 'package:flutter/material.dart';
import '../../../core/theme/brik_theme.dart';
import '../screens/ai_shopping_screen.dart';
import '../../../shared/widgets/pill_badge.dart';

class FloatingShoppingCopilotSheet extends StatelessWidget {
  final String detectedPackage;
  final String detectedContext;

  const FloatingShoppingCopilotSheet({
    super.key,
    required this.detectedPackage,
    required this.detectedContext,
  });

  static Future<void> show(
    BuildContext context, {
    required String detectedPackage,
    required String detectedContext,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FloatingShoppingCopilotSheet(
        detectedPackage: detectedPackage,
        detectedContext: detectedContext,
      ),
    );
  }

  String _formatAppName(String pkg) {
    if (pkg.contains('amazon')) return 'Amazon India';
    if (pkg.contains('flipkart')) return 'Flipkart';
    if (pkg.contains('grofers')) return 'Blinkit (10-Min)';
    if (pkg.contains('zepto')) return 'Zepto Quick';
    if (pkg.contains('swiggy')) return 'Swiggy Instamart';
    if (pkg.contains('myntra')) return 'Myntra Fashion';
    if (pkg.contains('nykaa')) return 'Nykaa Beauty';
    return 'Active Shopping App';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: BrikTheme.canvasBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 14, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 4,
                        decoration: BoxDecoration(
                          color: BrikTheme.brandNavy.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          '⚡ MITRAI OVERLAY · ${_formatAppName(detectedPackage).toUpperCase()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: BrikTheme.brandNavy,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: BrikTheme.brandNavy, size: 20),
                ),
              ],
            ),
          ),

          // Notification Banner showing detected context
          if (detectedContext.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: BrikTheme.cardSurfaceSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Detected browsing context: "$detectedContext"',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: BrikTheme.textSecondaryOnDark,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const PillBadge(
                    text: 'AUTO-SEARCH',
                    backgroundColor: BrikTheme.brandNavy,
                    textColor: Colors.white,
                    fontSize: 8.5,
                  ),
                ],
              ),
            ),

          // Embedded AI Shopping Screen with detected query
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: AiShoppingScreen(
                initialMessage: detectedContext.isNotEmpty ? detectedContext : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
