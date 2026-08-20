import 'package:flutter/material.dart';
import '../../../core/theme/brik_theme.dart';
import '../../../shared/widgets/brik_card.dart';
import '../../../shared/widgets/brik_button.dart';
import '../../../shared/widgets/pill_badge.dart';

class ProductDetailSheet extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onAddToCart;

  const ProductDetailSheet({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final name = product['name']?.toString() ?? 'boAt Rockerz 550 Wireless';
    final brand = product['brand']?.toString() ?? 'boAt';
    final price = product['price']?.toString() ?? '1,999';
    final originalPrice = product['original_price']?.toString() ?? '4,999';
    final rating = product['rating']?.toString() ?? '4.6 ★ (1,240)';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: BrikTheme.canvasBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Header Drag Handle & Close
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 14, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: BrikTheme.brandNavy.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'AI RESEARCHED PRODUCT',
                      style: TextStyle(
                        color: BrikTheme.brandNavy,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: BrikTheme.brandNavy),
                ),
              ],
            ),
          ),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Hero Product Summary Card
                  BrikCard(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            PillBadge(
                              text: brand.toUpperCase(),
                              backgroundColor: BrikTheme.brandNavy,
                              textColor: Colors.white,
                              fontSize: 10,
                            ),
                            PillBadge(
                              text: rating,
                              backgroundColor: BrikTheme.cardSurfaceSecondary,
                              textColor: Colors.white,
                              fontSize: 11,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '₹$price',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '₹$originalPrice',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 15,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const PillBadge(
                              text: '60% OFF',
                              backgroundColor: BrikTheme.brandNavy,
                              textColor: Colors.white,
                              fontSize: 10,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Specs: 20h Playback • 50mm Dynamic Drivers • Physical Bass Boost • Dual Mode (BT 5.0 + AUX)',
                          style: TextStyle(
                            color: BrikTheme.textSecondaryOnDark,
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Multi-Store Live Price Comparison Table Card
                  BrikCard(
                    padding: const EdgeInsets.all(18),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'Multi-Store Price Radar',
                              style: TextStyle(
                                color: BrikTheme.brandNavy,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            PillBadge(
                              text: 'LOWEST GUARANTEED',
                              backgroundColor: BrikTheme.brandNavy,
                              textColor: Colors.white,
                              fontSize: 9.5,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildStorePriceRow('Mitrai Direct Store', '₹1,999', 'Free Express', isBest: true),
                        const Divider(color: BrikTheme.cardBorder, height: 16),
                        _buildStorePriceRow('Flipkart', '₹2,099', '+ ₹40 Delivery'),
                        const Divider(color: BrikTheme.cardBorder, height: 16),
                        _buildStorePriceRow('Amazon India', '₹2,199', 'Prime 1-Day'),
                      ],
                    ),
                  ),

                  // 3. Multi-Source Sentiment Breakdown (YouTube & Reddit)
                  BrikCard(
                    padding: const EdgeInsets.all(18),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Multi-Source Community Intelligence',
                          style: TextStyle(
                            color: BrikTheme.brandNavy,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // YouTube Reviewers
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: BrikTheme.cardSurfaceSecondary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Row(
                                children: [
                                  Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'YouTube Tech Reviewers (Geekyranjit, Beebom)',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6),
                              Text(
                                '94% Positive Consensus: Praised for punchy sub-bass, 20h verified battery, and comfortable over-ear cushioning.',
                                style: TextStyle(color: BrikTheme.textSecondaryOnDark, fontSize: 11.5, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Reddit Community
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: BrikTheme.cardSurfaceSecondary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Row(
                                children: [
                                  Icon(Icons.forum_rounded, color: BrikTheme.brandNavy, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Reddit Community (r/IndiaTech, r/gadgets)',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6),
                              Text(
                                'High daily reliability for studying and casual gaming; minor mic latency in busy outdoor environments.',
                                style: TextStyle(color: BrikTheme.textSecondaryOnDark, fontSize: 11.5, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sticky Bottom CTA Bar
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
              child: BrikButton(
                text: 'Add to Cart & Checkout (₹$price)',
                isFullWidth: true,
                style: BrikButtonStyle.primaryLilac,
                icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 18),
                onPressed: () {
                  Navigator.pop(context);
                  onAddToCart();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorePriceRow(String store, String price, String delivery, {bool isBest = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              store,
              style: TextStyle(
                color: isBest ? Colors.white : BrikTheme.brandNavy,
                fontWeight: isBest ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
            Text(
              delivery,
              style: const TextStyle(
                color: BrikTheme.textSecondaryOnDark,
                fontSize: 11,
              ),
            ),
          ],
        ),
        Text(
          price,
          style: TextStyle(
            color: isBest ? Colors.white : BrikTheme.brandNavy,
            fontWeight: FontWeight.w800,
            fontSize: isBest ? 16 : 14,
          ),
        ),
      ],
    );
  }
}
