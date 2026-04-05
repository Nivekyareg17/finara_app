import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Términos y Condiciones"),
      ),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Text(
            "Aquí van tus términos y condiciones...\n\n"
            "1. Uso de la app\n"
            "2. Privacidad\n"
            "3. Responsabilidad\n\n"
            "Puedes personalizar esto después.",
            style: TextStyle(fontSize: 14),
          ),
        ),
      ),
    );
  }
}