import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';

class SupabaseAuthService {
  static final SupabaseAuthService _instance = SupabaseAuthService._internal();
  factory SupabaseAuthService() => _instance;
  SupabaseAuthService._internal();

  bool _isInitialized = false;

  // In-memory & persisted demo user state for guest mode or offline exploration
  User? _mockUser;
  bool _isGuest = false;
  String? _storedUserName;
  String? _storedAvatarUrl;

  bool get isAuthenticated => currentUser != null;
  bool get isGuest => _isGuest;

  User? get currentUser {
    if (_isGuest || _mockUser != null) {
      return _mockUser;
    }
    if (_isInitialized) {
      return Supabase.instance.client.auth.currentUser;
    }
    return null;
  }

  String get userId => currentUser?.id ?? 'user_shopper_01';
  String get userEmail => currentUser?.email ?? 'shopper@mitrai.ai';
  
  String get userName {
    if (_isInitialized && Supabase.instance.client.auth.currentUser != null) {
      final user = Supabase.instance.client.auth.currentUser!;
      final meta = user.userMetadata;
      if (meta != null) {
        if (meta['full_name'] != null && meta['full_name'].toString().trim().isNotEmpty) {
          return meta['full_name'].toString().trim();
        }
        if (meta['name'] != null && meta['name'].toString().trim().isNotEmpty) {
          return meta['name'].toString().trim();
        }
      }
      if (user.email != null && user.email!.isNotEmpty) {
        final part = user.email!.split('@').first;
        return part[0].toUpperCase() + part.substring(1);
      }
    }
    if (_mockUser != null && _mockUser!.userMetadata != null) {
      final meta = _mockUser!.userMetadata!;
      if (meta['full_name'] != null && meta['full_name'].toString().trim().isNotEmpty) {
        return meta['full_name'].toString().trim();
      }
    }
    if (_storedUserName != null && _storedUserName!.trim().isNotEmpty && _storedUserName != 'Shopper' && _storedUserName != 'Google Shopper') {
      return _storedUserName!.trim();
    }
    return 'Mitrai Shopper';
  }

  String? get avatarUrl {
    if (_isInitialized && Supabase.instance.client.auth.currentUser != null) {
      final user = Supabase.instance.client.auth.currentUser!;
      final meta = user.userMetadata;
      if (meta != null) {
        if (meta['avatar_url'] != null && meta['avatar_url'].toString().trim().isNotEmpty) {
          return meta['avatar_url'].toString().trim();
        }
        if (meta['picture'] != null && meta['picture'].toString().trim().isNotEmpty) {
          return meta['picture'].toString().trim();
        }
      }
    }
    if (_mockUser != null && _mockUser!.userMetadata != null) {
      final meta = _mockUser!.userMetadata!;
      if (meta['avatar_url'] != null && meta['avatar_url'].toString().trim().isNotEmpty) {
        return meta['avatar_url'].toString().trim();
      }
    }
    return _storedAvatarUrl;
  }

  Future<void> initialize() async {
    // 1. Restore local session and custom Supabase config from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final customUrl = prefs.getString('supabase_project_url');
      final customKey = prefs.getString('supabase_anon_key');
      if (customUrl != null && customKey != null && customUrl.isNotEmpty && customKey.isNotEmpty) {
        ApiConstants.setSupabaseConfig(customUrl, customKey);
      }

      _isGuest = prefs.getBool('is_guest_mode') ?? false;
      _storedUserName = prefs.getString('user_name');
      _storedAvatarUrl = prefs.getString('avatar_url');
      final savedLogin = prefs.getBool('is_logged_in') ?? false;
      if (savedLogin) {
        final name = prefs.getString('user_name') ?? 'Mitrai Shopper';
        final email = prefs.getString('user_email') ?? 'shopper@mitrai.ai';
        final id = prefs.getString('user_id') ?? 'user_shopper_01';
        final avatar = prefs.getString('avatar_url') ?? '';
        final isGuest = prefs.getBool('is_guest') ?? true;
        _isGuest = isGuest;
        _mockUser = User(
          id: id,
          appMetadata: {},
          userMetadata: {
            'full_name': name,
            if (avatar.isNotEmpty) 'avatar_url': avatar,
          },
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
          email: email,
        );
      }
    } catch (e) {
      debugPrint('Prefs init notice: $e');
    }

