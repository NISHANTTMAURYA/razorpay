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
import '../../orders/screens/my_orders_screen.dart';
import '../../onboarding/screens/permission_prompt_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/motion/luxury_page_transitions.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onSignOut;

  const HomeScreen({super.key, required this.onSignOut});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;
  final TextEditingController _discoverSearchController = TextEditingController();
  String _discoverSearchQuery = '';
  String _selectedCategory = 'ALL';
  bool _hasSetupCopilot = false;

  @override
  void initState() {
    super.initState();
    _checkCopilotSetupStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PermissionPromptSheet.showIfNeeded(context, onComplete: () {
        _checkCopilotSetupStatus();
      });
      context.read<WatcherProvider>().loadNotifications();
    });
  }

  Future<void> _checkCopilotSetupStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSetup = prefs.getBool('has_setup_copilot') ?? false;
      if (mounted) {
        setState(() => _hasSetupCopilot = hasSetup);
      }
    } catch (_) {}
  }

  void _openMyOrders() {
    Navigator.push(
      context,
      SpatialPageRoute(
        page: MyOrdersScreen(
          onStartShopping: () => setState(() => _currentNavIndex = 1),
        ),
      ),
    );
  }

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
          onMyOrdersPressed: _openMyOrders,
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

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, effectiveBottomPadding),
      child: Column(
        children: [
          // ── 1. Top Header Card ───────────────────────────────────────────
          BrikHeaderCard(
            margin: const EdgeInsets.only(bottom: 10),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _openMyOrders,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: BrikTheme.brandNavy,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: BrikTheme.accentLavender.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.receipt_long_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 5),
                        Text(
                          'ORDERS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _openSettings,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.settings_outlined,
                      color: BrikTheme.textSecondaryOnDark,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── 2. Greeting & Status Card (Standalone) ───────────────────────
          BrikCard(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
            margin: const EdgeInsets.only(bottom: 10),
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
                  catalog.products.isNotEmpty
                      ? 'Connected to ${catalog.products.length} live merchant products across integrated direct brands.'
                      : 'Connected to live merchant APIs and real-time scrapers.',
                  style: const TextStyle(
                    color: BrikTheme.textSecondaryOnDark,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),

          // ── 2.5. Background Shopping Copilot Status Card (Shown Only Before First Setup) ─────
          if (!_hasSetupCopilot) ...[
            BrikCard(
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: BrikTheme.brandNavy.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Background Copilot (Zave Mode)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Overlay copilot & price comparisons for Amazon, Blinkit, Zepto',
                          style: TextStyle(
                            color: BrikTheme.textSecondaryOnDark,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  BrikButton(
                    text: 'SETUP ⚡',
                    style: BrikButtonStyle.primaryLilac,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    onPressed: () async {
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('has_setup_copilot', true);
                      } catch (_) {}
                      if (mounted) {
                        setState(() => _hasSetupCopilot = true);
                        PermissionPromptSheet.showIfNeeded(context, force: true, onComplete: () {
                          _checkCopilotSetupStatus();
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ],

          // ── 3 & 4. Active Shopping Bag + Live Merchant Deal  →  Joined Card Group ────
          JoinedCardGroup(
            margin: const EdgeInsets.only(bottom: 10),
            children: [
              // Top slot (Card 3): Live Cart / Bag Tracker
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

              // Bottom slot (Card 4): Live Merchant Deals & Catalog
              JoinedCard(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                child: topProduct != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    topProduct['is_platform_product'] != false ? '● MERCHANT DIRECT' : '🌐 SCRAPED DEAL',
                                    style: const TextStyle(
                                      color: BrikTheme.brandNavy,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  PillBadge(
                                    text: '${topProduct['rating'] ?? 4.5} ★ RATED',
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
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => ProductDetailSheet(
                                      product: topProduct,
                                      onAddToCart: () {
                                        final prodId = topProduct['id'] ?? 1;
                                        final prodName = topProduct['name']?.toString();
                                        context.read<CartProvider>().addItem(prodId, productName: prodName);
                                      },
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            topProduct['name']?.toString() ?? 'Featured Product',
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
                            '₹${topProduct['price']} • ${topProduct['description'] ?? topProduct['brand'] ?? 'Verified'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: BrikTheme.textSecondaryOnDark,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Live Merchant Catalog',
                                  style: TextStyle(
                                    color: BrikTheme.brandNavy,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Ask Mitrai to search across 10 Direct Merchants & live Amazon/Flipkart.',
                                  style: TextStyle(
                                    color: BrikTheme.textSecondaryOnDark,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          BrikButton(
                            text: 'SEARCH',
                            style: BrikButtonStyle.primaryLilac,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            onPressed: () => setState(() => _currentNavIndex = 1),
                          ),
                        ],
                      ),
              ),
            ],
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
                          '${catalog.products.length} Items',
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
                          '${watcher.activeCount} Active',
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
                                    ? (watcher.watchers.first['product']?['name'] ?? watcher.watchers.first['search_query'] ?? 'Active Price Alert')
                                    : 'No active radar alerts right now',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                watcher.watchers.isNotEmpty ? 'Price drop alert active · Tap to manage' : 'Tap to set price alerts on any product',
                                style: const TextStyle(color: BrikTheme.textSecondaryOnDark, fontSize: 11),
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

    // Filter products based on search query & selected category
    final query = _discoverSearchQuery.trim().toLowerCase();
    final filteredProducts = catalog.products.where((p) {
      final categoryName = (p['category'] is Map ? p['category']['name'] : p['category']?.toString()) ?? '';
      
      // Category filter
      if (_selectedCategory != 'ALL') {
        if (!categoryName.toLowerCase().contains(_selectedCategory.toLowerCase())) {
          return false;
        }
      }

      // Query filter
      if (query.isNotEmpty) {
        final name = (p['name']?.toString() ?? '').toLowerCase();
        final brand = (p['brand']?.toString() ?? '').toLowerCase();
        final desc = (p['description']?.toString() ?? '').toLowerCase();
        final match = name.contains(query) || brand.contains(query) || desc.contains(query) || categoryName.toLowerCase().contains(query);
        if (!match) return false;
      }

      return true;
    }).toList();

    const categories = [
      'ALL',
      'AUDIO',
      'SMARTPHONES',
      'WEARABLES',
      'FOOTWEAR',
      'FASHION',
      'PERSONAL CARE',
      'FOOD & NUTRITION',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          // 1. Header Card with Orders Icon & Settings
          BrikHeaderCard(
            margin: const EdgeInsets.only(bottom: 10),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _openMyOrders,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: BrikTheme.brandNavy,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: BrikTheme.accentLavender.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.receipt_long_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 5),
                        Text(
                          'ORDERS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _openSettings,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.settings_outlined,
                      color: BrikTheme.textSecondaryOnDark,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Discover Value Proposition Card
          BrikCard(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Direct Brand Catalogs',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    PillBadge(
                      text: '${catalog.products.length} VERIFIED ITEMS',
                      backgroundColor: BrikTheme.brandNavy,
                      textColor: Colors.white,
                      fontSize: 9,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Browse genuine direct catalogs from 24+ top Indian brands (boAt, Noise, Red Tape, Mamaearth, Snitch, etc.) with 1-Tap Razorpay checkout & live multi-marketplace price radar.',
                  style: TextStyle(
                    color: BrikTheme.textSecondaryOnDark,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),

          // 3. Live Search Input Bar
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: BrikTheme.cardSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: BrikTheme.cardBorder),
            ),
            child: TextField(
              controller: _discoverSearchController,
              onChanged: (val) => setState(() => _discoverSearchQuery = val),
              style: const TextStyle(color: Colors.white, fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'Search products, brands, or specifications...',
                hintStyle: const TextStyle(color: BrikTheme.textSecondaryOnDark, fontSize: 12.5),
                prefixIcon: const Icon(Icons.search_rounded, color: BrikTheme.brandNavy, size: 20),
                suffixIcon: _discoverSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, color: BrikTheme.textSecondaryOnDark, size: 18),
                        onPressed: () {
                          _discoverSearchController.clear();
                          setState(() => _discoverSearchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),

          // 4. Horizontal Category Filter Chips
          Container(
            height: 34,
            margin: const EdgeInsets.only(bottom: 10),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, idx) {
                final cat = categories[idx];
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? BrikTheme.brandNavy : BrikTheme.cardSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? BrikTheme.accentLavender : BrikTheme.cardBorder,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected ? Colors.white : BrikTheme.textSecondaryOnDark,
                          fontSize: 10.5,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 5. Scrollable Product Cards with High-Res Images & Badges
          Expanded(
            child: catalog.isLoading && catalog.products.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: BrikTheme.brandNavy),
                  )
                : filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.search_off_rounded, color: BrikTheme.textSecondaryOnDark, size: 40),
                            const SizedBox(height: 8),
                            Text(
                              _discoverSearchQuery.isNotEmpty
                                  ? 'No products matching "$_discoverSearchQuery"'
                                  : 'No products in this category',
                              style: const TextStyle(color: BrikTheme.textSecondaryOnDark, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: BrikTheme.brandNavy,
                        onRefresh: () => context.read<CatalogProvider>().loadProducts(),
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.only(bottom: effectiveBottomPadding),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                          final p = filteredProducts[index];
                          final title = p['name']?.toString() ?? 'Product';
                          final brand = p['brand']?.toString() ?? (p['merchant']?['name']?.toString() ?? 'Mitrai');
                          final price = double.tryParse(p['price']?.toString() ?? '0')?.toStringAsFixed(0) ?? '0';
                          final origPrice = double.tryParse(p['original_price']?.toString() ?? '0')?.toStringAsFixed(0) ?? (p['original_price']?.toString() ?? '');
                          final rating = p['rating']?.toString() ?? '4.6';
                          final attrs = p['attributes'] as Map<String, dynamic>?;
                          final subtitle = attrs != null && attrs.isNotEmpty
                              ? attrs.entries.take(2).map((e) => '${e.key.replaceAll('_', ' ')}: ${e.value}').join(' • ')
                              : (p['description']?.toString() ?? 'Verified Merchant Grounded Spec');

                          // Extract product image URL
                          String imageUrl = '';
                          final rawImgs = p['images'];
                          if (rawImgs is List && rawImgs.isNotEmpty) {
                            imageUrl = rawImgs[0].toString();
                          } else if (p['image'] != null) {
                            imageUrl = p['image'].toString();
                          }

                            return _buildRealProductCard(
                              product: p,
                              title: title,
                              brand: brand,
                              subtitle: subtitle,
                              price: '₹$price',
                              originalPrice: origPrice.isNotEmpty && origPrice != price ? '₹$origPrice' : '',
                              rating: '$rating ★',
                              imageUrl: imageUrl,
                            );
                          },
                        ),
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
    required String imageUrl,
  }) {
    final isDirect = product['is_platform_product'] != false && product['source'] != 'SCRAPED_EXTERNAL';

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => ProductDetailSheet(
            product: product,
            onAddToCart: () {
              final prodId = product['id'] ?? 1;
              final prodName = product['name']?.toString();
              context.read<CartProvider>().addItem(prodId, productName: prodName);
            },
          ),
        );
      },
      child: BrikCard(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 10),
        backgroundColor: BrikTheme.cardSurface,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Visible High-Resolution Product Image with fallback
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 72,
                height: 72,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: BrikTheme.cardSurfaceSecondary,
                          child: const Center(
                            child: Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 24),
                          ),
                        ),
                      )
                    : Container(
                        color: BrikTheme.cardSurfaceSecondary,
                        child: const Center(
                          child: Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 24),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // Product Information & Action Triggers
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges: Brand & Merchant Direct / Scraped
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      PillBadge(
                        text: brand.toUpperCase(),
                        backgroundColor: BrikTheme.brandNavy,
                        textColor: Colors.white,
                        fontSize: 9,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      ),
                      PillBadge(
                        text: isDirect ? '● DIRECT' : '🌐 SCRAPED',
                        backgroundColor: isDirect ? const Color(0xFF10B981) : BrikTheme.cardSurfaceSecondary,
                        textColor: Colors.white,
                        fontSize: 8.5,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Title
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Subtitle Specs
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: BrikTheme.textSecondaryOnDark,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Price, MRP & Rating & Quick Add
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        price,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14.5,
                        ),
                      ),
                      if (originalPrice.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          originalPrice,
                          style: const TextStyle(
                            color: BrikTheme.textSecondaryOnDark,
                            decoration: TextDecoration.lineThrough,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                      const Spacer(),
                      PillBadge(
                        text: rating,
                        fontSize: 9,
                        backgroundColor: BrikTheme.cardSurfaceSecondary,
                        textColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          final prodId = product['id'] ?? 1;
                          final prodName = product['name']?.toString() ?? title;
                          context.read<CartProvider>().addItem(prodId, productName: prodName);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: BrikTheme.cardSurface,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              content: Text(
                                'Added $title to bag!',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: BrikTheme.brandNavy,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '+ BAG',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
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
