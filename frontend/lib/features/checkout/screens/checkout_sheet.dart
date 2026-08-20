import 'package:flutter/material.dart';
import '../../../core/theme/brik_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/widgets/brik_card.dart';
import '../../../shared/widgets/brik_button.dart';
import '../../../shared/widgets/pill_badge.dart';

class CheckoutSheet extends StatefulWidget {
  final Map<String, dynamic> cart;
  final VoidCallback onOrderSuccess;

  const CheckoutSheet({
    super.key,
    required this.cart,
    required this.onOrderSuccess,
  });

  @override
  State<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<CheckoutSheet> {
  bool _isProcessing = false;
  bool _isPaid = false;
  Map<String, dynamic>? _confirmedOrder;
  String _statusMessage = '';

  Future<void> _handleRazorpayPayment() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Creating Razorpay Order...';
    });

    final cartId = widget.cart['id']?.toString() ?? 'cart_demo_01';
    final address = {
      'name': 'Bohdan',
      'phone': '+919876543210',
      'city': 'Bengaluru',
      'postal_code': '560001'
    };

    // 1. Backend Checkout initialization
    final checkoutResult = await ApiService().checkout(
      cartId: cartId,
      shippingAddress: address,
    );

    final orderId = checkoutResult['order_id']?.toString() ?? '';
    final rzpOrderId = checkoutResult['razorpay_order_id']?.toString() ?? '';

    setState(() {
      _statusMessage = 'Processing Razorpay Test Payment...';
    });

    // 2. Simulate Razorpay Checkout Bridge Verification
    await Future.delayed(const Duration(milliseconds: 1200));

    final verifyResult = await ApiService().verifyPayment(
      orderId: orderId,
      razorpayOrderId: rzpOrderId,
      razorpayPaymentId: 'pay_mitrai_${DateTime.now().millisecondsSinceEpoch}',
      razorpaySignature: 'simulated_test_sig',
    );

    setState(() {
      _isProcessing = false;
      if (verifyResult['status'] == 'PAID') {
        _isPaid = true;
        _confirmedOrder = verifyResult['order'];
      }
    });

    widget.onOrderSuccess();
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = widget.cart['subtotal']?.toString() ?? '2999.00';

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
              Text(
                _isPaid ? 'Order Confirmed!' : 'Razorpay Checkout',
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

          if (_isPaid) ...[
            BrikCard(
              backgroundColor: BrikTheme.cardSurface,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 56),
                  const SizedBox(height: 16),
                  const Text(
                    'Payment Successful',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tracking: ${_confirmedOrder?['tracking_number'] ?? 'MITRAI-8A2F99'}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your order is verified and scheduled for delivery in 2-4 business days. The AI Agent is ready for any post-purchase questions.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: BrikTheme.textSecondaryOnDark, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            BrikButton(
              text: 'Done',
              isFullWidth: true,
              style: BrikButtonStyle.primaryLilac,
              onPressed: () => Navigator.pop(context),
            ),
          ] else ...[
            // Checkout Summary Card
            BrikCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Razorpay Payment Gateway', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      const PillBadge(text: 'SECURED'),
                    ],
                  ),
                  const Divider(color: BrikTheme.cardBorder, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Cart Subtotal', style: TextStyle(color: BrikTheme.textSecondaryOnDark)),
                      Text('₹$subtotal', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Estimated Delivery', style: TextStyle(color: BrikTheme.textSecondaryOnDark)),
                      Text('FREE (2-4 Days)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Divider(color: BrikTheme.cardBorder, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                      Text('₹$subtotal', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_isProcessing)
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(color: BrikTheme.cardSurface),
                    const SizedBox(height: 12),
                    Text(_statusMessage, style: const TextStyle(color: BrikTheme.cardSurface, fontWeight: FontWeight.w600)),
                  ],
                ),
              )
            else
              BrikButton(
                text: 'Pay ₹$subtotal with Razorpay',
                isFullWidth: true,
                style: BrikButtonStyle.primaryDark,
                icon: const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 18),
                onPressed: _handleRazorpayPayment,
              ),
          ],
        ],
      ),
    );
  }
}
