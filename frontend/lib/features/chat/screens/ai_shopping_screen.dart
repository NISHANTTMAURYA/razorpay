import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/brik_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/chat_storage_service.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../shared/widgets/brik_card.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/pill_badge.dart';
import '../../product/screens/product_detail_sheet.dart';

class AiShoppingScreen extends StatefulWidget {
  final ValueChanged<int>? onCartUpdated;
  final VoidCallback? onSettingsPressed;
  final String? initialMessage;

  const AiShoppingScreen({
    super.key,
    this.onCartUpdated,
    this.onSettingsPressed,
    this.initialMessage,
  });

  @override
  State<AiShoppingScreen> createState() => _AiShoppingScreenState();
}

class _AiShoppingScreenState extends State<AiShoppingScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  // Active Session & Message State
  ChatSession? _currentSession;
  final List<Map<String, dynamic>> _messages = [];
  final List<Map<String, dynamic>> _liveRunningSteps = [];
  bool _includeMerchants = true;

  @override
  void initState() {
    super.initState();
    _initChatSession();
    if (widget.initialMessage != null && widget.initialMessage!.trim().isNotEmpty) {
      _textController.text = widget.initialMessage!.trim();
    }
  }

  Future<void> _initChatSession() async {
    final storage = ChatStorageService();
    final sessions = await storage.getSessions();
    final activeId = await storage.getActiveSessionId();

    ChatSession? sessionToLoad;
    if (activeId != null && sessions.isNotEmpty) {
      sessionToLoad = sessions.firstWhere((s) => s.id == activeId, orElse: () => sessions.first);
    } else if (sessions.isNotEmpty) {
      sessionToLoad = sessions.first;
    }

    if (sessionToLoad != null && sessionToLoad.messages.isNotEmpty) {
      setState(() {
        _currentSession = sessionToLoad;
        _messages.clear();
        _messages.addAll(sessionToLoad!.messages);
      });
    } else if (sessions.isNotEmpty && sessions.any((s) => s.messages.isNotEmpty)) {
      final nonEmpty = sessions.firstWhere((s) => s.messages.isNotEmpty);
      setState(() {
        _currentSession = nonEmpty;
        _messages.clear();
        _messages.addAll(nonEmpty.messages);
      });
    } else if (sessionToLoad != null) {
      setState(() {
        _currentSession = sessionToLoad;
        _messages.clear();
        _messages.addAll(sessionToLoad!.messages);
      });
    } else {
      _startNewChat(autoSave: false);
    }
  }

  void _startNewChat({bool autoSave = true}) {
    if (autoSave && _currentSession != null && _messages.isNotEmpty) {
      _saveCurrentSession();
    }

    final newSession = ChatSession(
      id: 'session_${DateTime.now().millisecondsSinceEpoch}',
      title: 'New Conversation',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messages: [],
    );

    setState(() {
      _currentSession = newSession;
      _messages.clear();
    });

    ChatStorageService().setActiveSessionId(newSession.id);
  }

  Future<void> _saveCurrentSession() async {
    if (_currentSession == null) return;
    _currentSession!.messages = List<Map<String, dynamic>>.from(_messages);
    _currentSession!.updatedAt = DateTime.now();

    // Auto-generate concise title from first user prompt if still default
    if (_currentSession!.title == 'New Conversation' && _messages.isNotEmpty) {
      final firstUser = _messages.firstWhere((m) => m['isUser'] == true, orElse: () => {});
      final firstText = firstUser['text']?.toString() ?? '';
      if (firstText.isNotEmpty) {
        _currentSession!.title = firstText.length > 28 ? '${firstText.substring(0, 28)}...' : firstText;
      }
    }

    await ChatStorageService().saveSession(_currentSession!);
  }

  Future<void> _switchSession(ChatSession session) async {
    await _saveCurrentSession();
    setState(() {
      _currentSession = session;
      _messages.clear();
      _messages.addAll(session.messages);
    });
    await ChatStorageService().setActiveSessionId(session.id);
    _scrollToBottom();
  }

  Future<void> _deleteSession(String sessionId) async {
    await ChatStorageService().deleteSession(sessionId);
    if (_currentSession?.id == sessionId) {
      final remaining = await ChatStorageService().getSessions();
      if (remaining.isNotEmpty) {
        await _switchSession(remaining.first);
      } else {
        _startNewChat(autoSave: false);
      }
    } else {
      if (mounted) setState(() {});
    }
  }

  // Conversation history for multi-turn LLM reasoning
  List<Map<String, String>> get _history {
    final List<Map<String, String>> history = [];
    for (final m in _messages) {
      final isUser = m['isUser'] == true;
      final text = m['text']?.toString() ?? '';
      if (text.isNotEmpty) {
        history.add({
          'role': isUser ? 'user' : 'assistant',
          'content': text,
        });
      }
    }
    return history;
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Immediately dismiss keyboard on submit
    FocusScope.of(context).unfocus();

    if (_currentSession == null) {
      _startNewChat(autoSave: false);
    }

    setState(() {
      _messages.add({
        'isUser': true,
        'text': text,
        'products': <Map<String, dynamic>>[],
        'steps': <Map<String, dynamic>>[],
      });
      _liveRunningSteps.clear();
      _isLoading = true;
    });

    final cartId = context.read<CartProvider>().cartId;
    _textController.clear();
    _scrollToBottom();
    await _saveCurrentSession();

    final currentHistory = _history;

    // Trigger Celery background research so the response is computed and creates a notification
    ApiService().sendBackgroundChatMessage(
      message: text,
      history: currentHistory.map((h) => Map<String, dynamic>.from(h)).toList(),
      cartId: cartId,
      includeMerchants: _includeMerchants,
    );

    final response = await ApiService().streamAgentMessage(
      message: text,
      history: currentHistory,
      cartId: cartId,
      includeMerchants: _includeMerchants,
      onStepUpdate: (step) {
        if (mounted) {
          setState(() {
            final idx = _liveRunningSteps.indexWhere((s) => s['step_name'] == step['step_name']);
            if (idx >= 0) {
              _liveRunningSteps[idx] = step;
            } else {
              _liveRunningSteps.add(step);
            }
          });
          _scrollToBottom();
        }
      },
    );

    final respText = (response['response'] ?? response['message'] ?? '').toString().trim();
    final effectiveText = respText.isEmpty ? 'There is an error right now. Please chat later.' : respText;

    // Check for intermediate preview response (e.g. preliminary merchant discovery list before final products)
    final intermediateText = (response['intermediate_response'] ?? '').toString().trim();
    final List<Map<String, dynamic>> newBotMessages = [];

    if (intermediateText.isNotEmpty && intermediateText != effectiveText) {
      newBotMessages.add({
        'isUser': false,
        'text': intermediateText,
        'isIntermediate': true,
        'products': <Map<String, dynamic>>[],
        'comparison': null,
        'cart': null,
        'steps': <Map<String, dynamic>>[],
        'actions': <Map<String, dynamic>>[],
      });
    }

    newBotMessages.add({
      'isUser': false,
      'text': effectiveText,
      'products': List<Map<String, dynamic>>.from(response['products'] ?? []),
      'comparison': response['comparison'],
      'cart': response['cart'],
      'steps': List<Map<String, dynamic>>.from(response['steps'] ?? (_liveRunningSteps.isNotEmpty ? _liveRunningSteps : [])),
      'actions': List<Map<String, dynamic>>.from(response['suggested_actions'] ?? []),
    });

    if (mounted) {
      setState(() {
        _isLoading = false;
        _messages.addAll(newBotMessages);
      });
      _scrollToBottom();
      await _saveCurrentSession();
    } else {
      // User navigated away: persist message directly to disk storage
      if (_currentSession != null) {
        _currentSession!.messages.addAll(newBotMessages);
        _currentSession!.updatedAt = DateTime.now();
        await ChatStorageService().saveSession(_currentSession!);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 300,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleAddToCart(dynamic productId, {String? productName}) async {
    final cartProvider = context.read<CartProvider>();
    await cartProvider.addItem(productId, productName: productName);
    widget.onCartUpdated?.call(cartProvider.itemCount);
    _sendMessage('Added ${productName ?? "product #$productId"} to my cart');
  }

  void _openProductDetail(Map<String, dynamic> prod) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductDetailSheet(
        product: prod,
        onAddToCart: () {
          final prodId = prod['id'] ?? 1;
          final prodName = prod['name']?.toString();
          _handleAddToCart(prodId, productName: prodName);
        },
      ),
    );
  }

  void _openChatHistorySheet() async {
    await _saveCurrentSession();
    final initialSessions = await ChatStorageService().getSessions();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        List<ChatSession> sheetSessions = List.from(initialSessions);

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
              decoration: const BoxDecoration(
                color: BrikTheme.canvasBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // Sheet Header in Blue
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.history_rounded, color: Color(0xFF60A5FA), size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Chat History',
                              style: TextStyle(
                                color: Color(0xFF60A5FA),
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: BrikTheme.cardBorder, height: 1),

                  // Session List
                  Expanded(
                    child: sheetSessions.isEmpty
                        ? const Center(
                            child: Text(
                              'No saved conversations yet.',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: sheetSessions.length,
                            itemBuilder: (context, index) {
                              final session = sheetSessions[index];
                              final isSelected = _currentSession?.id == session.id;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF1E293B) : BrikTheme.cardSurface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF3B82F6) : BrikTheme.cardBorder,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                  title: Text(
                                    session.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isSelected ? const Color(0xFF60A5FA) : const Color(0xFF93C5FD),
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${session.messages.length} messages · ${_formatDate(session.updatedAt)}',
                                    style: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                                    onPressed: () async {
                                      await _deleteSession(session.id);
                                      final updated = await ChatStorageService().getSessions();
                                      setSheetState(() {
                                        sheetSessions = List.from(updated);
                                      });
                                    },
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _switchSession(session);
                                  },
                                ),
                              );
                            },
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

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (now.difference(dt).inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    final effectiveBottomPadding = bottomInset > 0 ? 10.0 : (bottomSafeArea + 78.0);

    return Column(
      children: [
        // Top Custom Header (Replaced static copilot tag with History + New Chat triggers)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: BrikCard(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            borderRadius: 24.0,
            height: 60.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // App Logo
                const AppLogo(width: 88, height: 24),

                // History & New Chat Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // History Button
                    GestureDetector(
                      onTap: _openChatHistorySheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: BrikTheme.cardSurfaceSecondary,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: BrikTheme.cardBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.history_rounded, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'CHATS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // + New Chat Button
                    GestureDetector(
                      onTap: () => _startNewChat(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                        decoration: BoxDecoration(
                          color: BrikTheme.brandNavy,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.add_rounded, color: Colors.white, size: 15),
                            SizedBox(width: 3),
                            Text(
                              'NEW CHAT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (widget.onSettingsPressed != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: widget.onSettingsPressed,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: BrikTheme.cardSurfaceSecondary,
                            shape: BoxShape.circle,
                            border: Border.all(color: BrikTheme.cardBorder),
                          ),
                          child: const Center(
                            child: Icon(Icons.settings_outlined, color: Colors.white, size: 15),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        // Direct Brand Merchant Products Toggle Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Toggle Button
              GestureDetector(
                onTap: () {
                  setState(() {
                    _includeMerchants = !_includeMerchants;
                  });
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _includeMerchants
                            ? '🛍️ Direct Brand Stores: ENABLED (Xiaomi, OnePlus, Samsung, boAt, etc.)'
                            : '🌐 Direct Brand Stores: DISABLED (Searching External Marketplaces Only)',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                      backgroundColor: _includeMerchants ? BrikTheme.brandNavy : const Color(0xFFE65100),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _includeMerchants ? BrikTheme.cardSurface : const Color(0xFF2B1400),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _includeMerchants ? BrikTheme.cardBorder : const Color(0xFFFF9800),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _includeMerchants ? Icons.storefront_rounded : Icons.storefront_outlined,
                        size: 13,
                        color: _includeMerchants ? const Color(0xFF64B5F6) : const Color(0xFFFFB74D),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _includeMerchants ? 'Direct Brands: ON' : 'Direct Brands: OFF',
                        style: TextStyle(
                          color: _includeMerchants ? Colors.white : const Color(0xFFFFB74D),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _includeMerchants ? const Color(0xFF00E676) : const Color(0xFFFF5252),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Filter State Indicator
              Text(
                _includeMerchants ? 'Direct Brands + Web Marketplaces' : 'External Stores Only (Amazon, Flipkart)',
                style: const TextStyle(
                  color: BrikTheme.textSecondaryOnDark,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // Message List / Empty State
        Expanded(
          child: _messages.isEmpty
              ? _buildEmptyAgentCanvas()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length) {
                      return _buildAgentReasoningBubble();
                    }
                    return _buildMessageBubble(_messages[index]);
                  },
                ),
        ),

        // Bottom Input Bar
        Container(
          padding: EdgeInsets.fromLTRB(16, 8, 16, effectiveBottomPadding),
          decoration: const BoxDecoration(
            color: BrikTheme.canvasBackground,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: BrikTheme.cardSurface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: BrikTheme.cardBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    cursorColor: BrikTheme.brandNavy,
                    decoration: const InputDecoration(
                      hintText: 'Ask anything (e.g. "Compare Sony vs boAt")...',
                      hintStyle: TextStyle(color: BrikTheme.textSecondaryOnDark, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                GestureDetector(
                  onTap: () => _sendMessage(_textController.text),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: BrikTheme.brandNavy,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyAgentCanvas() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const BrandMark(size: 72),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildStarterChip('Headphones under ₹3k', 'I need wireless headphones under ₹3,000 with good battery life'),
                _buildStarterChip('Compare Sony vs boAt', 'Compare Sony WH-CH520 vs boAt Rockerz 550'),
                _buildStarterChip('Smartphones under ₹25k', 'Show 5G smartphones under ₹25,000'),
                _buildStarterChip('Nike vs Puma shoes', 'Compare Nike Revolution vs Puma Flyer'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarterChip(String label, String prompt) {
    return GestureDetector(
      onTap: () => _sendMessage(prompt),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: BrikTheme.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: BrikTheme.cardBorder),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildAgentReasoningBubble() {
    return _LiveAgentProgressBubble(liveSteps: _liveRunningSteps);
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final isUser = msg['isUser'] == true;
    final text = msg['text']?.toString() ?? '';
    final products = (msg['products'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
    final comparison = msg['comparison'] as Map<String, dynamic>?;
    final steps = (msg['steps'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
    final actions = (msg['actions'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];

    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: const BoxConstraints(maxWidth: 320),
          decoration: BoxDecoration(
            color: BrikTheme.brandNavy,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Interactive Expandable Real Execution Tool Trace
            if (steps.isNotEmpty) _ExpandableStepsTraceCard(steps: steps),

            // 2. Main Response Text Bubble with clickable Markdown links
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BrikTheme.cardSurface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: BrikTheme.cardBorder),
              ),
              child: MarkdownBody(
                data: text,
                selectable: false,
                onTapLink: (text, href, title) async {
                  if (href != null && href.trim().isNotEmpty) {
                    var uriStr = href.trim();
                    if (!uriStr.startsWith('http://') && !uriStr.startsWith('https://')) {
                      uriStr = 'https://$uriStr';
                    }
                    try {
                      final uri = Uri.parse(uriStr);
                      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
                      if (!launched) {
                        await launchUrl(uri, mode: LaunchMode.platformDefault);
                      }
                    } catch (e) {
                      debugPrint('Could not launch url: $e');
                    }
                  }
                },
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    height: 1.45,
                  ),
                  strong: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                  em: const TextStyle(
                    color: BrikTheme.brandNavy,
                    fontStyle: FontStyle.italic,
                  ),
                  a: const TextStyle(
                    color: Color(0xFF90CAF9),
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                  h1: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                  h2: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                  h3: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14.5),
                  listBullet: const TextStyle(color: BrikTheme.brandNavy, fontSize: 14),
                  tableHead: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                  tableBody: const TextStyle(color: BrikTheme.textSecondaryOnDark, fontSize: 11.5),
                  tableBorder: TableBorder.all(color: BrikTheme.cardBorder, width: 1, borderRadius: BorderRadius.circular(8)),
                  tableCellsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
              ),
            ),

            // 3. Dynamic N x M Comparison Table (if generated by agent)
            if (comparison != null && comparison['columns'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _buildComparisonMatrixTable(comparison),
              ),

            // 4. Product Cards in Sleek Horizontal Scroll Carousel
            if (products.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: SizedBox(
                  height: 215,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: products.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 10),
                    itemBuilder: (context, index) => _buildHorizontalProductCard(products[index]),
                  ),
                ),
              ),

            // 5. Action Trigger Chips
            if (actions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: actions.map((act) {
                    final label = act['label']?.toString() ?? 'Action';
                    return GestureDetector(
                      onTap: () {
                        if (act['action'] == 'TOGGLE_MERCHANTS_OFF') {
                          setState(() {
                            _includeMerchants = false;
                          });
                        } else if (act['action'] == 'TOGGLE_MERCHANTS_ON') {
                          setState(() {
                            _includeMerchants = true;
                          });
                        }

                        if (act['action'] == 'ADD_TO_CART') {
                          final pid = act['payload']?['product_id'] ?? 1;
                          _handleAddToCart(pid is int ? pid : int.tryParse(pid.toString()) ?? 1);
                        } else if (act['payload']?['query'] != null) {
                          _sendMessage(act['payload']['query']);
                        } else {
                          _sendMessage(label);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: BrikTheme.cardSurfaceSecondary,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: BrikTheme.cardBorder),
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: BrikTheme.brandNavy,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonMatrixTable(Map<String, dynamic> comp) {
    final columns = (comp['columns'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final rows = (comp['rows'] as List?)?.map((r) => (r as List).map((c) => c.toString()).toList()).toList() ?? [];
    final title = comp['title']?.toString() ?? 'Intelligent Comparison Matrix';
    final recommendation = comp['recommendation']?.toString();

    if (columns.isEmpty || rows.isEmpty) return const SizedBox.shrink();

    return BrikCard(
      padding: const EdgeInsets.all(14),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚖️ 11-Point Specification Delta Matrix',
                      style: TextStyle(color: BrikTheme.brandNavy, fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const PillBadge(
                text: 'MULTI-SPEC N×M',
                fontSize: 8.5,
                backgroundColor: BrikTheme.brandNavy,
                textColor: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              border: TableBorder.all(
                color: BrikTheme.cardBorder,
                width: 1,
                borderRadius: BorderRadius.circular(12),
              ),
              headingRowColor: WidgetStateProperty.all(BrikTheme.cardSurfaceSecondary),
              dataRowColor: WidgetStateProperty.resolveWith<Color>((states) {
                return BrikTheme.cardSurface;
              }),
              columnSpacing: 18,
              horizontalMargin: 14,
              dataRowMinHeight: 44,
              dataRowMaxHeight: 76,
              headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
              columns: columns.asMap().entries.map((entry) {
                final idx = entry.key;
                final col = entry.value;
                return DataColumn(
                  label: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: idx == 0 ? 150 : 210),
                    child: Text(
                      col,
                      style: TextStyle(
                        color: idx == 0 ? const Color(0xFF64B5F6) : Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                );
              }).toList(),
              rows: rows.map((row) {
                return DataRow(
                  cells: row.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final cell = entry.value;
                    final isSpecLabel = idx == 0;
                    return DataCell(
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: isSpecLabel ? 150 : 220),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            cell,
                            style: TextStyle(
                              color: isSpecLabel ? const Color(0xFFFFD54F) : Colors.white,
                              fontWeight: isSpecLabel ? FontWeight.w700 : FontWeight.w500,
                              fontSize: isSpecLabel ? 11.5 : 11,
                              height: 1.25,
                            ),
                            softWrap: true,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
          if (recommendation != null && recommendation.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1B2A38),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x66FFB74D)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_rounded, color: Color(0xFFFFB74D), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      recommendation,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHorizontalProductCard(Map<String, dynamic> prod) {
    final name = prod['name']?.toString() ?? 'Product';
    final brand = prod['brand']?.toString() ?? 'Merchant Brand';
    final price = prod['price']?.toString() ?? '0';
    final rating = prod['rating']?.toString() ?? '4.6';
    final isPlatform = prod['is_platform_product'] != false && prod['source'] != 'SCRAPED_EXTERNAL';
    final merchantName = prod['merchant']?['name']?.toString() ?? (isPlatform ? 'Direct Merchant' : 'Marketplace');

    final externalUrl = prod['attributes']?['external_url']?.toString() ?? prod['external_url']?.toString() ?? '';

    // One single picture only
    final images = prod['images'] as List?;
    final singleImage = (images != null && images.isNotEmpty)
        ? images.first.toString()
        : (prod['image'] ?? prod['image_url'] ?? 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=300').toString();

    return GestureDetector(
      onTap: () => _openProductDetail(prod),
      child: Container(
        width: 190,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: BrikTheme.cardSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isPlatform ? BrikTheme.brandNavy.withValues(alpha: 0.6) : BrikTheme.cardBorder,
            width: isPlatform ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1 Single Hero Picture
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Image.network(
                    singleImage,
                    width: double.infinity,
                    height: 95,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 95,
                      color: BrikTheme.cardSurfaceSecondary,
                      child: const Center(
                        child: Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$rating ★',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Differentiated Platform vs Scraped Badge
            PillBadge(
              text: isPlatform ? '● MERCHANT DIRECT · 1-TAP' : '🌐 SCRAPED · ${merchantName.toUpperCase()}',
              backgroundColor: isPlatform ? BrikTheme.brandNavy : BrikTheme.cardSurfaceSecondary,
              textColor: Colors.white,
              fontSize: 7.5,
            ),
            const SizedBox(height: 5),

            // Title
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                height: 1.15,
              ),
            ),
            const Spacer(),

            // Price & Brand / External Link
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹$price',
                  style: TextStyle(
                    color: isPlatform ? BrikTheme.brandNavy : Colors.white70,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                if (!isPlatform && externalUrl.isNotEmpty) ...[
                  GestureDetector(
                    onTap: () async {
                      var uriStr = externalUrl.trim();
                      if (!uriStr.startsWith('http://') && !uriStr.startsWith('https://')) {
                        uriStr = 'https://$uriStr';
                      }
                      try {
                        final uri = Uri.parse(uriStr);
                        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
                        if (!launched) {
                          await launchUrl(uri, mode: LaunchMode.platformDefault);
                        }
                      } catch (e) {
                        debugPrint('Could not launch url: $e');
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: BrikTheme.cardSurfaceSecondary,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: BrikTheme.cardBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text('LINK', style: TextStyle(color: BrikTheme.brandNavy, fontSize: 8.5, fontWeight: FontWeight.w700)),
                          SizedBox(width: 2),
                          Icon(Icons.open_in_new_rounded, color: BrikTheme.brandNavy, size: 9),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  Text(
                    brand,
                    style: const TextStyle(
                      color: BrikTheme.textSecondaryOnDark,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Live Animated Agent Progress Bubble
// ─────────────────────────────────────────────────────────────────────────────
class _LiveAgentProgressBubble extends StatefulWidget {
  final List<Map<String, dynamic>> liveSteps;

  const _LiveAgentProgressBubble({this.liveSteps = const []});

  @override
  State<_LiveAgentProgressBubble> createState() => _LiveAgentProgressBubbleState();
}

class _LiveAgentProgressBubbleState extends State<_LiveAgentProgressBubble> {
  int _currentStage = 0;
  static const List<Map<String, String>> _stages = [
    {
      'icon': '🔍',
      'title': 'Querying Merchant APIs',
      'subtitle': 'Connecting to integrated brand catalog endpoints...',
    },
    {
      'icon': '🌐',
      'title': 'Scraping Live Marketplaces',
      'subtitle': 'Checking real-time prices across external stores...',
    },
    {
      'icon': '💬',
      'title': 'Mining Community Discussions',
      'subtitle': 'Searching Reddit threads & buyer forums via Tavily...',
    },
    {
      'icon': '📺',
      'title': 'Analyzing Video & Web Reviews',
      'subtitle': 'Extracting reviewer consensus via live web search...',
    },
    {
      'icon': '⚡',
      'title': 'Assembling Grounded Recommendation',
      'subtitle': 'Synthesizing specs, trade-offs & verified source links...',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startCycle();
  }

  void _startCycle() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 1400));
      if (mounted && widget.liveSteps.isEmpty) {
        setState(() {
          _currentStage = (_currentStage + 1) % _stages.length;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If real backend steps are streaming via SSE, show the real active tool!
    if (widget.liveSteps.isNotEmpty) {
      final latestStep = widget.liveSteps.last;
      final stepName = latestStep['step_name']?.toString() ?? 'Executing Agent Tool';
      final desc = latestStep['description']?.toString() ?? 'Processing live reasoning node...';
      final tool = latestStep['tool_name']?.toString();

      String icon = '⚡';
      if (tool == 'search_merchant_gateway') {
        icon = '🔍';
      } else if (tool == 'search_all_external_marketplaces') {
        icon = '🌐';
      } else if (tool == 'analyze_product_reviews') {
        icon = '💬';
      } else if (tool == 'gemini_grounded_synthesis') {
        icon = '🧠';
      }

      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          constraints: const BoxConstraints(maxWidth: 380),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: BrikTheme.cardSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: BrikTheme.cardBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: BrikTheme.brandNavy.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: BrikTheme.brandNavy,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    icon,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      stepName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: BrikTheme.brandNavy,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Tool ${widget.liveSteps.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 30),
                child: Text(
                  desc,
                  style: const TextStyle(
                    color: BrikTheme.textSecondaryOnDark,
                    fontSize: 11,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final stage = _stages[_currentStage];
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: BrikTheme.cardSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: BrikTheme.cardBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: BrikTheme.brandNavy.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: BrikTheme.brandNavy,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  stage['icon']!,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    stage['title']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${_currentStage + 1}/${_stages.length}',
                  style: const TextStyle(
                    color: BrikTheme.textSecondaryOnDark,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Text(
                stage['subtitle']!,
                style: const TextStyle(
                  color: BrikTheme.textSecondaryOnDark,
                  fontSize: 11,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Interactive Expandable Tool Execution Trace Card
// ─────────────────────────────────────────────────────────────────────────────
class _ExpandableStepsTraceCard extends StatefulWidget {
  final List<Map<String, dynamic>> steps;

  const _ExpandableStepsTraceCard({required this.steps});

  @override
  State<_ExpandableStepsTraceCard> createState() => _ExpandableStepsTraceCardState();
}

class _ExpandableStepsTraceCardState extends State<_ExpandableStepsTraceCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: BrikTheme.cardSurfaceSecondary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: BrikTheme.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: Colors.transparent,
                child: Row(
                  children: [
                    const Icon(Icons.bolt_rounded, color: BrikTheme.brandNavy, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '⚡ Agent Reasoning & Tool Trace (${widget.steps.length} tools executed)',
                        style: const TextStyle(
                          color: BrikTheme.brandNavy,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: BrikTheme.brandNavy,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            if (_isExpanded) ...[
              const Divider(height: 1, color: BrikTheme.cardBorder),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: widget.steps.asMap().entries.map((entry) {
                    final index = entry.key;
                    final step = entry.value;
                    final name = step['step_name']?.toString() ?? 'Agent Step';
                    final desc = step['description']?.toString() ?? '';
                    final tool = step['tool_name']?.toString();
                    final durationMs = step['duration_ms'] ?? 85;

                    return Padding(
                      padding: EdgeInsets.only(bottom: index == widget.steps.length - 1 ? 0 : 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: BrikTheme.brandNavy,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                          color: BrikTheme.brandNavy,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    if (tool != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.5),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          tool,
                                          style: const TextStyle(
                                            color: BrikTheme.brandNavy,
                                            fontSize: 9.5,
                                            fontFamily: 'monospace',
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${durationMs}ms',
                                      style: const TextStyle(
                                        color: BrikTheme.textSecondaryOnDark,
                                        fontSize: 9.5,
                                      ),
                                    ),
                                  ],
                                ),
                                if (desc.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    desc,
                                    style: const TextStyle(
                                      color: BrikTheme.textSecondaryOnDark,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

