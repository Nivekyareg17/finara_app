import 'package:finara_app_v1/features/ai/view/ai_chat_page.dart';
import 'package:finara_app_v1/screens/admin_screen.dart';
import 'package:finara_app_v1/screens/news_card.screen.dart';
import 'package:finara_app_v1/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'screens/Video_screen.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';
import 'screens/reset_password_screen.dart';

StreamSubscription? _sub;

void initDeepLinks(BuildContext context) {
  _sub = uriLinkStream.listen((Uri? uri) {
    if (uri != null) {
      print("LINK: $uri");

      if (uri.path == "/reset-password") {
        final token = uri.queryParameters["token"];

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(token: token!),
          ),
        );
      }
    }
  }, onError: (err) {
    print("ERROR LINK: $err");
  });
}

Future<void> checkInitialLink(BuildContext context) async {
  final uri = await getInitialUri();

  if (uri != null && uri.path == "/reset-password") {
    final token = uri.queryParameters["token"];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResetPasswordScreen(token: token!),
      ),
    );
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
Widget build(BuildContext context) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
      ),
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
      ),
    ],
    child: Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,

          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,

          initialRoute: "/",

          routes: {
            "/": (context) => const SplashScreen(),
            "/login": (context) => const LoginScreen(),
            "/register": (context) => const RegisterScreen(),
            "/home": (context) => HomeScreen(),
            '/daiko_ai': (context) => const AIChatPage(),
            "/news": (context) => const NewsScreen(),
            "/profile": (context) => const ProfileScreen(),
            "/video": (context) => const VideoScreen(),
            "/admin": (context) => const AdminScreen(),
            
          },
        );
      },
    ),
  );
}
}

