import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/brik_theme.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/providers/catalog_provider.dart';
import '../../../shared/widgets/brik_card.dart';
import '../../../shared/widgets/brik_button.dart';
import '../../../shared/widgets/pill_badge.dart';
import '../../../shared/widgets/brik_header_card.dart';
import '../../product/screens/product_detail_sheet.dart';

enum ProductSortOption {
  featured,
  priceLowToHigh,
  priceHighToLow,
  rating,
  discount,
}

enum ProductViewMode {
  grid,
  list,
}

class DiscoverScreen extends StatefulWidget {
  final VoidCallback onOpenOrders;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenAiChat;

  const DiscoverScreen({
    super.key,
    required this.onOpenOrders,
    required this.onOpenSettings,
    required this.onOpenAiChat,
  });

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _accordionScrollController = ScrollController();

  String _searchQuery = '';
  String _selectedCategory = 'ALL';
  String? _selectedBrand;
  ProductSortOption _selectedSort = ProductSortOption.featured;
  ProductViewMode _viewMode = ProductViewMode.grid;

  // Filter criteria
  RangeValues _priceRange = const RangeValues(0, 30000);
  bool _directMerchantOnly = false;
  double _minRating = 0.0;

  int _activeAccordionIndex = 0;
  Timer? _accordionTimer;

  final List<Map<String, dynamic>> _heroBanners = [
    {
      'title': 'boAt Audio Fest',
      'subtitle': 'Up to 60% OFF Direct Merchant Catalog',
      'tag': '⚡ FLASH SALE',
      'category': 'AUDIO',
      'accent': const Color(0xFFEB935C),
      'image': 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800&auto=format&fit=crop',
    },
    {
      'title': '5G Smartphone Drop',
      'subtitle': 'Samsung & OnePlus • Best Flagships',
      'tag': '🔥 FLAGSHIP DEAL',
      'category': 'SMARTPHONES',
      'accent': const Color(0xFFD3C7F8),
      'image': 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=800&auto=format&fit=crop',
    },
    {
      'title': 'Athleisure & Kicks',
      'subtitle': 'Red Tape & Snitch • Fresh Drops',
      'tag': '✨ TRENDING',
      'category': 'FOOTWEAR',
      'accent': const Color(0xFFF4A776),
      'image': 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800&auto=format&fit=crop',
    },
    {
      'title': 'D2C Wellness & Care',
      'subtitle': 'The Derma Co & Minimalist',
      'tag': '🌿 OFFICIAL D2C',
      'category': 'PERSONAL CARE',
      'accent': const Color(0xFF10B981),
      'image': 'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=800&auto=format&fit=crop',
    },
    {
      'title': 'Smart Wearables',
      'subtitle': 'Noise & Fire-Boltt AMOLED',
      'tag': '⌚ NEW DROP',
      'category': 'WEARABLES',
      'accent': const Color(0xFF38BDF8),
      'image': 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=800&auto=format&fit=crop',
    },
    {
      'title': 'Pure Nutrition',
      'subtitle': 'MuscleBlaze Whey & Isolate Protein',
      'tag': '💪 ATHLETE PICK',
      'category': 'FOOD & NUTRITION',
      'accent': const Color(0xFFF59E0B),
      'image': 'https://images.unsplash.com/photo-1579722821273-0f6c7d44362f?w=800&auto=format&fit=crop',
    },
    {
      'title': 'Streetwear & Apparel',
      'subtitle': 'Snitch Oversized Tees & Cargoes',
      'tag': '👕 RUNWAY',
      'category': 'FASHION',
      'accent': const Color(0xFFA78BFA),
      'image': 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=800&auto=format&fit=crop',
    },
  ];

