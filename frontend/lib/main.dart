import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/brik_theme.dart';
import 'core/services/supabase_auth_service.dart';
import 'core/services/permission_service.dart';
import 'core/providers/cart_provider.dart';
import 'core/providers/watcher_provider.dart';
import 'core/providers/catalog_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/chat/widgets/floating_shopping_copilot_sheet.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseAuthService().initialize();
  
  // Initialize accessibility listener for background e-commerce app detection (Zave style)
  final permService = PermissionService();
  permService.initialize();
  permService.onECommerceAppDetected = (pkg, ctx) {
    final navContext = rootNavigatorKey.currentContext;
    if (navContext != null) {
      FloatingShoppingCopilotSheet.show(
        navContext,
        detectedPackage: pkg,
        detectedContext: ctx,
      );
    }
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => WatcherProvider()),
        ChangeNotifierProvider(create: (_) => CatalogProvider()),
      ],
      child: const MitraiApp(),
    ),
  );
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
      navigatorKey: rootNavigatorKey,
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
