import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/brik_theme.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../shared/widgets/brik_card.dart';
import '../../../shared/widgets/brik_button.dart';
import '../../../shared/widgets/brik_header_card.dart';
import '../../../shared/widgets/pill_badge.dart';
import '../../checkout/screens/checkout_sheet.dart';
import '../../orders/screens/order_tracking_screen.dart';

class CartScreen extends StatelessWidget {
  final VoidCallback? onCheckoutComplete;
  final VoidCallback? onSettingsPressed;

  const CartScreen({
    super.key,
    this.onCheckoutComplete,
    this.onSettingsPressed,
  });

  void _openCheckout(BuildContext context, Map<String, dynamic> cart) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CheckoutSheet(
        cart: cart,
        onOrderSuccess: () {
          context.read<CartProvider>().clearCart();
          onCheckoutComplete?.call();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderTrackingScreen(
                onBackToHome: () => Navigator.pop(context),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final items = cartProvider.items;
    final subtotalNum = cartProvider.subtotal;
    const discount = 500.0;
    final total = (subtotalNum - (subtotalNum > 0 ? discount : 0)).clamp(0.0, double.infinity);

    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    final effectiveBottomPadding = bottomSafeArea + 110.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, effectiveBottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrikHeaderCard(
            tagText: '${items.length} ITEMS IN CART',
            margin: const EdgeInsets.only(bottom: 10),
            onSettingsPressed: onSettingsPressed,
          ),

          if (cartProvider.isLoading && items.isEmpty)
            const Expanded(child: Center(child: CircularProgressIndicator(color: BrikTheme.brandNavy)))
          else if (items.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.shopping_bag_outlined, size: 64, color: BrikTheme.brandNavy),
                    SizedBox(height: 16),
                    Text(
                      'Your cart is empty',
                      style: TextStyle(color: BrikTheme.brandNavy, fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Ask the AI Agent to discover products or browse the catalog.',
                      style: TextStyle(color: BrikTheme.textSecondaryOnDark),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView(
                children: [
                  // Shipping Address
                  BrikCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: const [
                              Icon(Icons.location_on_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Deliver to: Bengaluru, Karnataka (560034)',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const PillBadge(
                          text: 'CHANGE',
                          backgroundColor: BrikTheme.brandNavy,
                          textColor: Colors.white,
                          fontSize: 9.5,
                        ),
                      ],
                    ),
                  ),

                  // Cart Item Cards
                  ...items.map((item) {
                    final prod = item['product'] as Map<String, dynamic>? ?? {};
                    final pid = prod['id'] ?? item['id'] ?? 1;
                    final prodId = pid is int ? pid : (int.tryParse(pid.toString()) ?? 1);
                    final qty = (item['quantity'] as num?)?.toInt() ?? 1;
                    final unitPrice = double.tryParse(item['unit_price']?.toString() ?? '0') ?? 0;
                    final lineTotal = unitPrice * qty;

                    return BrikCard(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          // Product thumbnail
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: BrikTheme.cardSurfaceSecondary,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.headphones_rounded, color: Colors.white),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  prod['name']?.toString() ?? item['product_name']?.toString() ?? 'Product',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(
                                      '₹${unitPrice.toStringAsFixed(0)}',
                                      style: const TextStyle(color: BrikTheme.brandNavy, fontSize: 13, fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(width: 12),
                                    // Quantity Stepper (fully wired to CartProvider)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: BrikTheme.brandNavy,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              if (qty > 1) {
                                                context.read<CartProvider>().updateItemQuantity(prodId, qty - 1);
                                              }
                                            },
                                            child: const Padding(
                                              padding: EdgeInsets.all(4),
                                              child: Icon(Icons.remove, color: Colors.white, size: 14),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 6),
                                            child: Text(
                                              '$qty',
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              context.read<CartProvider>().addItem(prodId, quantity: 1);
                                            },
                                            child: const Padding(
                                              padding: EdgeInsets.all(4),
                                              child: Icon(Icons.add, color: Colors.white, size: 14),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Line total
                          Text(
                            '₹${lineTotal.toStringAsFixed(0)}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }),

                  // Order Summary Card
                  BrikCard(
                    padding: const EdgeInsets.all(18),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payment & Order Summary',
                          style: TextStyle(color: BrikTheme.brandNavy, fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        _buildSummaryRow('Subtotal', '₹${subtotalNum.toStringAsFixed(0)}'),
                        const SizedBox(height: 6),
                        _buildSummaryRow('AI Deal Match Discount', '-₹${discount.toStringAsFixed(0)}', isHighlight: true),
                        const SizedBox(height: 6),
                        _buildSummaryRow('Express Delivery', 'FREE', isHighlight: true),
                        const Divider(color: BrikTheme.cardBorder, height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Amount', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                            Text(
                              '₹${total.toStringAsFixed(0)}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Checkout CTA
                  BrikButton(
                    text: 'Pay ₹${total.toStringAsFixed(0)} with Razorpay',
                    isFullWidth: true,
                    style: BrikButtonStyle.primaryLilac,
                    icon: const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 18),
                    onPressed: () => _openCheckout(context, cartProvider.cart),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isHighlight ? BrikTheme.brandNavy : BrikTheme.textSecondaryOnDark,
            fontSize: 13,
            fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isHighlight ? BrikTheme.brandNavy : Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
