import 'package:finara_app_v1/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = "";
  String email = "";

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  void loadUser() async {
    final auth = context.read<AuthProvider>();

    final data = await auth.getUserData();

    if (data != null) {
      setState(() {
        name = data["name"];
        email = data["email"];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    const Color primaryColor = Color(0xFF064E3B);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF061A17) : Colors.white,
      appBar: AppBar(
        title: const Text("Perfil"),
        backgroundColor: isDark ? Colors.black : Colors.white,
        foregroundColor: primaryColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            const CircleAvatar(
              radius: 50,
              backgroundColor: primaryColor,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),

            const SizedBox(height: 15),

            // Nombre
            Text(
              name.isEmpty ? "Cargando..." : name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              email.isEmpty ? "Cargando..." : email,
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 30),

            //Botón logout
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  final auth = context.read<AuthProvider>();

                  await auth.logout();

                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    "/login",
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Cerrar sesión",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Mejorar a futuro

  // 🔒 Confirmación logout
  // void _confirmLogout(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       return Dialog(
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(20),
  //         ),
  //         child: Container(
  //           padding: const EdgeInsets.all(20),
  //           decoration: BoxDecoration(
  //             color: const Color(0xFF18B47A),
  //             borderRadius: BorderRadius.circular(20),
  //           ),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               const Icon(Icons.logout, color: Colors.white, size: 40),
  //               const SizedBox(height: 10),
  //               const Text(
  //                 "¿Deseas cerrar sesión?",
  //                 textAlign: TextAlign.center,
  //                 style: TextStyle(
  //                   color: Colors.white,
  //                   fontWeight: FontWeight.bold,
  //                   fontSize: 16,
  //                 ),
  //               ),
  //               const SizedBox(height: 20),
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //                 children: [
  //                   // Cancelar
  //                   TextButton(
  //                     onPressed: () => Navigator.pop(context),
  //                     child: const Text(
  //                       "Cancelar",
  //                       style: TextStyle(color: Colors.white),
  //                     ),
  //                   ),

  //                   // Confirmar logout
  //                   ElevatedButton(
  //                     style: ElevatedButton.styleFrom(
  //                       backgroundColor: Colors.white,
  //                       foregroundColor: Colors.green,
  //                     ),
  //                     onPressed: () {
  //                       Navigator.pop(context);

  //                       // 🔁 Ir a login y borrar historial
  //                       Navigator.pushNamedAndRemoveUntil(
  //                         context,
  //                         "/login",
  //                         (route) => false,
  //                       );
  //                     },
  //                     child: const Text("Salir"),
  //                   ),
  //                 ],
  //               )
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }
}
