import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final String formattedAddress;
  final String city;

  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    this.city = 'Bangalore',
  });
}

class PermissionStatusModel {
  final bool notificationGranted;
  final bool locationGranted;
  final bool accessibilityGranted;
  final bool overlayGranted;

  PermissionStatusModel({
    required this.notificationGranted,
    required this.locationGranted,
    required this.accessibilityGranted,
    required this.overlayGranted,
  });

  bool get allGranted =>
      notificationGranted && locationGranted && accessibilityGranted && overlayGranted;
}

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  static const MethodChannel _channel = MethodChannel('com.mitrai.mitrai/accessibility');

  bool get _isMobilePlatform => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Function(String package, String context)? onECommerceAppDetected;

  void initialize() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onECommerceAppDetected') {
        final args = call.arguments as Map<dynamic, dynamic>?;
        final pkg = args?['package']?.toString() ?? '';
        final ctx = args?['context']?.toString() ?? '';
        if (onECommerceAppDetected != null) {
          onECommerceAppDetected!(pkg, ctx);
        }
      }
    });
  }

  Future<PermissionStatusModel> checkAllPermissions() async {
    if (kIsWeb || !_isMobilePlatform) {
      return PermissionStatusModel(
        notificationGranted: true,
        locationGranted: true,
        accessibilityGranted: true,
        overlayGranted: true,
      );
    }

    bool notifGranted = false;
    try {
      final notifStatus = await Permission.notification.status;
      notifGranted = notifStatus.isGranted;
    } catch (_) {
      notifGranted = true;
    }

    bool locGranted = false;
    try {
      final locStatus = await Geolocator.checkPermission();
      locGranted = locStatus == LocationPermission.always || locStatus == LocationPermission.whileInUse;
    } catch (_) {
      locGranted = true;
    }

    final isAccess = await isAccessibilityEnabled();
    final isOverlay = await isOverlayPermissionGranted();

    return PermissionStatusModel(
      notificationGranted: notifGranted,
      locationGranted: locGranted,
      accessibilityGranted: isAccess,
      overlayGranted: isOverlay,
    );
  }

  Future<bool> requestNotificationPermission() async {
    if (kIsWeb || !_isMobilePlatform) return true;
    try {
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('Notification request notice: $e');
      return true;
    }
  }

  Future<bool> requestLocationPermission() async {
    if (kIsWeb || !_isMobilePlatform) return true;
    try {
      final status = await Geolocator.requestPermission();
      return status == LocationPermission.always || status == LocationPermission.whileInUse;
    } catch (e) {
      debugPrint('Location request notice: $e');
      return true;
    }
  }

  Future<bool> isAccessibilityEnabled() async {
    if (kIsWeb) return true;
    try {
      final bool? enabled = await _channel.invokeMethod<bool>('isAccessibilityEnabled');
      return enabled ?? false;
    } catch (e) {
      debugPrint('Accessibility check notice: $e');
      return false;
    }
  }

  Future<void> openAccessibilitySettings() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
      return;
    } catch (_) {}

    try {
      await openAppSettings();
    } catch (_) {}
  }

  Future<bool> isOverlayPermissionGranted() async {
    if (kIsWeb) return true;
    try {
      final bool? granted = await _channel.invokeMethod<bool>('isOverlayPermissionGranted');
      return granted ?? false;
    } catch (e) {
      debugPrint('Overlay check notice: $e');
      return false;
    }
  }

  Future<void> openOverlaySettings() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod('openOverlaySettings');
      return;
    } catch (_) {}

    try {
      await openAppSettings();
    } catch (_) {}
  }

  Future<LocationResult?> requestLocationAndFetchAddress() async {
    final granted = await requestLocationPermission();
    if (!granted) return null;

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final addr = 'Lat: ${pos.latitude.toStringAsFixed(4)}, Long: ${pos.longitude.toStringAsFixed(4)} (Express Delivery Zone)';
      return LocationResult(
        latitude: pos.latitude,
        longitude: pos.longitude,
        formattedAddress: addr,
        city: 'Bangalore',
      );
    } catch (e) {
      debugPrint('Location fetch notice: $e');
      return LocationResult(
        latitude: 12.9716,
        longitude: 77.5946,
        formattedAddress: 'Bangalore, Karnataka, India (Default Hub)',
        city: 'Bangalore',
      );
    }
  }

  Future<bool> hasShownPermissionOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('has_completed_permission_onboarding') ?? false;
  }

  Future<void> markPermissionOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_permission_onboarding', true);
  }
}
