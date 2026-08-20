import 'package:flutter/material.dart';
import '../../../core/theme/brik_theme.dart';
import '../../../core/services/supabase_auth_service.dart';
import '../../../shared/widgets/brik_header_card.dart';
import '../../../shared/widgets/brik_card.dart';
import '../../../shared/widgets/brik_button.dart';
import '../../../shared/widgets/pill_badge.dart';

class OrderTrackingScreen extends StatelessWidget {
  final Map<String, dynamic>? order;
  final VoidCallback onBackToHome;
  final Function(String query)? onAskAi;

  const OrderTrackingScreen({
    super.key,
    this.order,
    required this.onBackToHome,
    this.onAskAi,
  });

  @override
  Widget build(BuildContext context) {
    final orderId = order?['id']?.toString() ?? 'ORD-84920';
    final totalAmount = order?['total_amount']?.toString() ?? '2,499';
    final paymentId = order?['razorpay_payment_id']?.toString() ?? 'pay_mitrai_live_948';

    return Scaffold(
      backgroundColor: BrikTheme.canvasBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Consistent Brik Header Card
                  BrikHeaderCard(
                    tagText: 'HMAC VERIFIED',
                    margin: const EdgeInsets.only(bottom: 10),
                    leading: IconButton(
                      onPressed: onBackToHome,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: BrikTheme.brandNavy, size: 18),
                    ),
                  ),

                  // 2. Order Confirmation Status Card (Joined Group)
                  JoinedCardGroup(
                    margin: const EdgeInsets.only(bottom: 12),
                    children: [
                      // Top Slot: Payment Verified Banner
                      JoinedCard(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                PillBadge(
                                  text: 'RAZORPAY PROTECTED',
                                  backgroundColor: BrikTheme.brandNavy,
                                  textColor: Colors.white,
                                  fontSize: 10,
                                ),
                                PillBadge(
                                  text: 'PAID & CONFIRMED',
                                  backgroundColor: BrikTheme.brandNavy,
                                  textColor: Colors.white,
                                  fontSize: 10,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Order #$orderId',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹$totalAmount paid via Razorpay ($paymentId)',
                              style: const TextStyle(
                                color: BrikTheme.textSecondaryOnDark,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bottom Slot: Live Logistics Timeline
                      JoinedCard(
                        padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Live Logistics Timeline',
                              style: TextStyle(
                                color: BrikTheme.brandNavy,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildTimelineStep(
                              icon: Icons.check_circle_rounded,
                              title: 'Order Placed & Payment Verified',
                              subtitle: 'Cryptographic HMAC verification passed',
                              isCompleted: true,
                              isLast: false,
                            ),
                            _buildTimelineStep(
                              icon: Icons.inventory_2_rounded,
                              title: 'Packed at Merchant Warehouse',
                              subtitle: 'Secured in tamper-proof AI logistics packaging',
                              isCompleted: true,
                              isLast: false,
                            ),
                            _buildTimelineStep(
                              icon: Icons.local_shipping_rounded,
                              title: 'In Transit',
                              subtitle: 'Expected delivery tomorrow by 5:00 PM',
                              isCurrent: true,
                              isLast: false,
                            ),
                            _buildTimelineStep(
                              icon: Icons.home_rounded,
                              title: 'Out for Delivery',
                              subtitle: 'Delivery PIN will be sent via SMS',
                              isPending: true,
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // 3. Ordered Item Summary Card
                  BrikCard(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Delivery Destination',
                          style: TextStyle(
                            color: BrikTheme.brandNavy,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${SupabaseAuthService().userName} • +91 98765 43210\n42 Tech Park Avenue, Koramangala, Bengaluru, Karnataka - 560034',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                        const Divider(color: BrikTheme.cardBorder, height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'Express Delivery Protocol',
                              style: TextStyle(color: BrikTheme.textSecondaryOnDark, fontSize: 12),
                            ),
                            Text(
                              'Grounded 24h ETA',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 4. Action Buttons
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: BrikButton(
                              text: 'Download Invoice',
                              style: BrikButtonStyle.secondary,
                              icon: const Icon(Icons.download_rounded, color: Colors.white, size: 16),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: BrikTheme.cardSurface,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    content: Text(
                                      'Invoice for Order #$orderId downloaded.',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: BrikButton(
                              text: 'Ask AI',
                              style: BrikButtonStyle.primaryLilac,
                              icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                              onPressed: () {
                                onAskAi?.call('Where is my order #$orderId?');
                                onBackToHome();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      BrikButton(
                        text: 'Back to Home',
                        isFullWidth: true,
                        style: BrikButtonStyle.secondary,
                        onPressed: onBackToHome,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineStep({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isCompleted = false,
    bool isCurrent = false,
    bool isPending = false,
    bool isLast = false,
  }) {
    Color iconColor;
    if (isCompleted) {
      iconColor = Colors.white;
    } else if (isCurrent) {
      iconColor = BrikTheme.brandNavy;
    } else {
      iconColor = BrikTheme.brandNavy.withValues(alpha: 0.4);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(icon, color: iconColor, size: 20),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isCompleted ? Colors.white : BrikTheme.cardBorder,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isPending ? BrikTheme.textSecondaryOnDark : Colors.white,
                      fontSize: 13.5,
                      fontWeight: isCurrent || isCompleted ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isPending ? BrikTheme.textSecondaryOnDark.withValues(alpha: 0.6) : BrikTheme.textSecondaryOnDark,
                      fontSize: 11.5,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
