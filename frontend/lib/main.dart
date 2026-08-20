import 'package:flutter/material.dart';
import 'core/theme/brik_theme.dart';
import 'core/services/supabase_auth_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseAuthService().initialize();
  runApp(const MitraiApp());
}

class MitraiApp extends StatefulWidget {
  const MitraiApp({super.key});

  @override
  State<MitraiApp> createState() => _MitraiAppState();
}

class _MitraiAppState extends State<MitraiApp> {
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _isLoggedIn = SupabaseAuthService().isAuthenticated;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mitrai AI Commerce',
      debugShowCheckedModeBanner: false,
      theme: BrikTheme.themeData,
      home: _isLoggedIn
          ? HomeScreen(
              onSignOut: () {
                setState(() => _isLoggedIn = false);
              },
            )
          : LoginScreen(
              onLoginSuccess: () {
                setState(() => _isLoggedIn = true);
              },
            ),
    );
  }
}