  static const List<Map<String, dynamic>> _categories = [
    {'name': 'ALL', 'label': 'All'},
    {'name': 'AUDIO', 'label': 'Audio'},
    {'name': 'SMARTPHONES', 'label': 'Phones'},
    {'name': 'WEARABLES', 'label': 'Wearables'},
    {'name': 'FOOTWEAR', 'label': 'Footwear'},
    {'name': 'FASHION', 'label': 'Fashion'},
    {'name': 'PERSONAL CARE', 'label': 'Care'},
    {'name': 'FOOD & NUTRITION', 'label': 'Nutrition'},
  ];

  @override
  void initState() {
    super.initState();
    _startAccordionAutoPlay();
  }

  @override
  void dispose() {
    _accordionTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    _accordionScrollController.dispose();
    super.dispose();
  }

  void _startAccordionAutoPlay() {
    _accordionTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        final next = (_activeAccordionIndex + 1) % _heroBanners.length;
        _selectAccordionItem(next, autoScroll: true);
      }
    });
  }

  void _selectAccordionItem(int index, {bool autoScroll = true}) {
    setState(() {
      _activeAccordionIndex = index;
    });

    if (autoScroll && _accordionScrollController.hasClients) {
      const collapsedWidth = 39.5;
      const spacing = 5.4;
      const expandedWidth = 230.0;
      final screenWidth = MediaQuery.of(context).size.width;
      final targetScroll = (index * (collapsedWidth + spacing)) - (screenWidth / 2) + (expandedWidth / 2);
      _accordionScrollController.animateTo(
        targetScroll.clamp(0.0, _accordionScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    }
  }

  int _calculateDiscount(dynamic priceVal, dynamic origPriceVal) {
    final p = double.tryParse(priceVal?.toString() ?? '0') ?? 0.0;
    final op = double.tryParse(origPriceVal?.toString() ?? '0') ?? 0.0;
    if (op > p && op > 0) {
      return (((op - p) / op) * 100).round();
    }
    return 0;
  }

  List<Map<String, dynamic>> _getProcessedProducts(List<Map<String, dynamic>> allProducts) {
    var list = List<Map<String, dynamic>>.from(allProducts);

    // 1. Category Filter
    if (_selectedCategory != 'ALL') {
      list = list.where((p) {
        final catName = (p['category'] is Map ? p['category']['name'] : p['category']?.toString()) ?? '';
        return catName.toLowerCase().contains(_selectedCategory.toLowerCase());
      }).toList();
    }

    // 2. Brand Filter
    if (_selectedBrand != null && _selectedBrand!.isNotEmpty) {
      list = list.where((p) {
        final brand = (p['brand']?.toString() ?? '').toLowerCase();
        return brand.contains(_selectedBrand!.toLowerCase());
      }).toList();
    }

    // 3. Search Query Filter
    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((p) {
        final name = (p['name']?.toString() ?? '').toLowerCase();
        final brand = (p['brand']?.toString() ?? '').toLowerCase();
        final desc = (p['description']?.toString() ?? '').toLowerCase();
        final cat = (p['category'] is Map ? p['category']['name'] : p['category']?.toString()) ?? '';
        return name.contains(q) || brand.contains(q) || desc.contains(q) || cat.toLowerCase().contains(q);
      }).toList();
    }

    // 4. Direct Merchant Only Filter
    if (_directMerchantOnly) {
      list = list.where((p) {
        return p['is_platform_product'] != false && p['source'] != 'SCRAPED_EXTERNAL';
      }).toList();
    }

    // 5. Price Range Filter
    list = list.where((p) {
      final price = double.tryParse(p['price']?.toString() ?? '0') ?? 0.0;
      return price >= _priceRange.start && price <= _priceRange.end;
    }).toList();

    // 6. Minimum Rating Filter
    if (_minRating > 0) {
      list = list.where((p) {
        final rating = double.tryParse(p['rating']?.toString() ?? '0') ?? 0.0;
        return rating >= _minRating;
      }).toList();
    }

    // 7. Sorting
    switch (_selectedSort) {
      case ProductSortOption.priceLowToHigh:
        list.sort((a, b) {
          final pA = double.tryParse(a['price']?.toString() ?? '0') ?? 0.0;
          final pB = double.tryParse(b['price']?.toString() ?? '0') ?? 0.0;
          return pA.compareTo(pB);
        });
        break;
      case ProductSortOption.priceHighToLow:
        list.sort((a, b) {
          final pA = double.tryParse(a['price']?.toString() ?? '0') ?? 0.0;
          final pB = double.tryParse(b['price']?.toString() ?? '0') ?? 0.0;
          return pB.compareTo(pA);
        });
        break;
      case ProductSortOption.rating:
        list.sort((a, b) {
          final rA = double.tryParse(a['rating']?.toString() ?? '0') ?? 0.0;
          final rB = double.tryParse(b['rating']?.toString() ?? '0') ?? 0.0;
          return rB.compareTo(rA);
        });
        break;
      case ProductSortOption.discount:
        list.sort((a, b) {
          final dA = _calculateDiscount(a['price'], a['original_price']);
          final dB = _calculateDiscount(b['price'], b['original_price']);
          return dB.compareTo(dA);
        });
        break;
      case ProductSortOption.featured:
        break;
    }

    return list;
  }

  void _openProductDetail(Map<String, dynamic> product) {
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
  }

  int get _activeFilterCount {
    int count = 0;
    if (_directMerchantOnly) count++;
    if (_selectedBrand != null) count++;
    if (_minRating > 0) count++;
    if (_priceRange.start > 0 || _priceRange.end < 30000) count++;
    if (_selectedCategory != 'ALL') count++;
    return count;
  }

  void _openFilterSheet(List<Map<String, dynamic>> allProducts) {
    final brands = allProducts
        .map((p) => p['brand']?.toString() ?? '')
        .where((b) => b.isNotEmpty)
        .toSet()
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: const BoxDecoration(
                color: BrikTheme.cardSurface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Filters',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (_activeFilterCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: BrikTheme.brandNavy,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$_activeFilterCount',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            setSheetState(() {
                              _priceRange = const RangeValues(0, 30000);
                              _directMerchantOnly = false;
                              _selectedBrand = null;
                              _minRating = 0.0;
                              _selectedCategory = 'ALL';
                            });
                            setState(() {});
                          },
                          child: const Text(
                            'Clear All',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: BrikTheme.cardBorder, height: 20),

                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Direct Merchant Toggle
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: BrikTheme.cardSurfaceSecondary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Direct Verified Store',
                                      style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700),
                                    ),
                                    Text(
                                      'Only show direct official brand catalogs',
                                      style: TextStyle(color: BrikTheme.textSecondaryOnDark, fontSize: 11),
                                    ),
                                  ],
                                ),
                                Switch(
                                  value: _directMerchantOnly,
                                  activeThumbColor: BrikTheme.brandNavy,
                                  onChanged: (val) {
                                    setSheetState(() => _directMerchantOnly = val);
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 2. Price Range Slider
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Price Range',
                                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                '₹${_priceRange.start.toInt()} - ₹${_priceRange.end.toInt()}',
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                          RangeSlider(
                            values: _priceRange,
                            min: 0,
                            max: 30000,
                            divisions: 30,
                            activeColor: BrikTheme.brandNavy,
                            inactiveColor: BrikTheme.cardSurfaceSecondary,
                            onChanged: (vals) {
                              setSheetState(() => _priceRange = vals);
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: 12),

                          // 3. Minimum Rating
                          const Text(
                            'Customer Rating',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [0.0, 4.0, 4.5, 4.8].map((r) {
                              final isSel = _minRating == r;
                              return GestureDetector(
                                onTap: () {
                                  setSheetState(() => _minRating = r);
                                  setState(() {});
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: isSel ? BrikTheme.brandNavy : BrikTheme.cardSurfaceSecondary,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSel ? BrikTheme.accentLavender : Colors.transparent,
                                    ),
                                  ),
                                  child: Text(
                                    r == 0.0 ? 'All Ratings' : '$r ★ & above',
                                    style: TextStyle(
                                      color: isSel ? Colors.white : BrikTheme.textSecondaryOnDark,
                                      fontSize: 11.5,
                                      fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),

                          // 4. Brands
                          const Text(
                            'Brands',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: brands.map((b) {
                              final isSel = _selectedBrand == b;
                              return GestureDetector(
                                onTap: () {
                                  setSheetState(() {
                                    _selectedBrand = isSel ? null : b;
                                  });
                                  setState(() {});
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSel ? BrikTheme.brandNavy : BrikTheme.cardSurfaceSecondary,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSel ? BrikTheme.accentLavender : Colors.transparent,
                                    ),
                                  ),
                                  child: Text(
                                    b,
                                    style: TextStyle(
                                      color: isSel ? Colors.white : BrikTheme.textSecondaryOnDark,
                                      fontSize: 11.5,
                                      fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),

                          BrikButton(
                            text: 'APPLY FILTERS',
                            style: BrikButtonStyle.primaryLilac,
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          decoration: const BoxDecoration(
            color: BrikTheme.cardSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sort Products',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const Divider(color: BrikTheme.cardBorder, height: 20),
              _buildSortOptionTile('🔥 Featured / Recommended', ProductSortOption.featured),
              _buildSortOptionTile('📉 Price: Low to High', ProductSortOption.priceLowToHigh),
              _buildSortOptionTile('📈 Price: High to Low', ProductSortOption.priceHighToLow),
              _buildSortOptionTile('⭐ Customer Rating', ProductSortOption.rating),
              _buildSortOptionTile('🏷️ Biggest Discount', ProductSortOption.discount),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOptionTile(String label, ProductSortOption option) {
    final isSel = _selectedSort == option;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(
        label,
        style: TextStyle(
          color: isSel ? Colors.white : BrikTheme.textSecondaryOnDark,
          fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
          fontSize: 14,
        ),
      ),
      trailing: isSel ? const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20) : null,
      onTap: () {
        setState(() => _selectedSort = option);
        Navigator.pop(context);
      },
    );
  }

  String get _sortLabel {
    switch (_selectedSort) {
      case ProductSortOption.priceLowToHigh:
        return 'Price: Low';
      case ProductSortOption.priceHighToLow:
        return 'Price: High';
      case ProductSortOption.rating:
        return 'Rating';
      case ProductSortOption.discount:
        return 'Discount';
      case ProductSortOption.featured:
        return 'Sort';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    final effectiveBottomPadding = bottomSafeArea + 110.0;
    final catalog = context.watch<CatalogProvider>();
    final processedProducts = _getProcessedProducts(catalog.products);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          // 1. Top Header Card
          BrikHeaderCard(
            tagText: '${catalog.products.length} ITEMS',
            margin: const EdgeInsets.only(bottom: 10),
            onOrdersPressed: widget.onOpenOrders,
            onSettingsPressed: widget.onOpenSettings,
          ),

          // 2. Clean Search Bar
          _buildSearchBar(),

          const SizedBox(height: 8),

          // 3. Amazon-Style Unified Horizontal Filter & Category Capsule Rail
          _buildUnifiedAmazonFilterRail(catalog.products),

          const SizedBox(height: 10),

          // 4. Scrollable Catalog Body
          Expanded(
            child: catalog.isLoading && catalog.products.isEmpty
                ? const Center(child: CircularProgressIndicator(color: BrikTheme.brandNavy))
                : RefreshIndicator(
                    color: BrikTheme.brandNavy,
                    onRefresh: () => context.read<CatalogProvider>().loadProducts(),
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      slivers: [
                        // A. Smooth Responsive Expanding Horizontal Accordion Carousel
                        if (_searchQuery.isEmpty && _selectedCategory == 'ALL' && _selectedBrand == null && _activeFilterCount == 0) ...[
                          SliverToBoxAdapter(
                            child: _buildResponsiveAccordionCarousel(),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 14)),
                        ],

                        // B. Product Counter & Grid/List Toggle Header
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${processedProducts.length} ${processedProducts.length == 1 ? 'Product' : 'Products'} Available',
                                  style: const TextStyle(
                                    color: BrikTheme.textSecondaryOnLight,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _viewMode = _viewMode == ProductViewMode.grid ? ProductViewMode.list : ProductViewMode.grid;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: BrikTheme.cardSurface,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: BrikTheme.cardBorder),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _viewMode == ProductViewMode.grid ? Icons.view_list_rounded : Icons.grid_view_rounded,
                                          color: BrikTheme.brandNavy,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _viewMode == ProductViewMode.grid ? 'LIST' : 'GRID',
                                          style: const TextStyle(
                                            color: BrikTheme.textPrimaryOnDark,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 6)),

                        // C. Product Grid / List Content
                        if (processedProducts.isEmpty)
                          SliverToBoxAdapter(
                            child: _buildEmptyState(),
                          )
                        else if (_viewMode == ProductViewMode.grid)
                          _buildProductGridSliver(processedProducts)
                        else
                          _buildProductListSliver(processedProducts),

                        // Bottom Spacer
                        SliverToBoxAdapter(
                          child: SizedBox(height: effectiveBottomPadding),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: BrikTheme.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BrikTheme.cardBorder, width: 1.2),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.search_rounded, color: BrikTheme.brandNavy, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                hintText: 'Search products, brands, headphones...',
                hintStyle: TextStyle(color: BrikTheme.textSecondaryOnDark, fontSize: 12),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded, color: BrikTheme.textSecondaryOnDark, size: 16),
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),
          GestureDetector(
            onTap: widget.onOpenAiChat,
            child: Container(
              margin: const EdgeInsets.all(5),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: BrikTheme.brandNavy,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 13),
                  SizedBox(width: 4),
                  Text(
                    'AI COPILOT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
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

  Widget _buildUnifiedAmazonFilterRail(List<Map<String, dynamic>> allProducts) {
    final activeCount = _activeFilterCount;

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          // 1. Filter Trigger Pill
          GestureDetector(
            onTap: () => _openFilterSheet(allProducts),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: activeCount > 0 ? BrikTheme.brandNavy : BrikTheme.cardSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: activeCount > 0 ? BrikTheme.accentLavender : BrikTheme.cardBorder,
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    color: activeCount > 0 ? Colors.white : BrikTheme.brandNavy,
                    size: 13,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Filters',
                    style: TextStyle(
                      color: activeCount > 0 ? Colors.white : BrikTheme.textPrimaryOnDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (activeCount > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$activeCount',
                        style: const TextStyle(color: BrikTheme.brandNavy, fontSize: 9, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 2. Sort Dropdown Pill
          GestureDetector(
            onTap: _openSortSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: _selectedSort != ProductSortOption.featured ? BrikTheme.brandNavy : BrikTheme.cardSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _selectedSort != ProductSortOption.featured ? BrikTheme.accentLavender : BrikTheme.cardBorder,
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _sortLabel,
                    style: TextStyle(
                      color: _selectedSort != ProductSortOption.featured ? Colors.white : BrikTheme.textPrimaryOnDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: _selectedSort != ProductSortOption.featured ? Colors.white : BrikTheme.brandNavy,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),

          // 3. Quick Direct Store Toggle
          GestureDetector(
            onTap: () {
              setState(() => _directMerchantOnly = !_directMerchantOnly);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: _directMerchantOnly ? const Color(0xFF10B981) : BrikTheme.cardSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _directMerchantOnly ? const Color(0xFF10B981) : BrikTheme.cardBorder,
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_directMerchantOnly) ...[
                    const Icon(Icons.check_rounded, color: Colors.white, size: 12),
                    const SizedBox(width: 3),
                  ],
                  Text(
                    'Direct Store',
                    style: TextStyle(
                      color: _directMerchantOnly ? Colors.white : BrikTheme.textPrimaryOnDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Category Pills
          ..._categories.map((cat) {
            final catName = cat['name'] as String;
            final isSel = _selectedCategory == catName;

            return GestureDetector(
              onTap: () {
                setState(() => _selectedCategory = catName);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: isSel ? BrikTheme.brandNavy : BrikTheme.cardSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSel ? BrikTheme.accentLavender : BrikTheme.cardBorder,
                    width: 1.2,
                  ),
                ),
                child: Text(
                  cat['label'] as String,
                  style: TextStyle(
                    color: isSel ? Colors.white : BrikTheme.textPrimaryOnDark,
                    fontSize: 11,
                    fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Truly Responsive & Centered Expanding Accordion Carousel
  /// Automatically centers the cards when total width is within screen bounds,
  /// and dynamically expands/compresses gracefully on all device widths.
  Widget _buildResponsiveAccordionCarousel() {
    const carouselHeight = 175.0;
    const spacing = 5.4;
    const collapsedWidth = 39.5;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final otherCardsCount = _heroBanners.length - 1;
        final fitWidth = totalWidth - (otherCardsCount * (collapsedWidth + spacing));
        // If all cards fit on screen, expand to fill; otherwise use standard ~60% hero ratio
        final expandedWidth = (fitWidth >= 180.0)
            ? fitWidth.clamp(180.0, 280.0)
            : (totalWidth * 0.60).clamp(200.0, 260.0);

        return SizedBox(
          height: carouselHeight,
          child: SingleChildScrollView(
            controller: _accordionScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: totalWidth),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_heroBanners.length, (index) {
                    final isSelected = _activeAccordionIndex == index;
                    final banner = _heroBanners[index];
                    final imgUrl = banner['image'] as String;
                    final title = banner['title'] as String;
                    final subtitle = banner['subtitle'] as String;
                    final tag = banner['tag'] as String;
                    final accent = banner['accent'] as Color;

                    return Padding(
                      padding: EdgeInsets.only(right: index == _heroBanners.length - 1 ? 0 : spacing),
                      child: GestureDetector(
                        onTap: () {
                          if (isSelected) {
                            setState(() {
                              _selectedCategory = banner['category']?.toString() ?? 'ALL';
                            });
                          } else {
                            _selectAccordionItem(index, autoScroll: true);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 380),
                          curve: Curves.easeOutCubic,
                          width: isSelected ? expandedWidth : collapsedWidth,
                          height: carouselHeight,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isSelected ? accent : BrikTheme.cardBorder.withValues(alpha: 0.7),
                              width: isSelected ? 3.2 : 2.0,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // 1. Image (Desaturated/dimmed when collapsed, vibrant when active)
                                ColorFiltered(
                                  colorFilter: isSelected
                                      ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                                      : ColorFilter.mode(Colors.black.withValues(alpha: 0.55), BlendMode.darken),
                                  child: Image.network(
                                    imgUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: BrikTheme.brandNavy,
                                      child: const Icon(Icons.photo_outlined, color: Colors.white30),
                                    ),
                                  ),
                                ),

                                // 2. Gradient Overlay for text readability
                                Positioned.fill(
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 300),
                                    opacity: isSelected ? 1.0 : 0.35,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.black.withValues(alpha: 0.1),
                                            Colors.black.withValues(alpha: 0.35),
                                            Colors.black.withValues(alpha: 0.92),
                                          ],
                                          stops: const [0.0, 0.45, 1.0],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // 3. Expanded Card Content (Tag, Vertical line + Title, Subtitle)
                                if (isSelected)
                                  Positioned(
                                    left: 12,
                                    right: 12,
                                    bottom: 12,
                                    child: AnimatedOpacity(
                                      duration: const Duration(milliseconds: 300),
                                      opacity: isSelected ? 1.0 : 0.0,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Tag Pill
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: accent.withValues(alpha: 0.3),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: accent.withValues(alpha: 0.6), width: 0.8),
                                            ),
                                            child: Text(
                                              tag,
                                              style: TextStyle(
                                                color: accent,
                                                fontSize: 8,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 5),

                                          // Title with Vertical Accent Line
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 3.5,
                                                height: 14,
                                                decoration: BoxDecoration(
                                                  color: accent,
                                                  borderRadius: BorderRadius.circular(2),
                                                ),
                                              ),
                                              const SizedBox(width: 5),
                                              Expanded(
                                                child: Text(
                                                  title,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: -0.2,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),

                                          // Subtitle
                                          Text(
                                            subtitle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.85),
                                              fontSize: 9.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: BrikTheme.cardSurface,
              shape: BoxShape.circle,
              border: Border.all(color: BrikTheme.cardBorder),
            ),
            child: const Icon(Icons.search_off_rounded, color: BrikTheme.brandNavy, size: 30),
          ),
          const SizedBox(height: 12),
          const Text(
            'No matching products',
            style: TextStyle(color: BrikTheme.textPrimaryOnLight, fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Try clearing your filters or searching another keyword.',
            textAlign: TextAlign.center,
            style: TextStyle(color: BrikTheme.textSecondaryOnLight, fontSize: 11.5),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BrikButton(
                text: 'RESET FILTERS',
                style: BrikButtonStyle.primaryLilac,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                    _selectedCategory = 'ALL';
                    _selectedBrand = null;
                    _directMerchantOnly = false;
                    _minRating = 0.0;
                    _priceRange = const RangeValues(0, 30000);
                  });
                },
              ),
              const SizedBox(width: 8),
              BrikButton(
                text: 'ASK AI ⚡',
                style: BrikButtonStyle.primaryLilac,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                onPressed: widget.onOpenAiChat,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductGridSliver(List<Map<String, dynamic>> products) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.70,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final p = products[index];
          return _buildBentoProductCard(product: p);
        },
        childCount: products.length,
      ),
    );
  }

  Widget _buildProductListSliver(List<Map<String, dynamic>> products) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final p = products[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildListProductCard(product: p),
          );
        },
        childCount: products.length,
      ),
    );
  }

  Widget _buildBentoProductCard({
    required Map<String, dynamic> product,
  }) {
    final title = product['name']?.toString() ?? 'Product';
    final brand = product['brand']?.toString() ?? 'Mitrai';
    final price = double.tryParse(product['price']?.toString() ?? '0')?.toStringAsFixed(0) ?? '0';
    final origPrice = double.tryParse(product['original_price']?.toString() ?? '0')?.toStringAsFixed(0) ?? '';
    final rating = product['rating']?.toString() ?? '4.6';
    final isDirect = product['is_platform_product'] != false && product['source'] != 'SCRAPED_EXTERNAL';
    final discount = _calculateDiscount(product['price'], product['original_price']);

    String imgUrl = '';
    if (product['images'] is List && (product['images'] as List).isNotEmpty) {
      imgUrl = product['images'][0].toString();
    } else if (product['image'] != null) {
      imgUrl = product['image'].toString();
    }

    final attrs = product['attributes'] as Map<String, dynamic>?;
    final keySpec = attrs != null && attrs.isNotEmpty
        ? attrs.entries.take(1).map((e) => '${e.value}').first
        : (product['description']?.toString() ?? 'Verified Stock');

    return GestureDetector(
      onTap: () => _openProductDetail(product),
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: BrikTheme.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: BrikTheme.cardBorder, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 118,
                    width: double.infinity,
                    color: BrikTheme.cardSurfaceSecondary,
                    child: imgUrl.isNotEmpty
                        ? Image.network(
                            imgUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 26),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 26),
                          ),
                  ),
                ),
                if (discount > 0)
                  Positioned(
                    top: 5,
                    left: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: BrikTheme.brandNavy,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '-$discount%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 5,
                  left: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 9.5),
                        const SizedBox(width: 2),
                        Text(
                          rating,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    brand.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: BrikTheme.textSecondaryOnDark,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: isDirect ? const Color(0xFF10B981) : BrikTheme.cardSurfaceSecondary,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    isDirect ? 'DIRECT' : 'WEB',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              keySpec,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: BrikTheme.textSecondaryOnDark,
                fontSize: 9.5,
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '₹$price',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (origPrice.isNotEmpty && origPrice != price) ...[
                      const SizedBox(width: 4),
                      Text(
                        '₹$origPrice',
                        style: const TextStyle(
                          color: BrikTheme.textSecondaryOnDark,
                          decoration: TextDecoration.lineThrough,
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ],
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: BrikTheme.brandNavy,
                  size: 11,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListProductCard({
    required Map<String, dynamic> product,
  }) {
    final title = product['name']?.toString() ?? 'Product';
    final brand = product['brand']?.toString() ?? 'Mitrai';
    final price = double.tryParse(product['price']?.toString() ?? '0')?.toStringAsFixed(0) ?? '0';
    final origPrice = double.tryParse(product['original_price']?.toString() ?? '0')?.toStringAsFixed(0) ?? '';
    final rating = product['rating']?.toString() ?? '4.6';
    final isDirect = product['is_platform_product'] != false && product['source'] != 'SCRAPED_EXTERNAL';

    String imgUrl = '';
    if (product['images'] is List && (product['images'] as List).isNotEmpty) {
      imgUrl = product['images'][0].toString();
    } else if (product['image'] != null) {
      imgUrl = product['image'].toString();
    }

    final attrs = product['attributes'] as Map<String, dynamic>?;
    final specSummary = attrs != null && attrs.isNotEmpty
        ? attrs.entries.take(2).map((e) => '${e.key.replaceAll('_', ' ')}: ${e.value}').join(' • ')
        : (product['description']?.toString() ?? 'Verified Grounded Stock');

    return GestureDetector(
      onTap: () => _openProductDetail(product),
      child: BrikCard(
        padding: const EdgeInsets.all(12),
        margin: EdgeInsets.zero,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 80,
                height: 80,
                child: imgUrl.isNotEmpty
                    ? Image.network(
                        imgUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: BrikTheme.cardSurfaceSecondary,
                          child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 22),
                        ),
                      )
                    : Container(
                        color: BrikTheme.cardSurfaceSecondary,
                        child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 22),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      PillBadge(
                        text: brand.toUpperCase(),
                        backgroundColor: BrikTheme.brandNavy,
                        textColor: Colors.white,
                        fontSize: 8.5,
                      ),
                      PillBadge(
                        text: isDirect ? '● DIRECT' : '🌐 SCRAPED',
                        backgroundColor: isDirect ? const Color(0xFF10B981) : BrikTheme.cardSurfaceSecondary,
                        textColor: Colors.white,
                        fontSize: 8,
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    specSummary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: BrikTheme.textSecondaryOnDark, fontSize: 10.5),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            '₹$price',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14.5),
                          ),
                          if (origPrice.isNotEmpty && origPrice != price) ...[
                            const SizedBox(width: 6),
                            Text(
                              '₹$origPrice',
                              style: const TextStyle(
                                color: BrikTheme.textSecondaryOnDark,
                                decoration: TextDecoration.lineThrough,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                      PillBadge(
                        text: '$rating ★',
                        fontSize: 8.5,
                        backgroundColor: BrikTheme.cardSurfaceSecondary,
                        textColor: Colors.white,
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
