import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/brik_theme.dart';
import '../../../core/services/supabase_auth_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/permission_service.dart';
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
  String _deliveryAddress = '';
  String _phoneNumber = '';
  String _userDisplayName = '';
  bool _notificationsEnabled = false;
  bool _isDetectingLocation = false;
  List<Map<String, dynamic>> _watchers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileAndSettings();
  }

  Future<void> _loadProfileAndSettings() async {
    final auth = SupabaseAuthService();
    String name = auth.userName;
    String address = '';
    String phone = '';
    bool notifs = false;

    // 1. Read local cache
    try {
      final prefs = await SharedPreferences.getInstance();
      address = prefs.getString('pref_delivery_address') ?? '';
      phone = prefs.getString('pref_phone_number') ?? '';
      notifs = prefs.getBool('pref_notifications_enabled') ?? false;
      final savedName = prefs.getString('user_name');
      if (savedName != null && savedName.trim().isNotEmpty) {
        name = savedName.trim();
      }
    } catch (_) {}

    // 2. Fetch backend profile to sync if available
    final backendProfile = await ApiService().getUserProfile();
    if (backendProfile != null) {
      if (backendProfile['delivery_address'] != null && backendProfile['delivery_address'].toString().trim().isNotEmpty) {
        address = backendProfile['delivery_address'].toString().trim();
      }
      if (backendProfile['phone'] != null && backendProfile['phone'].toString().trim().isNotEmpty) {
        phone = backendProfile['phone'].toString().trim();
      }
      if (backendProfile['full_name'] != null && backendProfile['full_name'].toString().trim().isNotEmpty) {
        name = backendProfile['full_name'].toString().trim();
      }
      if (backendProfile['notifications_enabled'] != null) {
        notifs = backendProfile['notifications_enabled'] == true;
      }
    }

    // 3. Fetch active watchers
    final watchersList = await ApiService().getWatchers();

    if (!mounted) return;
    setState(() {
      _userDisplayName = name;
      _deliveryAddress = address;
      _phoneNumber = phone;
      _notificationsEnabled = notifs;
      _watchers = watchersList;
      _isLoading = false;
    });
  }

  Future<void> _detectCurrentLocation() async {
    setState(() => _isDetectingLocation = true);
    final messenger = ScaffoldMessenger.of(context);
    
    final result = await PermissionService().requestLocationAndFetchAddress();
    if (!mounted) return;
    setState(() => _isDetectingLocation = false);

    if (result != null && result.formattedAddress.isNotEmpty) {
      setState(() {
        _deliveryAddress = result.formattedAddress;
      });
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: BrikTheme.brandNavy,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Text(
            'Location detected: ${result.city.isNotEmpty ? result.city : "Address updated"} & saved to DB.',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: BrikTheme.brandNavy,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: const Text(
            'Location permission denied or unavailable.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
  }

  Future<void> _toggleNotificationPermission(bool value) async {
    setState(() => _notificationsEnabled = value);
    if (value) {
      await PermissionService().requestNotificationPermission();
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pref_notifications_enabled', false);
      await ApiService().updateUserProfile({'notifications_enabled': false});
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: BrikTheme.brandNavy,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Text(
            value ? 'Notification permissions enabled & saved in DB.' : 'Notifications disabled.',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
  }

  Future<void> _cancelWatcher(String id) async {
    final messenger = ScaffoldMessenger.of(context);
    final success = await ApiService().deleteWatcher(id);
    if (success) {
      setState(() {
        _watchers.removeWhere((w) => w['id']?.toString() == id);
      });
    }
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: BrikTheme.brandNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(
          success ? 'Radar watcher removed.' : 'Failed to cancel watcher on server.',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Future<void> _editProfileDialog() async {
    final nameController = TextEditingController(text: _userDisplayName);
    final phoneController = TextEditingController(text: _phoneNumber);
    final addressController = TextEditingController(text: _deliveryAddress);

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BrikTheme.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Edit Profile & Delivery Address',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: const TextStyle(color: BrikTheme.textSecondaryOnDark),
                  filled: true,
                  fillColor: BrikTheme.cardSurfaceSecondary,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: const TextStyle(color: BrikTheme.textSecondaryOnDark),
                  filled: true,
                  fillColor: BrikTheme.cardSurfaceSecondary,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                decoration: InputDecoration(
                  labelText: 'Delivery Address',
                  labelStyle: const TextStyle(color: BrikTheme.textSecondaryOnDark),
                  filled: true,
                  fillColor: BrikTheme.cardSurfaceSecondary,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL', style: TextStyle(color: BrikTheme.brandNavy, fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SAVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (saved == true && mounted) {
      final newName = nameController.text.trim();
      final newPhone = phoneController.text.trim();
      final newAddr = addressController.text.trim();

      setState(() {
        if (newName.isNotEmpty) _userDisplayName = newName;
        _phoneNumber = newPhone;
        _deliveryAddress = newAddr;
      });

      try {
        final prefs = await SharedPreferences.getInstance();
        if (newName.isNotEmpty) await prefs.setString('user_name', newName);
        await prefs.setString('pref_phone_number', newPhone);
        await prefs.setString('pref_delivery_address', newAddr);
      } catch (_) {}

      await ApiService().updateUserProfile({
        'full_name': _userDisplayName,
        'phone': _phoneNumber,
        'delivery_address': _deliveryAddress,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: BrikTheme.brandNavy,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            content: const Text(
              'Profile and address saved in DB.',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        );
      }
    }
  }

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
          'Are you sure you want to end your active shopping session?',
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
        Navigator.pop(context);
        widget.onSignOut();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = SupabaseAuthService();
    final userEmail = auth.userEmail;
    final avatarUrl = auth.avatarUrl;
    final isGuest = auth.isGuest;
    final displayName = _userDisplayName.isNotEmpty ? _userDisplayName : auth.userName;
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    final effectiveBottomPadding = bottomSafeArea + 32.0;

    return Scaffold(
      backgroundColor: BrikTheme.canvasBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 12, 16, effectiveBottomPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Header Card
                  BrikHeaderCard(
                    tagText: 'SETTINGS',
                    margin: const EdgeInsets.only(bottom: 12),
                    onBack: () => Navigator.pop(context),
                  ),

                  // 2. Profile & Delivery Address (Curved Ticket Notch Effect)
                  JoinedCardGroup(
                    margin: const EdgeInsets.only(bottom: 12),
                    notchDepth: 28.0,
                    notchHalfHeight: 4.5,
                    notchCornerRadius: 16.0,
                    outerRadius: 28.0,
                    children: [
                      // Top Slot: User Account Info (Real Photo, Name, Email)
                      JoinedCard(
                        padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
                        child: Row(
                          children: [
                            // Profile Avatar
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: BrikTheme.brandNavy,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: (avatarUrl != null && avatarUrl.isNotEmpty)
                                  ? Image.network(
                                      avatarUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Center(
                                        child: Text(
                                          displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
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
                                          displayName,
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
                                        text: isGuest ? 'GUEST' : 'LOGGED IN',
                                        backgroundColor: BrikTheme.brandNavy,
                                        textColor: Colors.white,
                                        fontSize: 9,
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    userEmail,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: BrikTheme.textSecondaryOnDark,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bottom Slot: Saved Delivery Address
                      JoinedCard(
                        padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Delivery Address',
                                  style: TextStyle(
                                    color: BrikTheme.brandNavy,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Row(
                                  children: [
                                    // GPS Location Detector Button
                                    GestureDetector(
                                      onTap: _isDetectingLocation ? null : _detectCurrentLocation,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        margin: const EdgeInsets.only(right: 6),
                                        decoration: BoxDecoration(
                                          color: BrikTheme.brandNavy,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (_isDetectingLocation)
                                              const SizedBox(
                                                width: 10,
                                                height: 10,
                                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 1.5),
                                              )
                                            else
                                              const Icon(Icons.my_location_rounded, color: Colors.white, size: 11),
                                            const SizedBox(width: 4),
                                            const Text('AUTO-LOCATE', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _editProfileDialog,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: BrikTheme.brandNavy,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.edit_outlined, color: Colors.white, size: 11),
                                            const SizedBox(width: 4),
                                            Text(
                                              _deliveryAddress.isNotEmpty ? 'EDIT' : 'ADD',
                                              style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_deliveryAddress.isNotEmpty) ...[
                              Text(
                                '$displayName${_phoneNumber.isNotEmpty ? ' • $_phoneNumber' : ''}\n$_deliveryAddress',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  height: 1.35,
                                ),
                              ),
                            ] else ...[
                              const Text(
                                'No delivery address saved yet.\nTap AUTO-LOCATE or ADD to set your shipping address.',
                                style: TextStyle(
                                  color: BrikTheme.textSecondaryOnDark,
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  // 3. Permissions & Notifications Card
                  BrikCard(
                    padding: const EdgeInsets.all(18),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Permissions & Alerts',
                          style: TextStyle(
                            color: BrikTheme.brandNavy,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Price Drop & Order Notifications',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Receive real-time price radar & shipping alerts',
                                    style: TextStyle(color: BrikTheme.textSecondaryOnDark, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _notificationsEnabled,
                              activeThumbColor: Colors.white,
                              activeTrackColor: BrikTheme.brandNavy,
                              onChanged: _toggleNotificationPermission,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 4. Active Watcher Radar Card (Real Backend Watchers Only)
                  BrikCard(
                    padding: const EdgeInsets.all(18),
                    margin: const EdgeInsets.only(bottom: 16),
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
                                  decoration: BoxDecoration(
                                    color: _watchers.isNotEmpty
                                        ? BrikTheme.brandNavy
                                        : BrikTheme.textSecondaryOnDark,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Price Radar Watchers',
                                  style: TextStyle(color: BrikTheme.brandNavy, fontSize: 13, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            PillBadge(
                              text: '${_watchers.length} ACTIVE',
                              backgroundColor: BrikTheme.brandNavy,
                              textColor: Colors.white,
                              fontSize: 9.5,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_isLoading) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator(color: BrikTheme.brandNavy, strokeWidth: 2)),
                          ),
                        ] else if (_watchers.isEmpty) ...[
                          const Text(
                            'No active price watchers.',
                            style: TextStyle(color: BrikTheme.textSecondaryOnDark, fontSize: 12),
                          ),
                        ] else
                          ..._watchers.map((watcher) {
                            final wId = watcher['id']?.toString() ?? '';
                            final prodName = watcher['product']?['name']?.toString() ?? watcher['search_query']?.toString() ?? 'Monitored Product';
                            final targetVal = watcher['target_price']?.toString() ?? watcher['target_value']?.toString() ?? '';
                            final cond = targetVal.isNotEmpty
                                ? 'Target: ₹$targetVal · Active'
                                : 'Price Drop Alert · Active';

                            return Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Container(
                                padding: const EdgeInsets.all(14),
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
                                            prodName,
                                            style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            cond,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: BrikTheme.textSecondaryOnDark, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => _cancelWatcher(wId),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: BrikTheme.cardSurface,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: BrikTheme.cardBorder),
                                        ),
                                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
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
}
