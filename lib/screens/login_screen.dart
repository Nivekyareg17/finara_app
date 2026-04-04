import 'package:finara_app_v1/providers/auth_provider.dart';
import 'package:finara_app_v1/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // DIALOG CORREG
  void showCustomDialog(String message, {bool isError = false}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        // Auto cerrar usando el context
        Future.delayed(const Duration(seconds: 2), () {
          if (Navigator.canPop(dialogContext)) {
            Navigator.pop(dialogContext);
          }
        });

        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 30),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isError ? Colors.red : const Color(0xFF18B47A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isError ? Icons.error : Icons.check_circle,
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF061A17) : Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                // logo
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18B47A),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    color: Colors.white,
                    size: 40,
                  ),
                ),

                const SizedBox(height: 15),

                const Text(
                  "Finara",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 5),

                const Text(
                  "ELEVATE YOUR WEALTH",
                  style: TextStyle(
                    letterSpacing: 2,
                    fontSize: 12,
                    color: Color(0xFF18B47A),
                  ),
                ),

                const SizedBox(height: 40),

                // email
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    hintText: "Email",
                    filled: true,
                    fillColor: isDark ? Colors.black26 : Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20),
                  ),
                ),

                const SizedBox(height: 15),

                // password
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "Password",
                    filled: true,
                    fillColor: isDark ? Colors.black26 : Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20),
                  ),
                ),

                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      final emailController = TextEditingController();

                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text("Recuperar contraseña"),
                            content: TextField(
                              controller: emailController,
                              decoration: const InputDecoration(
                                hintText: "Ingresa tu email",
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Cancelar"),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  final success =
                                      await ApiService.forgotPassword(
                                    emailController.text,
                                  );

                                  Navigator.pop(context);

                                  showCustomDialog(
                                    success
                                        ? "Revisa tu correo"
                                        : "Error al enviar correo",
                                    isError: !success,
                                  );
                                },
                                child: const Text("Enviar"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color: Color.fromARGB(255, 1, 26, 173),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                //  BOTÓN LOGIN CORREG
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF18B47A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () async {
                      final auth = context.read<AuthProvider>();

                      final success = await auth.login(
                        emailController.text,
                        passwordController.text,
                      );

                      if (!mounted) return;

                      if (success) {
                        showCustomDialog("Inicio de sesión exitoso");

                        await Future.delayed(const Duration(seconds: 2));

                        if (!mounted) return;

                        Navigator.pushReplacementNamed(context, "/home");
                      } else {
                        showCustomDialog(
                          "Email o contraseña incorrectos",
                          isError: true,
                        );
                      }
                    },
                    child: const Text(
                      "Sign In",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, "/register");
                      },
                      child: const Text(
                        "Create an Account",
                        style: TextStyle(
                          color: Color(0xFF18B47A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),
                const Text("OR CONTINUE WITH"),
                const SizedBox(height: 15),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor:
                          isDark ? Colors.black26 : Colors.grey[200],
                      child: const Icon(Icons.g_mobiledata, size: 30),
                    ),
                    const SizedBox(width: 20),
                    CircleAvatar(
                      radius: 25,
                      backgroundColor:
                          isDark ? Colors.black26 : Colors.grey[200],
                      child: const Icon(Icons.apple),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}