import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/brik_theme.dart';
import '../../../core/services/supabase_auth_service.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/brik_card.dart';
import '../../../shared/widgets/brik_button.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    final success = await SupabaseAuthService().signInWithGoogle();
    setState(() => _isLoading = false);

    if (success && mounted) {
      widget.onLoginSuccess();
    } else if (mounted) {
      _showCustomLoginDialog(
        title: 'Complete Profile Sign In',
        subtitle: 'Enter your name and email to personalize your shopping copilot.',
      );
    }
  }

  Future<void> _showCustomLoginDialog({
    String title = 'Sign In to Mitrai',
    String subtitle = 'Enter your name and email to start shopping.',
  }) async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BrikTheme.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitle,
              style: const TextStyle(color: BrikTheme.textSecondaryOnDark, fontSize: 12.5),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Your Full Name',
                labelStyle: const TextStyle(color: BrikTheme.textSecondaryOnDark),
                filled: true,
                fillColor: BrikTheme.cardSurfaceSecondary,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Email Address',
                labelStyle: const TextStyle(color: BrikTheme.textSecondaryOnDark),
                filled: true,
                fillColor: BrikTheme.cardSurfaceSecondary,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: BrikTheme.brandNavy, fontWeight: FontWeight.w700)),
          ),
          BrikButton(
            text: 'CONTINUE ⚡',
            style: BrikButtonStyle.primaryLilac,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            onPressed: () async {
              final name = nameController.text.trim();
              final email = emailController.text.trim();
              if (name.isEmpty) return;

              final cleanEmail = email.isNotEmpty ? email : '${name.toLowerCase().replaceAll(' ', '')}@mitrai.ai';
              Navigator.pop(ctx);
              
              setState(() => _isLoading = true);
              await SupabaseAuthService().signInWithCustomIdentity(
                name: name,
                email: cleanEmail,
              );
              setState(() => _isLoading = false);
              
              if (mounted) {
                widget.onLoginSuccess();
              }
            },
          ),
        ],
      ),
    );
  }

  void _handleGuestSignIn() {
    SupabaseAuthService().signInAsDemoUser();
    widget.onLoginSuccess();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final isDesktop = screenWidth >= 768;

    // Responsive sizing
    final cardMaxWidth = isDesktop ? math.min(540.0, screenWidth * 0.85) : 460.0;
    final logoWidth = cardMaxWidth * 0.48;
    final logoHeight = logoWidth * 0.32;
    final characterHeight = isDesktop ? 330.0 : 290.0;

    return Scaffold(
      backgroundColor: BrikTheme.canvasBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: cardMaxWidth),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 20 : 16,
                vertical: isDesktop ? 20 : 12,
              ),
              child: JoinedCardGroup(
                margin: EdgeInsets.zero,
                children: [
                  // ── Slot 1: Header & Hero Value Proposition ───────────────────
                  JoinedCard(
                    padding: EdgeInsets.fromLTRB(
                      isDesktop ? 30 : 24,
                      isDesktop ? 26 : 22,
                      isDesktop ? 30 : 24,
                      isDesktop ? 22 : 18,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 1. Centered Large Brand Logo
                        Center(
                          child: AppLogo(
                            width: logoWidth,
                            height: logoHeight,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 2. Hero Title
                        Text(
                          'Natural-language\ncommerce experience.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isDesktop ? 19 : 17.5,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 3. Subtitle Metadata Tags (Discovery & Payments)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Discovery',
                                      style: TextStyle(
                                        color: BrikTheme.textSecondaryOnDark,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      'Conversational AI',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Payments',
                                      style: TextStyle(
                                        color: BrikTheme.textSecondaryOnDark,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      'Razorpay Secured',
                                      style: TextStyle(
                                        color: BrikTheme.accentLavender,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Slot 2: Character Depth Effect & Auth Actions ─────────
                  JoinedCard(
                    padding: EdgeInsets.fromLTRB(
                      isDesktop ? 28 : 22,
                      12,
                      isDesktop ? 28 : 22,
                      isDesktop ? 24 : 20,
                    ),
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        // Layer 1: Large Character Illustration
                        Padding(
                          padding: const EdgeInsets.only(top: 0),
                          child: SizedBox(
                            height: characterHeight,
                            child: Image.asset(
                              'assets/images/character.png',
                              height: characterHeight,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                Icons.shopping_bag_outlined,
                                size: 90,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        // Layer 2: Overlapping Text & Auth Actions over the lower legs
                        Padding(
                          padding: EdgeInsets.only(
                            top: characterHeight * 0.58,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  BrikTheme.cardSurface.withValues(alpha: 0.0),
                                  BrikTheme.cardSurface.withValues(alpha: 0.85),
                                  BrikTheme.cardSurface,
                                  BrikTheme.cardSurface,
                                ],
                                stops: const [0.0, 0.28, 0.55, 1.0],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.fromLTRB(10, 24, 10, 6),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Discover, compare specifications, and complete Razorpay payments through natural conversation.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: BrikTheme.textSecondaryOnDark,
                                    fontSize: 12.5,
                                    height: 1.4,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (_isLoading)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: CircularProgressIndicator(
                                      color: BrikTheme.brandNavy,
                                    ),
                                  )
                                else ...[
                                  BrikButton(
                                    text: 'Sign In with Google',
                                    isFullWidth: true,
                                    style: BrikButtonStyle.primaryLilac,
                                    icon: const Icon(
                                      Icons.g_mobiledata_rounded,
                                      color: BrikTheme.cardSurface,
                                      size: 26,
                                    ),
                                    onPressed: _handleGoogleSignIn,
                                  ),
                                  const SizedBox(height: 10),
                                  BrikButton(
                                    text: 'Continue as Guest',
                                    isFullWidth: true,
                                    style: BrikButtonStyle.secondary,
                                    onPressed: _handleGuestSignIn,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
