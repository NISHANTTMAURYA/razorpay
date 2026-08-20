import 'package:flutter/material.dart';
import '../../../core/theme/brik_theme.dart';
import '../../../shared/widgets/brik_card.dart';
import '../../../shared/widgets/brik_button.dart';

class ProductComparisonSheet extends StatelessWidget {
  final Map<String, dynamic> comparison;
  final List<Map<String, dynamic>> products;
  final Function(int productId) onAddToCart;

  const ProductComparisonSheet({
    super.key,
    required this.comparison,
    required this.products,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final attributes = (comparison['attributes'] as List?) ?? [];
    final p1 = products.isNotEmpty ? products[0] : null;
    final p2 = products.length > 1 ? products[1] : null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: BrikTheme.canvasBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Product Comparison',
                style: TextStyle(
                  color: BrikTheme.textPrimaryOnLight,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: BrikTheme.cardSurface),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Comparison Table Card
          BrikCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      flex: 2,
                      child: Text('Specs', style: TextStyle(color: BrikTheme.textSecondaryOnDark, fontWeight: FontWeight.w600)),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        p1?['name']?.toString().split(' ').take(2).join(' ') ?? 'Option A',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        p2?['name']?.toString().split(' ').take(2).join(' ') ?? 'Option B',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const Divider(color: BrikTheme.cardBorder, height: 24),
                ...attributes.map((attr) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            attr['name']?.toString() ?? '',
                            style: const TextStyle(color: BrikTheme.textSecondaryOnDark, fontSize: 12),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            attr['p1']?.toString() ?? '',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            attr['p2']?.toString() ?? '',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          // Agent Recommendation Card
          if (comparison['recommendation'] != null)
            BrikCard(
              backgroundColor: BrikTheme.cardSurfaceSecondary,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      comparison['recommendation'].toString().replaceAll('*', ''),
                      style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),

          // Action Buttons
          Row(
            children: [
              if (p1 != null)
                Expanded(
                  child: BrikButton(
                    text: 'Add ${p1['brand'] ?? 'Option 1'}',
                    style: BrikButtonStyle.primaryDark,
                    onPressed: () {
                      Navigator.pop(context);
                      onAddToCart(p1['id']);
                    },
                  ),
                ),
              const SizedBox(width: 12),
              if (p2 != null)
                Expanded(
                  child: BrikButton(
                    text: 'Add ${p2['brand'] ?? 'Option 2'}',
                    style: BrikButtonStyle.primaryLilac,
                    onPressed: () {
                      Navigator.pop(context);
                      onAddToCart(p2['id']);
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