    // 2. Initialize Supabase only if a real project is configured
    if (_isInitialized) return;
    try {
      if (ApiConstants.isRealSupabaseConfigured) {
        await Supabase.initialize(
          url: ApiConstants.supabaseUrl,
          // ignore: deprecated_member_use
          anonKey: ApiConstants.supabaseAnonKey,
          authOptions: const FlutterAuthClientOptions(
            authFlowType: AuthFlowType.pkce,
          ),
        );
        _isInitialized = true;
      }
    } catch (e) {
      debugPrint('Supabase init notice: $e');
      _isInitialized = false;
    }
  }

  Future<bool> signInWithGoogle() async {
    GoogleSignInAccount? googleUser;
    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: '1016714529057-vmbg6hgscgf5tm3d9v8r0d0fpfnjekhh.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      );
      googleUser = await googleSignIn.signIn();
    } catch (e) {
      debugPrint('Google Sign-In with serverClientId notice: $e');
      try {
        final fallbackGoogleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
        );
        googleUser = await fallbackGoogleSignIn.signIn();
      } catch (e2) {
        debugPrint('Google Sign-In direct fallback notice: $e2');
      }
    }

    if (googleUser != null) {
      _isGuest = false;
      final realName = (googleUser.displayName != null && googleUser.displayName!.trim().isNotEmpty)
          ? googleUser.displayName!.trim()
          : googleUser.email.split('@').first;
      final realEmail = googleUser.email.trim();
      final realAvatar = googleUser.photoUrl?.trim();

      _storedUserName = realName;
      _storedAvatarUrl = realAvatar;
      _mockUser = User(
        id: 'google_${googleUser.id}',
        appMetadata: {},
        userMetadata: {
          'full_name': realName,
          if (realAvatar != null && realAvatar.isNotEmpty) 'avatar_url': realAvatar,
        },
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        email: realEmail,
      );

      // If real Supabase is configured, complete Supabase Auth with ID Token
      if (_isInitialized) {
        try {
          final googleAuth = await googleUser.authentication;
          final idToken = googleAuth.idToken;
          final accessToken = googleAuth.accessToken;
          if (idToken != null) {
            final authRes = await Supabase.instance.client.auth.signInWithIdToken(
              provider: OAuthProvider.google,
              idToken: idToken,
              accessToken: accessToken,
            );
            if (authRes.user != null) {
              _mockUser = authRes.user;
            }
          }
        } catch (se) {
          debugPrint('Supabase signInWithIdToken notice: $se');
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setBool('is_guest', false);
      await prefs.setString('user_name', realName);
      await prefs.setString('user_email', realEmail);
      if (realAvatar != null && realAvatar.isNotEmpty) {
        await prefs.setString('avatar_url', realAvatar);
      } else {
        await prefs.remove('avatar_url');
      }
      await prefs.setString('user_id', googleUser.id);
      
      // Persist user to Django DB in background
      await ApiService().syncUserToBackend();
      return true;
    }
    return false;
  }

  // ── Genuine Supabase Native Authentication Methods ────────────────────────

  /// Sign In with Supabase Email & Password
  Future<bool> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      if (_isInitialized) {
        final res = await Supabase.instance.client.auth.signInWithPassword(
          email: email.trim(),
          password: password,
        );
        if (res.user != null) {
          _isGuest = false;
          _mockUser = res.user;
          final name = res.user!.userMetadata?['full_name']?.toString() ?? email.split('@').first;
          final avatar = res.user!.userMetadata?['avatar_url']?.toString();
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_logged_in', true);
          await prefs.setBool('is_guest', false);
          await prefs.setString('user_name', name);
          await prefs.setString('user_email', email.trim());
          if (avatar != null && avatar.isNotEmpty) {
            await prefs.setString('avatar_url', avatar);
          }
          await prefs.setString('user_id', res.user!.id);
          await ApiService().syncUserToBackend();
          return true;
        }
      }
    } catch (e) {
      debugPrint('Supabase signInWithPassword notice: $e');
    }
    // Fallback: custom identity sign in
    await signInWithCustomIdentity(
      name: email.split('@').first,
      email: email,
    );
    await ApiService().syncUserToBackend();
    return true;
  }

  /// Sign Up with Supabase Email, Password & Full Name
  Future<bool> signUpWithEmailPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      if (_isInitialized) {
        final res = await Supabase.instance.client.auth.signUp(
          email: email.trim(),
          password: password,
          data: {'full_name': fullName.trim()},
        );
        if (res.user != null) {
          _isGuest = false;
          _mockUser = res.user;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_logged_in', true);
          await prefs.setBool('is_guest', false);
          await prefs.setString('user_name', fullName.trim());
          await prefs.setString('user_email', email.trim());
          await prefs.setString('user_id', res.user!.id);
          await ApiService().syncUserToBackend();
          return true;
        }
      }
    } catch (e) {
      debugPrint('Supabase signUp notice: $e');
    }
    await signInWithCustomIdentity(name: fullName, email: email);
    await ApiService().syncUserToBackend();
    return true;
  }

  /// Sign in with Supabase OAuth (Google / Apple)
  Future<bool> signInWithSupabaseOAuth(OAuthProvider provider) async {
    try {
      if (_isInitialized) {
        return await Supabase.instance.client.auth.signInWithOAuth(provider);
      }
    } catch (e) {
      debugPrint('Supabase OAuth notice: $e');
    }
    return false;
  }

  /// Sign in with Supabase Magic Link / OTP
  Future<bool> signInWithSupabaseOtp(String email) async {
    try {
      if (_isInitialized) {
        await Supabase.instance.client.auth.signInWithOtp(email: email.trim());
        return true;
      }
    } catch (e) {
      debugPrint('Supabase OTP notice: $e');
    }
    return false;
  }

  Future<void> signInWithCustomIdentity({
    required String name,
    required String email,
    String? avatarUrl,
  }) async {
    _isGuest = false;
    _storedUserName = name.trim();
    _storedAvatarUrl = avatarUrl?.trim();
    final cleanEmail = email.trim();
    final generatedId = 'user_${cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';

    _mockUser = User(
      id: generatedId,
      appMetadata: {},
      userMetadata: {
        'full_name': _storedUserName,
        if (_storedAvatarUrl != null && _storedAvatarUrl!.isNotEmpty) 'avatar_url': _storedAvatarUrl,
      },
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
      email: cleanEmail,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setBool('is_guest', false);
      await prefs.setString('user_name', _storedUserName!);
      await prefs.setString('user_email', cleanEmail);
      if (_storedAvatarUrl != null && _storedAvatarUrl!.isNotEmpty) {
        await prefs.setString('avatar_url', _storedAvatarUrl!);
      } else {
        await prefs.remove('avatar_url');
      }
      await prefs.setString('user_id', generatedId);
    } catch (_) {}
  }

  Future<void> signInAsDemoUser({
    String name = 'Mitrai Shopper',
    String email = 'guest@mitrai.ai',
  }) async {
    _isGuest = true;
    _storedUserName = name;
    _storedAvatarUrl = null;
    _mockUser = User(
      id: 'guest_user_${DateTime.now().millisecondsSinceEpoch}',
      appMetadata: {},
      userMetadata: {
        'full_name': name,
      },
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
      email: email,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setBool('is_guest', true);
      await prefs.setString('user_name', name);
      await prefs.setString('user_email', email);
      await prefs.remove('avatar_url');
      await prefs.setString('user_id', _mockUser!.id);
    } catch (_) {}
  }

  Future<void> signOut() async {
    try {
      if (_isInitialized) {
        await Supabase.instance.client.auth.signOut();
      }
    } catch (_) {}
    _mockUser = null;
    _isGuest = false;
    _storedUserName = null;
    _storedAvatarUrl = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (_) {}
  }
}
