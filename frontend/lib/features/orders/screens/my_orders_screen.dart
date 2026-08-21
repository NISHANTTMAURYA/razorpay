import 'package:flutter/material.dart';
import '../../../core/theme/brik_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/widgets/brik_card.dart';
import '../../../shared/widgets/brik_button.dart';
import '../../../shared/widgets/pill_badge.dart';

class MyOrdersScreen extends StatefulWidget {
  final VoidCallback? onStartShopping;

  const MyOrdersScreen({super.key, this.onStartShopping});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    final ordersList = await ApiService().getOrders();
    if (mounted) {
      setState(() {
        _orders = ordersList;
        _isLoading = false;
      });
    }
  }

  void _showTrackingModal(Map<String, dynamic> order) {
    final orderId = order['id']?.toString().substring(0, 8).toUpperCase() ?? 'MITRAI';
    final trackingNo = order['tracking_number'] ?? 'TRK-$orderId';
    final status = order['status']?.toString() ?? 'CONFIRMED';
    final isDelivered = status == 'DELIVERED';
    final isShipped = status == 'SHIPPED' || isDelivered;
    final isConfirmed = status == 'CONFIRMED' || isShipped || isDelivered;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: const BoxDecoration(
          color: BrikTheme.canvasBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: BrikTheme.brandNavy.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Live Shipment Tracker',
                  style: TextStyle(color: BrikTheme.brandNavy, fontSize: 17, fontWeight: FontWeight.w800),
                ),
                PillBadge(
                  text: status,
                  backgroundColor: const Color(0xFF10B981),
                  textColor: Colors.white,
                  fontSize: 10,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Waybill #$trackingNo • Express Partner',
              style: const TextStyle(color: BrikTheme.textSecondaryOnDark, fontSize: 12),
            ),
            const SizedBox(height: 20),

            _buildTrackingStep(
              title: 'Order Confirmed & Razorpay Verified',
              subtitle: 'Payment processed and sent to merchant warehouse.',
              isActive: isConfirmed,
              isDone: true,
            ),
            _buildTrackingStep(
              title: 'Packed & Dispatched from Merchant Hub',
              subtitle: 'Item scanned and handed to express courier.',
              isActive: isShipped,
              isDone: isShipped,
            ),
            _buildTrackingStep(
              title: 'In Transit to Local Hub',
              subtitle: 'Arrived at central distribution center.',
              isActive: isShipped,
              isDone: isDelivered,
            ),
            _buildTrackingStep(
              title: 'Out for Delivery / Delivered',
              subtitle: 'Courier partner out for delivery to your registered address.',
              isActive: isDelivered,
              isDone: isDelivered,
              isLast: true,
            ),

            const SizedBox(height: 20),
            BrikButton(
              text: 'CLOSE',
              isFullWidth: true,
              style: BrikButtonStyle.primaryLilac,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingStep({
    required String title,
    required String subtitle,
    required bool isActive,
    required bool isDone,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone
                    ? const Color(0xFF10B981)
                    : (isActive ? BrikTheme.brandNavy : BrikTheme.cardSurfaceSecondary),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isDone ? const Color(0xFF10B981) : BrikTheme.cardBorder,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isActive ? BrikTheme.brandNavy : BrikTheme.textSecondaryOnDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: BrikTheme.textSecondaryOnDark, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrikTheme.canvasBackground,
      appBar: AppBar(
        backgroundColor: BrikTheme.canvasBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: BrikTheme.brandNavy, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Orders & Shipments',
          style: TextStyle(color: BrikTheme.brandNavy, fontWeight: FontWeight.w800, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: BrikTheme.brandNavy),
            onPressed: _fetchOrders,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: BrikTheme.brandNavy))
            : _orders.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: BrikTheme.cardSurfaceSecondary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.receipt_long_rounded, color: BrikTheme.brandNavy, size: 48),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'No Orders Placed Yet',
                            style: TextStyle(color: BrikTheme.brandNavy, fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Discover 24+ top direct brands and complete your first 1-Tap Razorpay checkout!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: BrikTheme.textSecondaryOnDark, fontSize: 12.5, height: 1.4),
                          ),
                          const SizedBox(height: 22),
                          BrikButton(
                            text: 'START SHOPPING 🛍️',
                            style: BrikButtonStyle.primaryLilac,
                            onPressed: () {
                              Navigator.pop(context);
                              if (widget.onStartShopping != null) {
                                widget.onStartShopping!();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      final id = order['id']?.toString().substring(0, 8).toUpperCase() ?? 'MITRAI';
                      final total = order['total_amount']?.toString() ?? '0.00';
                      final status = order['status']?.toString() ?? 'CONFIRMED';
                      final merchantName = order['merchant']?['name']?.toString() ?? 'Direct Partner Brand';
                      final items = order['items'] as List<dynamic>? ?? [];

                      return BrikCard(
                        padding: const EdgeInsets.all(18),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: Order ID & Status
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.receipt_rounded, color: BrikTheme.brandNavy, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Order #$id',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                PillBadge(
                                  text: status,
                                  backgroundColor: const Color(0xFF10B981),
                                  textColor: Colors.white,
                                  fontSize: 9.5,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Merchant: $merchantName',
                              style: const TextStyle(color: BrikTheme.textSecondaryOnDark, fontSize: 11.5),
                            ),
                            const Divider(color: BrikTheme.cardBorder, height: 20),

                            // Items List
                            if (items.isNotEmpty) ...[
                              ...items.map((it) {
                                final prodName = it['product_name'] ?? it['product']?['name'] ?? 'Product Item';
                                final qty = it['quantity'] ?? 1;
                                final price = it['unit_price'] ?? '0';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '$qty× $prodName',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '₹$price',
                                        style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const Divider(color: BrikTheme.cardBorder, height: 16),
                            ],

                            // Total & Tracking Trigger
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Total Paid (Razorpay)',
                                        style: TextStyle(color: BrikTheme.textSecondaryOnDark, fontSize: 10.5)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '₹$total',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                                BrikButton(
                                  text: 'TRACK SHIPMENT 🚚',
                                  style: BrikButtonStyle.primaryLilac,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  onPressed: () => _showTrackingModal(order),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
