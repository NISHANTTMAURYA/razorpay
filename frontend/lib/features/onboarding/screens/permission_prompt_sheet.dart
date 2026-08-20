import 'package:flutter/material.dart';
import '../../../core/theme/brik_theme.dart';
import '../../../core/services/permission_service.dart';
import '../../../shared/widgets/brik_card.dart';
import '../../../shared/widgets/brik_button.dart';
import '../../../shared/widgets/pill_badge.dart';

class PermissionPromptSheet extends StatefulWidget {
  final VoidCallback onComplete;

  const PermissionPromptSheet({super.key, required this.onComplete});

  static Future<void> showIfNeeded(BuildContext context, {VoidCallback? onComplete, bool force = false}) async {
    final status = await PermissionService().checkAllPermissions();
    if ((force || !status.allGranted) && context.mounted) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => PermissionPromptSheet(
          onComplete: () {
            Navigator.pop(ctx);
            if (onComplete != null) onComplete();
          },
        ),
      );
    }
  }

  @override
  State<PermissionPromptSheet> createState() => _PermissionPromptSheetState();
}

class _PermissionPromptSheetState extends State<PermissionPromptSheet> with WidgetsBindingObserver {
  final _service = PermissionService();
  bool _notificationGranted = false;
  bool _locationGranted = false;
  bool _accessibilityGranted = false;
  bool _overlayGranted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAndRequestSystemPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPermissions();
    }
  }

  Future<void> _initAndRequestSystemPermissions() async {
    await _refreshPermissions();
    // Auto-trigger native OS dialogs for Notification & Location if not yet granted
    if (!_notificationGranted) {
      await _service.requestNotificationPermission();
    }
    if (!_locationGranted) {
      await _service.requestLocationPermission();
    }
    await _refreshPermissions();
  }

  Future<void> _refreshPermissions() async {
    final status = await _service.checkAllPermissions();
    if (mounted) {
      setState(() {
        _notificationGranted = status.notificationGranted;
        _locationGranted = status.locationGranted;
        _accessibilityGranted = status.accessibilityGranted;
        _overlayGranted = status.overlayGranted;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestNotification() async {
    await _service.requestNotificationPermission();
    await _refreshPermissions();
  }

  Future<void> _requestLocation() async {
    await _service.requestLocationPermission();
    await _refreshPermissions();
  }

  Future<void> _requestAccessibility() async {
    await _service.openAccessibilitySettings();
  }

  Future<void> _requestOverlay() async {
    await _service.openOverlaySettings();
  }

  Future<void> _enableAllPermissions() async {
    if (!_notificationGranted) {
      await _service.requestNotificationPermission();
    }
    if (!_locationGranted) {
      await _service.requestLocationPermission();
    }
    await _refreshPermissions();

    if (!_accessibilityGranted) {
      await _service.openAccessibilitySettings();
      return;
    }
    if (!_overlayGranted) {
      await _service.openOverlaySettings();
      return;
    }
    await _finishOnboarding();
  }

  Future<void> _finishOnboarding() async {
    await _service.markPermissionOnboardingComplete();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final allGranted = _notificationGranted && _locationGranted && _accessibilityGranted && _overlayGranted;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: BrikTheme.canvasBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 14, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 4,
                      decoration: BoxDecoration(
                        color: BrikTheme.brandNavy.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'COPILOT PERMISSIONS SETUP',
                      style: TextStyle(
                        color: BrikTheme.brandNavy,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _finishOnboarding,
                  icon: const Icon(Icons.close_rounded, color: BrikTheme.brandNavy, size: 20),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Card
                  BrikCard(
                    padding: const EdgeInsets.all(18),
                    margin: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const PillBadge(
                          text: 'REAL-TIME SHOPPING ASSISTANT (ZAVE-STYLE)',
                          backgroundColor: BrikTheme.brandNavy,
                          textColor: Colors.white,
                          fontSize: 9.5,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Enable Background Shopping Copilot',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Mitrai needs these permissions to detect when you browse Amazon, Flipkart, Blinkit, or Zepto and float a 1-tap assistant button over other apps.',
                          style: TextStyle(
                            color: BrikTheme.textSecondaryOnDark,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(color: BrikTheme.brandNavy),
                      ),
                    )
                  else ...[
                    // 1. Notifications
                    _buildPermissionTile(
                      icon: Icons.notifications_active_rounded,
                      title: '1. Push Notifications',
                      description: 'Get notified for flash deals, price drop radars, and delivery updates.',
                      isGranted: _notificationGranted,
                      actionLabel: 'GRANT NOTIFICATION',
                      onAction: _requestNotification,
                    ),
                    const SizedBox(height: 10),

                    // 2. Location
                    _buildPermissionTile(
                      icon: Icons.location_on_rounded,
                      title: '2. Location Access',
                      description: 'Calculates accurate instant delivery from local Blinkit & Zepto dark stores.',
                      isGranted: _locationGranted,
                      actionLabel: 'GRANT LOCATION',
                      onAction: _requestLocation,
                    ),
                    const SizedBox(height: 10),

                    // 3. Accessibility Service
                    _buildPermissionTile(
                      icon: Icons.auto_awesome_rounded,
                      title: '3. Accessibility (Shopping App Detection)',
                      description: 'Detects when you open Amazon, Flipkart, Blinkit, or Zepto to activate the copilot.',
                      isGranted: _accessibilityGranted,
                      actionLabel: 'ENABLE IN ACCESSIBILITY',
                      onAction: _requestAccessibility,
                    ),
                    const SizedBox(height: 10),

                    // 4. Display Over Other Apps (Overlay)
                    _buildPermissionTile(
                      icon: Icons.picture_in_picture_alt_rounded,
                      title: '4. Display Over Other Apps (Overlay)',
                      description: 'Allows the floating "⚡ Mitrai AI" button to appear right over shopping apps.',
                      isGranted: _overlayGranted,
                      actionLabel: 'GRANT OVERLAY PERMISSION',
                      onAction: _requestOverlay,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom Action
          Container(
            padding: EdgeInsets.fromLTRB(18, 12, 18, MediaQuery.of(context).padding.bottom + 12),
            decoration: const BoxDecoration(
              color: BrikTheme.canvasBackground,
              border: Border(top: BorderSide(color: BrikTheme.cardBorder)),
            ),
            child: BrikButton(
              text: allGranted ? 'CONTINUE TO MITRAI ✅' : 'ENABLE PERMISSIONS',
              isFullWidth: true,
              style: BrikButtonStyle.primaryLilac,
              onPressed: allGranted ? _finishOnboarding : _enableAllPermissions,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionTile({
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return BrikCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isGranted
                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                  : BrikTheme.brandNavy.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isGranted ? Icons.check_circle_rounded : icon,
              color: isGranted ? const Color(0xFF10B981) : Colors.white,
              size: 20,
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
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isGranted)
                      const PillBadge(
                        text: 'GRANTED',
                        backgroundColor: Color(0xFF10B981),
                        textColor: Colors.white,
                        fontSize: 9,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: BrikTheme.textSecondaryOnDark,
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
                if (!isGranted) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: onAction,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: BrikTheme.brandNavy,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        actionLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
