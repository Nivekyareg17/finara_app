import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/translate_widget.dart';
import '../widgets/app_drawer.dart';

import 'admin/admin_users_screen.dart';
import 'admin/admin_lecturas_screen.dart';
import 'admin/admin_videos_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const TranslatedText("Panel de administración"),
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.people),
                title: const TranslatedText("Gestionar usuarios"),
                subtitle: const TranslatedText(
                  "Administrar usuarios y roles",
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminUsersScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.menu_book),
                title: const TranslatedText("Gestionar lecturas"),
                subtitle: const TranslatedText(
                  "Crear, editar y eliminar lecturas",
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminLecturasScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.video_library),
                title: const TranslatedText("Gestionar videos"),
                subtitle: const TranslatedText(
                  "Crear, editar y eliminar videos",
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminVideosScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}