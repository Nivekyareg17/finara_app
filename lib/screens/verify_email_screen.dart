import 'package:flutter/material.dart';
import '../services/api_service.dart';

class VerifyEmailScreen extends StatefulWidget {

  final String token;

  const VerifyEmailScreen({
    super.key,
    required this.token,
  });

  @override
  State<VerifyEmailScreen> createState() =>
      _VerifyEmailScreenState();
}

class _VerifyEmailScreenState
    extends State<VerifyEmailScreen> {

  @override
  void initState() {
    super.initState();
    verify();
  }

  Future<void> verify() async {

    final success =
        await ApiService.verifyEmail(
      widget.token,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(

      SnackBar(
        content: Text(

          success
          ? "Correo verificado"
          : "Error verificando correo",

        ),
      ),
    );

    Navigator.pushReplacementNamed(
      context,
      "/login",
    );
  }

  @override
  Widget build(BuildContext context) {

    return const Scaffold(

      body: Center(

        child:
            CircularProgressIndicator(),

      ),
    );
  }
}