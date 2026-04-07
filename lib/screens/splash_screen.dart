import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';
import '../screens/reset_password_screen.dart';

StreamSubscription? _sub;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  bool openedFromLink = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await checkInitialLink();   // primero revisa link
      initDeepLinks();            // escucha links

      if (!openedFromLink) {
        checkLogin();             // SOLO si no viene de link
      }
    });
  }

  // 🔥 APP ABIERTA
  void initDeepLinks() {
    _sub = uriLinkStream.listen((Uri? uri) {
      if (uri != null && uri.path == "/reset-password") {
        final token = uri.queryParameters["token"];
        openedFromLink = true;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(token: token!),
          ),
        );
      }
    }, onError: (err) {
      print("ERROR LINK: $err");
    });
  }

  // 🔥 APP CERRADA
  Future<void> checkInitialLink() async {
    final uri = await getInitialUri();

    if (uri != null && uri.path == "/reset-password") {
      final token = uri.queryParameters["token"];
      openedFromLink = true;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(token: token!),
        ),
      );
    }
  }

  void checkLogin() async {
    final auth = context.read<AuthProvider>();

    await auth.loadToken();

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (auth.isAuthenticated) {
      Navigator.pushReplacementNamed(context, "/home");
    } else {
      Navigator.pushReplacementNamed(context, "/login");
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          "Finara",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold
          ),
        ),
      ),
    );
  }
}