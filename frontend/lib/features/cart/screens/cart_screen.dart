import 'package:flutter/material.dart';
import '../../../core/theme/brik_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/widgets/brik_card.dart';
import '../../../shared/widgets/brik_button.dart';
import '../../../shared/widgets/brik_header_card.dart';
import '../../../shared/widgets/pill_badge.dart';
import '../../checkout/screens/checkout_sheet.dart';
import '../../orders/screens/order_tracking_screen.dart';

class CartScreen extends StatefulWidget {
  final VoidCallback? onCheckoutComplete;
  final VoidCallback? onSettingsPressed;

  const CartScreen({
    super.key,
    this.onCheckoutComplete,
    this.onSettingsPressed,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Map<String, dynamic>? _cart;
  bool _isLoading = true;
  // Local quantity state keyed by product id
  final Map<String, int> _quantities = {};

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    final cartData = await ApiService().getCart();
    if (!mounted) return;
    setState(() {
      _cart = cartData;
      _isLoading = false;
      // Seed local quantities from cart items
      for (final item in (cartData['items'] as List? ?? [])) {
        final id = item['product']?['id']?.toString() ?? item['id']?.toString() ?? '';
        if (id.isNotEmpty) {
          _quantities[id] = (item['quantity'] as num?)?.toInt() ?? 1;
        }
      }
    });
  }

  void _incrementQty(String id) => setState(() => _quantities[id] = (_quantities[id] ?? 1) + 1);
  void _decrementQty(String id) {
    final current = _quantities[id] ?? 1;
    if (current <= 1) {
      setState(() => _quantities.remove(id));
    } else {
      setState(() => _quantities[id] = current - 1);
    }
  }

  List<Map<String, dynamic>> get _activeItems {
    final items = (_cart?['items'] as List?) ?? [];
    return items
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((item) {
          final id = item['product']?['id']?.toString() ?? item['id']?.toString() ?? '';
          return _quantities.containsKey(id);
        })
        .toList();
  }

  double get _subtotal {
    double total = 0;
    for (final item in _activeItems) {
      final id = item['product']?['id']?.toString() ?? item['id']?.toString() ?? '';
      final price = double.tryParse(item['unit_price']?.toString() ?? '0') ?? 0;
      total += price * (_quantities[id] ?? 1);
    }
    return total;
  }

  void _openCheckout() {
    if (_cart == null) return;
    final cartWithQty = Map<String, dynamic>.from(_cart!);
    cartWithQty['subtotal'] = _subtotal.toStringAsFixed(2);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CheckoutSheet(
        cart: cartWithQty,
        onOrderSuccess: () {
          _loadCart();
          widget.onCheckoutComplete?.call();
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
    final items = _activeItems;
    const discount = 500.0;
    final subtotalNum = _isLoading
        ? (double.tryParse(_cart?['subtotal']?.toString() ?? '2999') ?? 2999.0)
        : _subtotal;
    final total = (subtotalNum - discount).clamp(0.0, double.infinity);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrikHeaderCard(
            tagText: '${items.length} ITEMS IN CART',
            margin: const EdgeInsets.only(bottom: 10),
            onSettingsPressed: widget.onSettingsPressed,
          ),

          if (_isLoading)
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
                      'Ask the AI Agent to discover products for you.',
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
                    final id = prod['id']?.toString() ?? item['id']?.toString() ?? '';
                    final qty = _quantities[id] ?? 1;
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
                                    // Quantity Stepper (functional)
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
                                            onTap: () => _decrementQty(id),
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
                                            onTap: () => _incrementQty(id),
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
                    onPressed: _openCheckout,
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
