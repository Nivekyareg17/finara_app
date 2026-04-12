import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  void checkLogin() async {

    final auth = context.read<AuthProvider>();

    await auth.loadToken();

    await Future.delayed(const Duration(seconds: 2));

    if (auth.isAuthenticated) {
      Navigator.pushReplacementNamed(context, "/home");
    } else {
      Navigator.pushReplacementNamed(context, "/login");
    }
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