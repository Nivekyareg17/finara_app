import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/translate_widget.dart';
import '../widgets/app_drawer.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List users = [];
  String? currentUserEmail;

  Future<void> loadUsers() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token!;

    print("Cargando users...");

    final response = await ApiService.getUsers(token);
    print("USERS: $response");

    setState(() => users = response);
  }

  @override
  void initState() {
    super.initState();
    loadUsers();
    loadCurrentUser();
  }

  Future<void> loadCurrentUser() async {
    final auth = context.read<AuthProvider>();
    final data = await auth.getUserData();

    setState(() {
      currentUserEmail = data?["email"];
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final token = auth.token!;

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
                final auth = context.read<AuthProvider>();
                await auth.logout();

                if (!mounted) return;

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
