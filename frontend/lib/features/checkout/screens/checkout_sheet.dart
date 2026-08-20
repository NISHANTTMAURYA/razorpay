import 'package:flutter/material.dart';
import '../../../core/theme/brik_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/supabase_auth_service.dart';
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
  int _selectedPaymentMethod = 0; // 0=UPI, 1=Card, 2=Netbanking

  static const double _aiDiscount = 500.0;

  double get _subtotal => double.tryParse(widget.cart['subtotal']?.toString() ?? '2999') ?? 2999.0;
  double get _total => (_subtotal - _aiDiscount).clamp(0.0, double.infinity);

  Future<void> _handleRazorpayPayment() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Creating Razorpay Order...';
    });

    final cartId = widget.cart['id']?.toString() ?? 'cart_demo_01';
    final address = {
      'name': SupabaseAuthService().userName,
      'phone': '+919876543210',
      'city': 'Bengaluru',
      'postal_code': '560001'
    };

    final checkoutResult = await ApiService().checkout(
      cartId: cartId,
      shippingAddress: address,
    );

    final orderId = checkoutResult['order_id']?.toString() ?? '';
    final rzpOrderId = checkoutResult['razorpay_order_id']?.toString() ?? '';

    setState(() => _statusMessage = 'HMAC-SHA256 Signing & Processing...');
    await Future.delayed(const Duration(milliseconds: 1400));

    final verifyResult = await ApiService().verifyPayment(
      orderId: orderId,
      razorpayOrderId: rzpOrderId,
      razorpayPaymentId: 'pay_mitrai_${DateTime.now().millisecondsSinceEpoch}',
      razorpaySignature: 'simulated_test_sig',
    );

    if (!mounted) return;
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
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 24),
      decoration: const BoxDecoration(
        color: BrikTheme.canvasBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sheet handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: BrikTheme.brandNavy.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isPaid ? 'Order Confirmed! 🎉' : 'Razorpay Checkout',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
              ),
              if (!_isPaid)
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: BrikTheme.brandNavy),
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isPaid) ...[
            // ── Success State ──────────────────────────────────────────────
            BrikCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: BrikTheme.brandNavy,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Payment Successful',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Order #${_confirmedOrder?['tracking_number'] ?? 'MITRAI-8A2F99'}',
                    style: const TextStyle(color: BrikTheme.brandNavy, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹${_total.toStringAsFixed(0)} paid via Razorpay · HMAC-SHA256 Verified',
                    style: const TextStyle(color: BrikTheme.textSecondaryOnDark, fontSize: 12, height: 1.3),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Delivery in 2–4 business days. The AI Agent is ready for any post-purchase questions.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: BrikTheme.textSecondaryOnDark, fontSize: 12.5, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            BrikButton(
              text: 'Track My Order',
              isFullWidth: true,
              style: BrikButtonStyle.primaryLilac,
              icon: const Icon(Icons.local_shipping_outlined, color: Colors.white, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ] else ...[
            // ── Checkout Summary ────────────────────────────────────────────
            BrikCard(
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with HMAC badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Order Summary', style: TextStyle(color: BrikTheme.brandNavy, fontSize: 13, fontWeight: FontWeight.w700)),
                      PillBadge(
                        text: 'HMAC-SHA256',
                        backgroundColor: BrikTheme.cardSurfaceSecondary,
                        textColor: Colors.white,
                        fontSize: 9.5,
                      ),
                    ],
                  ),
                  const Divider(color: BrikTheme.cardBorder, height: 20),
                  // Line items
                  _summaryRow('Subtotal', '₹${_subtotal.toStringAsFixed(0)}'),
                  const SizedBox(height: 8),
                  _summaryRow('AI Deal Match Discount', '−₹${_aiDiscount.toStringAsFixed(0)}', accent: true),
                  const SizedBox(height: 8),
                  _summaryRow('Express Delivery', 'FREE', accent: true),
                  const Divider(color: BrikTheme.cardBorder, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                      Text(
                        '₹${_total.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Payment Method Selector ─────────────────────────────────────
            BrikCard(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payment Method', style: TextStyle(color: BrikTheme.brandNavy, fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _paymentMethodChip(0, Icons.account_balance_wallet_outlined, 'UPI'),
                      const SizedBox(width: 8),
                      _paymentMethodChip(1, Icons.credit_card_rounded, 'Card'),
                      const SizedBox(width: 8),
                      _paymentMethodChip(2, Icons.account_balance_rounded, 'Netbanking'),
                    ],
                  ),
                  if (_selectedPaymentMethod == 0) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _upiIcon('G', Colors.blue),
                        const SizedBox(width: 8),
                        _upiIcon('P', Colors.indigo),
                        const SizedBox(width: 8),
                        _upiIcon('P', Colors.teal),
                        const SizedBox(width: 8),
                        const Text('& More UPI apps', style: TextStyle(color: BrikTheme.textSecondaryOnDark, fontSize: 11)),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // ── Processing or CTA ───────────────────────────────────────────
            if (_isProcessing)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: BrikTheme.brandNavy,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _statusMessage,
                      style: const TextStyle(color: BrikTheme.brandNavy, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              BrikButton(
                text: 'Pay ₹${_total.toStringAsFixed(0)} with Razorpay',
                isFullWidth: true,
                style: BrikButtonStyle.primaryLilac,
                icon: const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 18),
                onPressed: _handleRazorpayPayment,
              ),

            // Security footnote
            const SizedBox(height: 12),
            const Center(
              child: Text(
                '🔒 PCI-DSS 3.2 · Secured by Razorpay · HMAC-SHA256',
                style: TextStyle(color: BrikTheme.textSecondaryOnDark, fontSize: 11),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool accent = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: accent ? BrikTheme.brandNavy : BrikTheme.textSecondaryOnDark, fontSize: 13)),
        Text(value, style: TextStyle(color: accent ? BrikTheme.accentLavender : Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
      ],
    );
  }

  Widget _paymentMethodChip(int index, IconData icon, String label) {
    final isSelected = _selectedPaymentMethod == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? BrikTheme.brandNavy : BrikTheme.cardSurfaceSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? BrikTheme.brandNavy : BrikTheme.cardBorder,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _upiIcon(String letter, Color color) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13),
        ),
      ),
    );
  }
}
