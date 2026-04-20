import 'package:flutter/material.dart';
import 'admin/admin_users_screen.dart';
import 'admin/admin_lecturas_screen.dart';
import 'admin/admin_videos_screen.dart';
import '../widgets/translate_widget.dart';
import '../widgets/app_drawer.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/translate_widget.dart';
import '../widgets/app_drawer.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const TranslatedText("Admin Panel"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirm = await showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const TranslatedText("Cerrar sesión"),
                  content: const TranslatedText("¿Seguro que quieres salir?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const TranslatedText("Cancelar"),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const TranslatedText("Salir"),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await auth.logout();

                if (!context.mounted) return;

                Navigator.pushReplacementNamed(context, "/login");
              }
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, i) {
          final user = users[i];

          return ListTile(
            title: Text(user["name"]),
            subtitle: TranslatedText("${user["email"]} - ${user["role"]}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // eliminar
                if (user["email"] != currentUserEmail)
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      final confirm = await showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const TranslatedText("Eliminar usuario"),
                          content: const TranslatedText("¿Estás seguro?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const TranslatedText("Cancelar"),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const TranslatedText("Eliminar"),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await ApiService.deleteUser(token, user["id"]);
                        loadUsers();
                      }
                    },
                  ),

                // SI NO es admin => mostrar botón hacer admin
                if (user["role"] != "admin")
                  IconButton(
                    icon: const Icon(Icons.security),
                    onPressed: () async {
                      await ApiService.makeAdmin(token, user["id"]);
                      loadUsers();
                    },
                  ),

                // SI es admin => mostrar botón quitar admin
                if (user["role"] == "admin")
                  IconButton(
                    icon: const Icon(Icons.person),
                    onPressed: () async {
                      await ApiService.removeAdmin(token, user["id"]);
                      loadUsers();
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}