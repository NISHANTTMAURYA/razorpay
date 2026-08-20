import 'package:flutter/material.dart';
import '../../../core/theme/brik_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/widgets/brik_card.dart';
import '../../../shared/widgets/brik_header_card.dart';
import '../../../shared/widgets/pill_badge.dart';
import '../../../shared/widgets/agent_thinking_pill.dart';
import '../../product/screens/product_comparison_sheet.dart';
import '../../product/screens/product_detail_sheet.dart';
import '../../checkout/screens/checkout_sheet.dart';
import '../../orders/screens/order_tracking_screen.dart';

class AiShoppingScreen extends StatefulWidget {
  final Function(int count)? onCartUpdated;
  final VoidCallback? onSettingsPressed;

  const AiShoppingScreen({
    super.key,
    this.onCartUpdated,
    this.onSettingsPressed,
  });

  @override
  State<AiShoppingScreen> createState() => _AiShoppingScreenState();
}

class _AiShoppingScreenState extends State<AiShoppingScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String _thinkingStepText = '[1/4] Classifying intent...';

  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'text': 'Hi Bohdan! I am your **Mitrai Commerce Agent** powered by LangGraph.\n\nAsk me anything:\n• *"I need wireless headphones under ₹3,000"*\n• *"Compare Sony vs boAt headphones"*\n• *"Where is my order?"*',
      'products': <Map<String, dynamic>>[],
      'actions': [
        {'label': 'Headphones under ₹3k', 'query': 'I need wireless headphones under ₹3,000 with good battery life'},
        {'label': 'Smartphones under ₹25k', 'query': 'Show me 5G phones under ₹25,000 with great camera'},
        {'label': 'Compare Top 2 Audio', 'query': 'Compare Sony vs boAt headphones'},
      ]
    }
  ];

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'isUser': true,
        'text': text,
        'products': <Map<String, dynamic>>[],
      });
      _isLoading = true;
      _thinkingStepText = '[1/4] Classifying intent...';
    });

    _textController.clear();
    _scrollToBottom();

    // Step 2 simulation
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted && _isLoading) {
        setState(() => _thinkingStepText = '[2/4] Querying 7 merchant catalogs...');
      }
    });

    // Step 3 simulation
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted && _isLoading) {
        setState(() => _thinkingStepText = '[3/4] Synthesizing YouTube & Reddit reviews...');
      }
    });

    final response = await ApiService().sendAgentMessage(message: text);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _messages.add({
        'isUser': false,
        'text': response['message'] ?? '',
        'products': List<Map<String, dynamic>>.from(response['products'] ?? []),
        'comparison': response['comparison'],
        'cart': response['cart'],
        'actions': List<Map<String, dynamic>>.from(response['suggested_actions'] ?? []),
      });
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleAction(Map<String, dynamic> action) async {
    final act = action['action'];
    final payload = action['payload'] as Map<String, dynamic>?;

    if (act == 'COMPARE') {
      final compResult = await ApiService().sendAgentMessage(message: 'Compare Sony vs boAt headphones');
      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => ProductComparisonSheet(
            comparison: compResult['comparison'] ?? {},
            products: List<Map<String, dynamic>>.from(compResult['products'] ?? []),
            onAddToCart: (pId) => _handleAddToCart(pId),
          ),
        );
      }
    } else if (act == 'ADD_TO_CART') {
      final pId = payload?['product_id'] ?? 1;
      _handleAddToCart(pId);
    } else if (act == 'CHECKOUT' || act == 'LAUNCH_RAZORPAY') {
      final cartData = await ApiService().getCart();
      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => CheckoutSheet(
            cart: cartData,
            onOrderSuccess: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderTrackingScreen(
                    onBackToHome: () => Navigator.pop(context),
                    onAskAi: (q) => _sendMessage(q),
                  ),
                ),
              );
            },
          ),
        );
      }
    } else if (act == 'TRACK_ORDER' || act == 'WHERE_IS_ORDER' || (action['query']?.toString().toLowerCase().contains('order') ?? false)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderTrackingScreen(
            onBackToHome: () => Navigator.pop(context),
            onAskAi: (q) => _sendMessage(q),
          ),
        ),
      );
    } else if (action['query'] != null) {
      _sendMessage(action['query']);
    }
  }

  void _openProductDetail(Map<String, dynamic> prod) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductDetailSheet(
        product: prod,
        onAddToCart: () => _handleAddToCart(prod['id'] ?? 1),
      ),
    );
  }

  void _handleAddToCart(int productId) async {
    final updatedCart = await ApiService().addToCart(productId: productId);
    widget.onCartUpdated?.call(updatedCart['total_items'] ?? 1);
    _sendMessage('Add this product to my cart');
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    final effectiveBottomPadding = bottomInset > 0 ? 10.0 : (bottomSafeArea + 78.0);

    return Column(
      children: [
        // Top App Bar Card (Consistent Standalone Component)
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
          child: BrikHeaderCard(
            tagText: 'LANGGRAPH ENGINE',
            margin: const EdgeInsets.only(bottom: 10),
            onSettingsPressed: widget.onSettingsPressed,
          ),
        ),

        // Chat Messages List
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              final isUser = msg['isUser'] == true;
              final products = msg['products'] as List<Map<String, dynamic>>? ?? [];
              final actions = msg['actions'] as List<Map<String, dynamic>>? ?? [];

              return Column(
                crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Message bubble
                  BrikCard(
                    backgroundColor: isUser ? BrikTheme.cardSurfaceSecondary : BrikTheme.cardSurface,
                    padding: const EdgeInsets.all(18),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg['text']?.toString().replaceAll('**', '') ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Product recommendation cards if present
                  if (products.isNotEmpty)
                    Container(
                      height: 200,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: products.length,
                        itemBuilder: (context, pIndex) {
                          final prod = products[pIndex];
                          return GestureDetector(
                            onTap: () => _openProductDetail(prod),
                            child: Container(
                              width: 240,
                              margin: const EdgeInsets.only(right: 12),
                              child: BrikCard(
                                padding: const EdgeInsets.all(14),
                                margin: EdgeInsets.zero,
                                backgroundColor: BrikTheme.cardSurfaceSecondary,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          prod['brand']?.toString() ?? 'Brand',
                                          style: const TextStyle(color: BrikTheme.brandNavy, fontSize: 11, fontWeight: FontWeight.w800),
                                        ),
                                        PillBadge(
                                          text: '${prod['rating'] ?? 4.5} ★',
                                          fontSize: 10,
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      prod['name']?.toString() ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                                    ),
                                    const Spacer(),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '₹${prod['price'] ?? 1999}',
                                          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
                                        ),
                                        IconButton(
                                          onPressed: () => _handleAddToCart(prod['id']),
                                          icon: const Icon(Icons.add_shopping_cart_rounded, color: BrikTheme.brandNavy, size: 20),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  // Action Chips
                  if (actions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: actions.map((act) {
                          return GestureDetector(
                            onTap: () => _handleAction(act),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: BrikTheme.brandNavy,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                act['label']?.toString() ?? 'Action',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              );
            },
          ),
        ),

        // Live Thinking Telemetry Bar
        if (_isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: AgentThinkingPill(
              stepName: _thinkingStepText,
              isCompleted: false,
            ),
          ),

        // Input Bar Card (Floating above bottom navbar)
        Padding(
          padding: EdgeInsets.fromLTRB(16, 6, 16, effectiveBottomPadding),
          child: BrikCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            margin: EdgeInsets.zero,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Describe what you want to buy...',
                      hintStyle: TextStyle(color: BrikTheme.textSecondaryOnDark, fontSize: 13),
                      border: InputBorder.none,
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_upward_rounded, color: BrikTheme.brandNavy),
                  onPressed: () => _sendMessage(_textController.text),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
