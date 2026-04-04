import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String token;

  const ResetPasswordScreen({super.key, required this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  void resetPassword() async {
    setState(() => isLoading = true);

    final success = await ApiService.resetPassword(
      widget.token,
      passwordController.text,
    );

    setState(() => isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Contraseña actualizada")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al cambiar contraseña")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nueva contraseña")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Nueva contraseña",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : resetPassword,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Actualizar"),
            ),
          ],
        ),
      ),
    );
  }
}