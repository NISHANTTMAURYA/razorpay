import 'package:flutter/material.dart';
import '../../../core/theme/brik_theme.dart';
import '../../../core/services/supabase_auth_service.dart';
import '../../../shared/widgets/brik_header_card.dart';
import '../../../shared/widgets/brik_card.dart';
import '../../../shared/widgets/brik_button.dart';
import '../../../shared/widgets/pill_badge.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onSignOut;

  const SettingsScreen({super.key, required this.onSignOut});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _priceAlerts = true;
  bool _voiceShopping = true;
  bool _fastCheckout = true;

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BrikTheme.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Log Out of Mitrai?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: const Text(
          'Are you sure you want to end your active shopping session? Your cart and preferences will remain saved.',
          style: TextStyle(color: BrikTheme.textSecondaryOnDark, fontSize: 13.5, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL', style: TextStyle(color: BrikTheme.brandNavy, fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('LOG OUT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await SupabaseAuthService().signOut();
      if (mounted) {
        Navigator.pop(context); // Close settings screen
        widget.onSignOut(); // Notify root to show login
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = SupabaseAuthService().userName;
    final userEmail = SupabaseAuthService().userEmail;
    final isGuest = SupabaseAuthService().isGuest;

    return Scaffold(
      backgroundColor: BrikTheme.canvasBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Header Card
                  BrikHeaderCard(
                    tagText: 'SETTINGS',
                    margin: const EdgeInsets.only(bottom: 12),
                    onBack: () => Navigator.pop(context),
                  ),

                  // 2. Profile & Authentication Joined Card Group (Curved Ticket Notch Effect)
                  JoinedCardGroup(
                    margin: const EdgeInsets.only(bottom: 12),
                    notchDepth: 28.0,
                    notchHalfHeight: 4.5,
                    notchCornerRadius: 16.0,
                    outerRadius: 28.0,
                    children: [
                      // Top Slot: User Account Info
                      JoinedCard(
                        padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: BrikTheme.brandNavy,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  userName.isNotEmpty ? userName[0].toUpperCase() : 'M',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          userName,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      PillBadge(
                                        text: isGuest ? 'GUEST' : 'GOOGLE AUTH',
                                        backgroundColor: BrikTheme.brandNavy,
                                        textColor: Colors.white,
                                        fontSize: 9,
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    userEmail,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: BrikTheme.textSecondaryOnDark,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bottom Slot: Default Delivery Address
                      JoinedCard(
                        padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text(
                                  'Default Delivery Address',
                                  style: TextStyle(
                                    color: BrikTheme.brandNavy,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                PillBadge(
                                  text: 'PRIMARY',
                                  backgroundColor: BrikTheme.brandNavy,
                                  textColor: Colors.white,
                                  fontSize: 9,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Bohdan • +91 98765 43210\n42 Tech Park Avenue, Koramangala, Bengaluru, 560034',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // 3. AI & Commerce Engine Toggles Card
                  BrikCard(
                    padding: const EdgeInsets.all(18),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Commerce & AI Preferences',
                          style: TextStyle(
                            color: BrikTheme.brandNavy,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Toggle 1: Fast Razorpay Checkout
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('Razorpay Express Checkout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5)),
                                  SizedBox(height: 2),
                                  Text('Cryptographic HMAC-SHA256 direct tokenization', style: TextStyle(color: BrikTheme.textSecondaryOnDark, fontSize: 11)),
                                ],
                              ),
                            ),
                            Switch(
                              value: _fastCheckout,
                              activeThumbColor: Colors.white,
                              activeTrackColor: BrikTheme.brandNavy,
                              onChanged: (val) => setState(() => _fastCheckout = val),
                            ),
                          ],
                        ),
                        const Divider(color: BrikTheme.cardBorder, height: 20),

                        // Toggle 2: AI Price Radar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('Multi-Store Price Radar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5)),
                                  SizedBox(height: 2),
                                  Text('Real-time Amazon & Flipkart price checks', style: TextStyle(color: BrikTheme.textSecondaryOnDark, fontSize: 11)),
                                ],
                              ),
                            ),
                            Switch(
                              value: _priceAlerts,
                              activeThumbColor: Colors.white,
                              activeTrackColor: BrikTheme.brandNavy,
                              onChanged: (val) => setState(() => _priceAlerts = val),
                            ),
                          ],
                        ),
                        const Divider(color: BrikTheme.cardBorder, height: 20),

                        // Toggle 3: Conversational Voice Shopping
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('Voice & Natural Language Agent', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5)),
                                  SizedBox(height: 2),
                                  Text('LangGraph multi-step intent routing', style: TextStyle(color: BrikTheme.textSecondaryOnDark, fontSize: 11)),
                                ],
                              ),
                            ),
                            Switch(
                              value: _voiceShopping,
                              activeThumbColor: Colors.white,
                              activeTrackColor: BrikTheme.brandNavy,
                              onChanged: (val) => setState(() => _voiceShopping = val),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 4. Active Watcher Radar Manager Card
                  BrikCard(
                    padding: const EdgeInsets.all(18),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: BrikTheme.brandNavy,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Active Radar Watchers',
                                  style: TextStyle(color: BrikTheme.brandNavy, fontSize: 13, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            const PillBadge(
                              text: '1 ACTIVE',
                              backgroundColor: BrikTheme.brandNavy,
                              textColor: Colors.white,
                              fontSize: 9.5,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Celery + Redis background workers monitoring your products.',
                          style: TextStyle(color: BrikTheme.textSecondaryOnDark, fontSize: 11.5),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: BrikTheme.cardSurfaceSecondary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'boAt Rockerz 550',
                                      style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'PRICE_DROP · Target ₹1,800 · Now ₹1,999',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: BrikTheme.textSecondaryOnDark, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {},
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: BrikTheme.cardSurface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: BrikTheme.cardBorder),
                                  ),
                                  child: const Icon(Icons.close_rounded, color: BrikTheme.textSecondaryOnDark, size: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 5. System & Architecture Information Card
                  BrikCard(
                    padding: const EdgeInsets.all(18),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'System & Session Telemetry',
                          style: TextStyle(
                            color: BrikTheme.brandNavy,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow('Database Layer', 'Supabase Cloud Sync (Active)'),
                        const SizedBox(height: 6),
                        _buildInfoRow('Session Persistence', 'SharedPreferences Encrypted Cache'),
                        const SizedBox(height: 6),
                        _buildInfoRow('Engine Architecture', 'LangGraph Multi-Catalog v2.4'),
                        const SizedBox(height: 6),
                        _buildInfoRow('Security Standard', 'PCI-DSS 3.2 • Razorpay HMAC-SHA256'),
                      ],
                    ),
                  ),

                  // 5. Logout Action Button
                  BrikButton(
                    text: 'Log Out of Mitrai',
                    isFullWidth: true,
                    style: BrikButtonStyle.primaryLilac,
                    icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
                    onPressed: _handleLogout,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: BrikTheme.textSecondaryOnDark, fontSize: 11.5)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11.5)),
      ],
    );
  }
}
