import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/brik_theme.dart';
import '../../../core/services/supabase_auth_service.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/providers/watcher_provider.dart';
import '../../../core/providers/catalog_provider.dart';
import '../../../shared/widgets/brik_card.dart';
import '../../../shared/widgets/brik_button.dart';
import '../../../shared/widgets/pill_badge.dart';
import '../../../shared/widgets/brik_progress_bar.dart';
import '../../../shared/widgets/segmented_pill_nav.dart';
import '../../../shared/widgets/brik_header_card.dart';
import '../../chat/screens/ai_shopping_screen.dart';
import '../../cart/screens/cart_screen.dart';
import '../../product/screens/product_detail_sheet.dart';
import '../../settings/screens/settings_screen.dart';
import '../../../core/motion/luxury_page_transitions.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onSignOut;

  const HomeScreen({super.key, required this.onSignOut});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;

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
    final cartProvider = context.watch<CartProvider>();

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
                // 1. Full-Height Scrollable Page Content with Parallax Transition
                Positioned.fill(
                  child: BentoParallaxTabTransition(
                    currentIndex: _currentNavIndex,
                    child: _buildCurrentPage(),
                  ),
                ),

                // 2. Floating Segmented Bottom Navigation Bar
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 8,
                  child: SegmentedPillNav(
                    selectedIndex: _currentNavIndex,
                    cartItemCount: cartProvider.itemCount,
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
            context.read<CartProvider>().loadCart();
          },
          onSettingsPressed: _openSettings,
        );
      case 2:
        return _buildShoppingDiscoveryTab();
      case 3:
        return CartScreen(
          onCheckoutComplete: () {
            context.read<CartProvider>().loadCart();
          },
          onSettingsPressed: _openSettings,
        );
      default:
        return _buildDashboardTab();
    }
  }

  Widget _buildDashboardTab() {
    final userName = SupabaseAuthService().userName;
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    final effectiveBottomPadding = bottomSafeArea + 110.0;

    final cart = context.watch<CartProvider>();
    final catalog = context.watch<CatalogProvider>();
    final watcher = context.watch<WatcherProvider>();

    final topProduct = catalog.topRecommendation;
    final topProductName = topProduct?['name']?.toString() ?? 'boAt Rockerz 550 Wireless';
    final topProductDesc = topProduct?['description']?.toString() ?? '20h Playback • 50mm Dynamic Bass Drivers';
    final topProductPrice = topProduct?['price']?.toString() ?? '1,999';
    final topProductRating = topProduct?['rating']?.toString() ?? '4.6';

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, effectiveBottomPadding),
      child: Column(
        children: [
          // ── 1. Top Header Card ───────────────────────────────────────────
          BrikHeaderCard(
            tagText: 'AGENT ACTIVE',
            margin: const EdgeInsets.only(bottom: 10),
            onSettingsPressed: _openSettings,
          ),

          // ── 2 & 3. Greeting + Live Cart Tracker  →  Joined Card Group ────
          JoinedCardGroup(
            margin: const EdgeInsets.only(bottom: 10),
            children: [
              // Top slot: Greeting & Catalog Status
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
                    Text(
                      'Connected to ${catalog.products.isNotEmpty ? catalog.products.length : 7} verified merchant products across 4 stores.',
                      style: const TextStyle(
                        color: BrikTheme.textSecondaryOnDark,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom slot: Live Cart / Bag Tracker
              JoinedCard(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _currentNavIndex = 3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Flexible(
                            child: Text(
                              'Active Shopping Bag',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: BrikTheme.textPrimaryOnDark,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            cart.itemCount == 0 ? 'Empty Bag' : '₹${cart.subtotal.toStringAsFixed(0)} Subtotal',
                            style: const TextStyle(
                              color: BrikTheme.brandNavy,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cart.itemCount == 0
                            ? 'Tap to discover products and add items to cart.'
                            : '${cart.itemCount} item(s) ready for Razorpay 1-tap checkout.',
                        style: const TextStyle(
                          color: BrikTheme.textSecondaryOnDark,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            cart.itemCount > 0 ? '${cart.itemCount}' : '0',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.0,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: BrikProgressBar(
                              percentage: cart.itemCount > 0 ? 100 : 0,
                              activeColor: BrikTheme.brandNavy,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── 4. Recommendation Card (Backed by Real Top DB Product) ──────
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
                      children: [
                        const Text(
                          'Top Researched Deal',
                          style: TextStyle(
                            color: BrikTheme.brandNavy,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        PillBadge(
                          text: '$topProductRating ★ RATED',
                          backgroundColor: BrikTheme.brandNavy,
                          textColor: Colors.white,
                          fontSize: 10,
                        ),
                      ],
                    ),
                    BrikButton(
                      text: 'VIEW DEAL',
                      style: BrikButtonStyle.primaryLilac,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      onPressed: () {
                        if (topProduct != null) {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => ProductDetailSheet(
                              product: topProduct,
                              onAddToCart: () {
                                final pid = topProduct['id'];
                                final prodId = pid is int ? pid : (int.tryParse(pid?.toString() ?? '1') ?? 1);
                                context.read<CartProvider>().addItem(prodId);
                              },
                            ),
                          );
                        } else {
                          setState(() => _currentNavIndex = 2);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  topProductName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹$topProductPrice • $topProductDesc',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: BrikTheme.textSecondaryOnDark,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // ── 5. Side-by-Side Dual Live Metrics (Horizontal Joined Card) ──
          HorizontalJoinedCardGroup(
            margin: const EdgeInsets.only(bottom: 10),
            notchDepth: 22.0,
            notchHalfWidth: 4.0,
            notchCornerRadius: 14.0,
            outerRadius: 26.0,
            children: [
              // Left slot: Catalog Status
              JoinedCard(
                padding: const EdgeInsets.fromLTRB(18, 18, 12, 18),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _currentNavIndex = 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Live Catalog',
                        style: TextStyle(
                          color: BrikTheme.brandNavy,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Verified Stores',
                        style: TextStyle(
                          color: BrikTheme.textSecondaryOnDark,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 14),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${catalog.products.isNotEmpty ? catalog.products.length : 7} Items',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Right slot: Background Celery Watchers
              JoinedCard(
                padding: const EdgeInsets.fromLTRB(12, 18, 18, 18),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _openSettings,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Radar Watchers',
                        style: TextStyle(
                          color: BrikTheme.brandNavy,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Celery Background',
                        style: TextStyle(
                          color: BrikTheme.textSecondaryOnDark,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 14),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${watcher.activeCount > 0 ? watcher.activeCount : 1} Active',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
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

          // ── 6. Live AI Radar & Price Watch Card (Real Backend Watchers) ─
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
                          'Price Drop Radar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const PillBadge(
                      text: 'CELERY + REDIS',
                      fontSize: 9.5,
                      backgroundColor: BrikTheme.brandNavy,
                      textColor: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Continuous background price & stock monitoring across all products.',
                  style: TextStyle(
                    color: BrikTheme.textSecondaryOnDark,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _openSettings,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: BrikTheme.cardSurfaceSecondary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                watcher.watchers.isNotEmpty
                                    ? (watcher.watchers.first['product']?['name'] ?? watcher.watchers.first['search_query'] ?? 'boAt Rockerz 550')
                                    : 'boAt Rockerz 550 Wireless',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Price drop alert active · Tap to manage',
                                style: TextStyle(color: BrikTheme.textSecondaryOnDark, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const PillBadge(
                          text: 'RADAR',
                          fontSize: 9.5,
                          backgroundColor: BrikTheme.brandNavy,
                          textColor: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── 7. AI Shopping Copilot Card ──────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _currentNavIndex = 1),
            child: BrikCard(
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
                        child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('AI Shopping Assistant',
                              style: TextStyle(color: BrikTheme.textSecondaryOnDark, fontSize: 11)),
                          SizedBox(height: 2),
                          Text('Discover, compare & pay via chat',
                              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ],
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: BrikTheme.brandNavy, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShoppingDiscoveryTab() {
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    final effectiveBottomPadding = bottomSafeArea + 110.0;
    final catalog = context.watch<CatalogProvider>();

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
            child: catalog.isLoading && catalog.products.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: BrikTheme.brandNavy),
                  )
                : catalog.products.isEmpty
                    ? const Center(
                        child: Text(
                          'No products found in merchant catalog',
                          style: TextStyle(color: BrikTheme.textSecondaryOnDark),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.only(bottom: effectiveBottomPadding),
                        itemCount: catalog.products.length,
                        itemBuilder: (context, index) {
                          final p = catalog.products[index];
                          final title = p['name']?.toString() ?? 'Product';
                          final brand = p['brand']?.toString() ?? (p['merchant']?['name']?.toString() ?? 'Mitrai');
                          final price = double.tryParse(p['price']?.toString() ?? '0')?.toStringAsFixed(0) ?? '0';
                          final origPrice = double.tryParse(p['original_price']?.toString() ?? '0')?.toStringAsFixed(0) ?? (p['original_price']?.toString() ?? '');
                          final rating = p['rating']?.toString() ?? '4.6';
                          final attrs = p['attributes'] as Map<String, dynamic>?;
                          final subtitle = attrs != null && attrs.isNotEmpty
                              ? attrs.values.take(2).join(' • ')
                              : (p['description']?.toString() ?? 'Verified Merchant Grounded Spec');

                          return _buildRealProductCard(
                            product: p,
                            title: title,
                            brand: brand,
                            subtitle: subtitle,
                            price: '₹$price',
                            originalPrice: origPrice.isNotEmpty ? '₹$origPrice' : '',
                            rating: '$rating ★',
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealProductCard({
    required Map<String, dynamic> product,
    required String title,
    required String brand,
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
            product: product,
            onAddToCart: () {
              final pid = product['id'];
              final prodId = pid is int ? pid : (int.tryParse(pid?.toString() ?? '1') ?? 1);
              context.read<CartProvider>().addItem(prodId);
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
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: BrikTheme.textSecondaryOnDark, fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(price, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                      if (originalPrice.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          originalPrice,
                          style: const TextStyle(
                            color: BrikTheme.textSecondaryOnDark,
                            decoration: TextDecoration.lineThrough,
                            fontSize: 12,
                          ),
                        ),
                      ],
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
