import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

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
                //logo
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

                //email
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                ),

                const SizedBox(height: 15),

                //password
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                ),

                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color: const Color.fromARGB(255, 1, 26, 173),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                //btn login
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

                      if (success) {
                        Navigator.pushReplacementNamed(context, "/home");
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Email o contraseña incorrectos"),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      "Sign In",
                      style: TextStyle(
                          fontSize: 16, color: Color.fromARGB(255, 0, 0, 0)),
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
                    // Google
                    CircleAvatar(
                      radius: 25,
                      backgroundColor:
                          isDark ? Colors.black26 : Colors.grey[200],
                      child: const Icon(Icons.g_mobiledata, size: 30),
                    ),

                    const SizedBox(width: 20),

                    // Apple
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
