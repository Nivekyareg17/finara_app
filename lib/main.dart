import 'dart:async';

import 'package:finara_app_v1/features/ai/view/ai_chat_page.dart';
import 'package:finara_app_v1/screens/admin_screen.dart';
import 'package:finara_app_v1/screens/news_card.screen.dart';
import 'package:finara_app_v1/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';

import '../providers/finance_provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/languaje_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/video_screen.dart';
import 'screens/verify_email_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _sub;

  @override
  void initState() {
    super.initState();
    _handleDeepLinks();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _handleDeepLinks() async {
    _appLinks = AppLinks();

    final initialUri = await _appLinks.getInitialLink();

    if (initialUri != null) {
      _handleLink(initialUri);
      ;
    }

    _sub = _appLinks.uriLinkStream.listen(
      (uri) {
        _handleLink(uri);
        ;
      },
    );
  }

  void _handleLink(Uri uri) {
    final token = uri.queryParameters["token"];

    if (token == null) return;

    if (uri.host == "reset-password") {
      navigatorKey.currentState?.pushNamed(
        "/reset-password",
        arguments: token,
      );
    }

    if (uri.host == "verify-email") {
      navigatorKey.currentState?.pushNamed(
        "/verify-email",
        arguments: token,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..loadToken(),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => LanguageProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => FinanceProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: "/",
            routes: {
              "/": (context) {
                final auth = Provider.of<AuthProvider>(context);

                if (!auth.isAuthenticated) {
                  return const SplashScreen();
                }

                if (auth.isAdmin && auth.isAdminView) {
                  return const AdminScreen();
                }

                return HomeScreen();
              },
              "/login": (context) => const LoginScreen(),
              "/register": (context) => const RegisterScreen(),
              "/home": (context) {
                final auth = Provider.of<AuthProvider>(context);

                if (auth.isAdmin && auth.isAdminView) {
                  return const AdminScreen();
                }

                return HomeScreen();
              },
              '/daiko_ai': (context) => const AIChatPage(),
              "/news": (context) => const NewsScreen(),
              "/profile": (context) => const ProfileScreen(),
              "/video": (context) => const VideoScreen(),
              "/admin": (context) => const AdminScreen(),
              "/reset-password": (context) {
                final token =
                    ModalRoute.of(context)!.settings.arguments as String;

                return ResetPasswordScreen(
                  token: token,
                );
              },
              "/verify-email": (context) {
                final token =
                    ModalRoute.of(context)!.settings.arguments as String;

                return VerifyEmailScreen(
                  token: token,
                );
              },
            },
          );
        },
      ),
    );
  }
}
