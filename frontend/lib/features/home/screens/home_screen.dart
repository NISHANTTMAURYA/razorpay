import 'package:flutter/material.dart';
import '../../../core/theme/brik_theme.dart';
import '../../../core/services/supabase_auth_service.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/widgets/brik_card.dart';
import '../../../shared/widgets/brik_button.dart';
import '../../../shared/widgets/pill_badge.dart';
import '../../../shared/widgets/brik_progress_bar.dart';
import '../../../shared/widgets/segmented_pill_nav.dart';
import '../../../shared/widgets/brik_header_card.dart';
import '../../chat/screens/ai_shopping_screen.dart';
import '../../cart/screens/cart_screen.dart';
import '../../product/screens/product_detail_sheet.dart';
import '../../orders/screens/order_tracking_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../../core/motion/luxury_page_transitions.dart';

// ────────────────────────────────────────────────────────────────────────────
//  NOTE: JoinedCardGroup and JoinedCard are defined in brik_card.dart
// ────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  final VoidCallback onSignOut;

  const HomeScreen({super.key, required this.onSignOut});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;
  int _cartCount = 1;

  void _openSettings() {
    Navigator.push(
      context,
      SpatialPageRoute(
        page: SettingsScreen(
          onSignOut: widget.onSignOut,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrikTheme.canvasBackground,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // 1. Full-Height Scrollable Page Content with Luxury Parallax Tab Transition
                Positioned.fill(
                  child: BentoParallaxTabTransition(
                    currentIndex: _currentNavIndex,
                    child: _buildCurrentPage(),
                  ),
                ),

                // 2. Pure Floating Segmented Bottom Navigation Bar
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 8,
                  child: SegmentedPillNav(
                    selectedIndex: _currentNavIndex,
                    cartItemCount: _cartCount,
                    onIndexChanged: (index) {
                      setState(() {
                        _currentNavIndex = index;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentNavIndex) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return AiShoppingScreen(
          onCartUpdated: (count) {
            setState(() => _cartCount = count);
          },
          onSettingsPressed: _openSettings,
        );
      case 2:
        return _buildShoppingDiscoveryTab();
      case 3:
        return CartScreen(
          onCheckoutComplete: () {
            setState(() => _cartCount = 0);
          },
          onSettingsPressed: _openSettings,
        );
      default:
        return _buildDashboardTab();
    }
  }

  Widget _buildDashboardTab() {
    final userName = SupabaseAuthService().userName;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
      child: Column(
        children: [
          // ── 1. Top Header Card (Consistent Standalone Component) ───────
          BrikHeaderCard(
            tagText: 'AGENT ACTIVE',
            margin: const EdgeInsets.only(bottom: 10),
            onSettingsPressed: _openSettings,
          ),

          // ── 2 & 3. Greeting + Budget Progress  →  Joined Card Group ────
          JoinedCardGroup(
            margin: const EdgeInsets.only(bottom: 10),
            children: [
              // Top slot: Greeting
              JoinedCard(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$userName,\nwelcome back',
                      style: const TextStyle(
                        color: BrikTheme.textPrimaryOnDark,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Shopping Assistant is ready with 7 grounded merchant catalogs.',
                      style: TextStyle(
                        color: BrikTheme.textSecondaryOnDark,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom slot: Budget Progress Bar
              JoinedCard(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Flexible(
                          child: Text(
                            'Monthly Shopping Budget',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: BrikTheme.textPrimaryOnDark,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '₹3,999 / ₹5,000',
                          style: TextStyle(
                            color: BrikTheme.brandNavy,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Optimal savings algorithm active.',
                      style: TextStyle(
                        color: BrikTheme.textSecondaryOnDark,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: const [
                        Text(
                          '80%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.0,
                          ),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: BrikProgressBar(
                            percentage: 80,
                            activeColor: BrikTheme.brandNavy,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── 4. Recommendation Card ───────────────────────────────────────
          BrikCard(
            padding: const EdgeInsets.all(22),
            margin: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Instant Recommendation',
                          style: TextStyle(
                            color: BrikTheme.brandNavy,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        PillBadge(
                          text: 'UNDER ₹3,000',
                          backgroundColor: BrikTheme.brandNavy,
                          textColor: Colors.white,
                          fontSize: 10,
                        ),
                      ],
                    ),
                    BrikButton(
                      text: 'EXPLORE',
                      style: BrikButtonStyle.primaryLilac,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      onPressed: () => setState(() => _currentNavIndex = 1),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'boAt Rockerz 550 vs Sony WH-CH520',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── 5. Side-by-Side Dual Metrics (Horizontal Joined Card Group) ─
          HorizontalJoinedCardGroup(
            margin: const EdgeInsets.only(bottom: 10),
            notchDepth: 22.0,
            notchHalfWidth: 4.0,
            notchCornerRadius: 14.0,
            outerRadius: 26.0,
            children: [
              // Left slot: Active Cart
              JoinedCard(
                padding: const EdgeInsets.fromLTRB(18, 18, 12, 18),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _currentNavIndex = 3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Active Cart',
                        style: TextStyle(
                          color: BrikTheme.brandNavy,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$_cartCount Items',
                        style: const TextStyle(
                          color: BrikTheme.textSecondaryOnDark,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '₹2,999',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Right slot: Payment Engine
              JoinedCard(
                padding: const EdgeInsets.fromLTRB(12, 18, 18, 18),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Navigator.push(
                      context,
                      SpatialPageRoute(
                        page: OrderTrackingScreen(
                          onBackToHome: () => Navigator.pop(context),
                          onAskAi: (q) => setState(() => _currentNavIndex = 1),
                        ),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Payment Engine',
                        style: TextStyle(
                          color: BrikTheme.brandNavy,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Razorpay Secured',
                        style: TextStyle(
                          color: BrikTheme.textSecondaryOnDark,
                          fontSize: 11,
                        ),
                      ),
                      SizedBox(height: 14),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '100% HMAC',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── 6. Live AI Radar & Price Watch Card ─────────────────────────
          BrikCard(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 10),
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
                          'AI Radar & Price Watch',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const PillBadge(
                      text: 'CELERY ACTIVE',
                      fontSize: 9.5,
                      backgroundColor: BrikTheme.brandNavy,
                      textColor: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Monitoring 1 product for price drops & stock updates.',
                  style: TextStyle(
                    color: BrikTheme.textSecondaryOnDark,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: BrikTheme.cardSurfaceSecondary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'boAt Rockerz 550',
                            style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Current: ₹1,999 • Target: ₹1,800',
                            style: TextStyle(color: BrikTheme.textSecondaryOnDark, fontSize: 11),
                          ),
                        ],
                      ),
                      PillBadge(
                        text: 'WATCHING',
                        fontSize: 9.5,
                        backgroundColor: BrikTheme.brandNavy,
                        textColor: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── 7. Feature Card ──────────────────────────────────────────────
          BrikCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            margin: EdgeInsets.zero,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: BrikTheme.brandNavy,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Conversational Shopping',
                            style: TextStyle(color: BrikTheme.textSecondaryOnDark, fontSize: 11)),
                        SizedBox(height: 2),
                        Text('Zero-Friction Checkout',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => setState(() => _currentNavIndex = 1),
                  icon: const Icon(Icons.arrow_forward_ios_rounded, color: BrikTheme.brandNavy, size: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShoppingDiscoveryTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          BrikHeaderCard(
            tagText: 'GROUNDED CATALOG',
            margin: const EdgeInsets.only(bottom: 10),
            onSettingsPressed: _openSettings,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 88),
              children: [
                _buildDealItem(
                  title: 'boAt Rockerz 550 Wireless',
                  subtitle: '20 Hours Battery • Passive Noise Isolation',
                  price: '₹1,999',
                  originalPrice: '₹4,999',
                  rating: '4.6 ★',
                ),
                _buildDealItem(
                  title: 'Sony WH-CH520 Bluetooth',
                  subtitle: '50 Hours Playback • DSEE Audio Engine',
                  price: '₹2,999',
                  originalPrice: '₹4,490',
                  rating: '4.8 ★',
                ),
                _buildDealItem(
                  title: 'OnePlus Nord CE 3 Lite 5G',
                  subtitle: '108 MP Camera • 67W SUPERVOOC',
                  price: '₹19,999',
                  originalPrice: '₹21,999',
                  rating: '4.6 ★',
                ),
                _buildDealItem(
                  title: 'Nike Revolution 6 Next Nature',
                  subtitle: 'Plush Foam • Daily Running & Training',
                  price: '₹3,695',
                  originalPrice: '₹4,995',
                  rating: '4.7 ★',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDealItem({
    required String title,
    required String subtitle,
    required String price,
    required String originalPrice,
    required String rating,
  }) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => ProductDetailSheet(
            product: {
              'name': title,
              'brand': title.split(' ').first,
              'price': price.replaceAll('₹', ''),
              'original_price': originalPrice.replaceAll('₹', ''),
              'rating': rating,
            },
            onAddToCart: () async {
              await ApiService().addToCart(productId: 1);
              setState(() => _cartCount = _cartCount + 1);
            },
          ),
        );
      },
      child: BrikCard(
        padding: const EdgeInsets.all(18),
        margin: const EdgeInsets.only(bottom: 10),
        backgroundColor: BrikTheme.cardSurface,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: BrikTheme.cardSurfaceSecondary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.shopping_bag_outlined, color: BrikTheme.brandNavy),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(color: BrikTheme.textSecondaryOnDark, fontSize: 11)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(price, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                      const SizedBox(width: 8),
                      Text(
                        originalPrice,
                        style: const TextStyle(
                          color: BrikTheme.textSecondaryOnDark,
                          decoration: TextDecoration.lineThrough,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      PillBadge(text: rating, fontSize: 9.5, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
