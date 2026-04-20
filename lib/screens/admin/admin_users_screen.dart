import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/translate_widget.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List users = [];
  String? currentUserEmail;

  @override
  void initState() {
    super.initState();
    loadUsers();
    loadCurrentUser();
  }

  Future<void> loadUsers() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token!;

    final response = await ApiService.getUsers(token);

    setState(() {
      users = response;
    });
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
        title: const TranslatedText("Gestionar usuarios"),
      ),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, i) {
          final user = users[i];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: ListTile(
              title: Text(user["name"]),
              subtitle: Text("${user["email"]} - ${user["role"]}"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (user["email"] != currentUserEmail)
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        final confirm = await showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const TranslatedText("Eliminar usuario"),
                            content: const TranslatedText(
                              "¿Estás seguro?",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: const TranslatedText("Cancelar"),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.pop(context, true),
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
                  if (user["role"] != "admin")
                    IconButton(
                      icon: const Icon(Icons.security),
                      onPressed: () async {
                        await ApiService.makeAdmin(token, user["id"]);
                        loadUsers();
                      },
                    ),
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
            ),
          );
        },
      ),
    );
  }
}